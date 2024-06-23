DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `calculate_average_price_per_product`(IN product_id_var INT)
item_exist: BEGIN
    DECLARE product_exists INT;

    -- Check if the product exists
    SELECT COUNT(*) INTO product_exists
    FROM Products
    WHERE product_id = product_id_var;

    -- If the product does not exist, insert an alert and exit
    IF product_exists = 0 THEN
		SELECT CONCAT('Alert: Product ID ', product_id_var, ' does not exist.') AS Warning;
        INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
        VALUES ('Product', product_id_var, CONCAT('Alert: Product ID ', product_id_var, ' does not exist.'), NOW());
        LEAVE item_exist;
    END IF;

    -- Create temporary table to store total cost and total quantity for each product
    CREATE TEMPORARY TABLE TempProductCosts AS
    SELECT 
        i.product_id,
        SUM(i.quantity * c.price) AS total_cost,
        SUM(i.quantity) AS total_quantity
    FROM 
        Inventory i
    JOIN 
        Catalog c ON i.catalog_id = c.catalog_id
    WHERE 
        i.product_id = product_id_var
    GROUP BY 
        i.product_id;

    -- Calculate and display the average purchase price for each product
    SELECT 
        p.product_id,
        p.name,
        CASE 
            WHEN t.total_quantity > 0 THEN t.total_cost / t.total_quantity 
            ELSE 0 
        END AS average_purchase_price
    FROM 
        Products p
    LEFT JOIN 
        TempProductCosts t ON p.product_id = t.product_id
    WHERE 
        p.product_id = product_id_var;

    -- Drop temporary table
    DROP TEMPORARY TABLE TempProductCosts;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `check_stock_level`(
    IN p_product_id INT,
    IN p_current_quantity INT,
    OUT p_needs_reorder BOOLEAN,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE safe_stock_level_var INT;
    
    -- Declare the variable to hold the safe stock level
    DECLARE v_safe_stock_level INT;

    -- Retrieve the safe stock level for the specified product
    SELECT safe_stock_level INTO v_safe_stock_level
    FROM Products 
    WHERE product_id = p_product_id;

    -- Check if the safe stock level was found
    IF v_safe_stock_level IS NULL THEN
        SET p_needs_reorder = FALSE;
        SET p_message = 'Product not found';
    ELSEIF p_current_quantity < v_safe_stock_level THEN
        SET p_needs_reorder = TRUE;
        SET p_message = 'Stock level below safe level';
    ELSE
        SET p_needs_reorder = FALSE;
        SET p_message = 'Stock level adequate';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_purchase_order`(
    IN product_id_var INT,
    IN quantity_var INT
)
BEGIN
    DECLARE supplier_var INT;
    DECLARE catalog_var INT;
    DECLARE price_var DECIMAL(10, 2);
    DECLARE po_var INT;
    DECLARE remaining_quantity INT;
    DECLARE total_cost DECIMAL(10, 2) DEFAULT 0;
    DECLARE current_warehouse_id INT;
    DECLARE current_warehouse_capacity INT;
    DECLARE current_warehouse_used_capacity INT;
    DECLARE allocatable_quantity INT;
    DECLARE product_shelf_space INT;
    DECLARE supplier_quantity INT;
    DECLARE supplier_price DECIMAL(10, 2);
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE alert_message VARCHAR(1000);
    DECLARE temp_supplier_id INT;
    DECLARE temp_catalog_id INT;
    DECLARE temp_price DECIMAL(10, 2);
    DECLARE temp_max_quantity INT;
    
    DECLARE warehouse_cursor CURSOR FOR 
        SELECT warehouse_id, capacity 
        FROM Warehouses 
        ORDER BY capacity DESC;

    DECLARE supplier_cursor CURSOR FOR
        SELECT supplier_id, catalog_id, price, max_quantity
        FROM TempSuppliers;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    main_block: BEGIN
        -- Ensure TempSuppliers table exists and is populated
        DROP TEMPORARY TABLE IF EXISTS TempSuppliers;
        CREATE TEMPORARY TABLE TempSuppliers AS
        SELECT supplier_id, catalog_id, price, max_quantity
        FROM Catalog
        WHERE product_id = product_id_var
        ORDER BY price;

        -- Fetch the first supplier ID to initialize the PurchaseOrder
        SELECT supplier_id INTO supplier_var
        FROM TempSuppliers
        LIMIT 1;
        
        -- Create Purchase Order
        INSERT INTO PurchaseOrders (supplier_id, order_date, status, total_cost)
        VALUES (supplier_var, CURDATE(), 'Pending', 0);

        SET po_var = LAST_INSERT_ID();

        -- Get product shelf space
        SELECT shelf_space INTO product_shelf_space
        FROM Products
        WHERE product_id = product_id_var;

        -- Initialize remaining quantity
        SET remaining_quantity = quantity_var;

        -- Temporary table to store allocations
        DROP TEMPORARY TABLE IF EXISTS temp_allocations;
        CREATE TEMPORARY TABLE temp_allocations (
            warehouse_id INT,
            quantity INT
        );

        -- Open cursor to iterate through warehouses
        OPEN warehouse_cursor;

        allocation_loop: LOOP
            FETCH warehouse_cursor INTO current_warehouse_id, current_warehouse_capacity;
            IF done THEN
                LEAVE allocation_loop;
            END IF;

            -- Calculate current used capacity
            SELECT IFNULL(SUM(Inventory.quantity * Products.shelf_space), 0)
            INTO current_warehouse_used_capacity
            FROM Inventory
            JOIN Products ON Inventory.product_id = Products.product_id
            WHERE Inventory.warehouse_id = current_warehouse_id;

            -- Calculate how much can be allocated to this warehouse
            SET allocatable_quantity = 
                FLOOR((current_warehouse_capacity - current_warehouse_used_capacity) / product_shelf_space);

            IF allocatable_quantity > 0 THEN
                IF allocatable_quantity >= remaining_quantity THEN
                    -- This warehouse can take all remaining quantity
                    INSERT INTO temp_allocations (warehouse_id, quantity) VALUES (current_warehouse_id, remaining_quantity);
                    SET remaining_quantity = 0;
                    LEAVE allocation_loop;
                ELSE
                    -- This warehouse can take part of the remaining quantity
                    INSERT INTO temp_allocations (warehouse_id, quantity) VALUES (current_warehouse_id, allocatable_quantity);
                    SET remaining_quantity = remaining_quantity - allocatable_quantity;
                END IF;
            END IF;
        END LOOP;

        CLOSE warehouse_cursor;

        -- Check if all quantity could be allocated
        IF remaining_quantity > 0 THEN
            -- Not all quantity could be allocated, reject PO and warn
            SET alert_message = CONCAT('Warning: Not enough warehouse capacity for the entire order of ', 
                                       quantity_var, ' units of product ID ', product_id_var, 
                                       '. PO rejected. Unallocated quantity: ', remaining_quantity);
            
            -- Update the Purchase Order status to 'Rejected'
            UPDATE PurchaseOrders
            SET status = 'Rejected'
            WHERE po_id = po_var;
            
            -- Add alert message
            INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
            VALUES ('Product', product_id_var, alert_message, NOW());

            SELECT alert_message AS result;
            LEAVE main_block;
        ELSE
            -- Allocate the quantities from suppliers
            SET remaining_quantity = quantity_var;
            OPEN supplier_cursor;
            supplier_loop: LOOP
                FETCH supplier_cursor INTO temp_supplier_id, temp_catalog_id, temp_price, temp_max_quantity;
                IF done THEN
                    LEAVE supplier_loop;
                END IF;

                SET supplier_quantity = LEAST(temp_max_quantity, remaining_quantity);
                SET supplier_price = temp_price * supplier_quantity;
                SET total_cost = total_cost + supplier_price;

                -- Create Purchase Order Detail
                INSERT INTO PurchaseOrderDetails (po_id, catalog_id, quantity, cost_for_product)
                VALUES (po_var, temp_catalog_id, supplier_quantity, temp_price);

                -- Update remaining quantity
                SET remaining_quantity = remaining_quantity - supplier_quantity;
                IF remaining_quantity = 0 THEN
                    LEAVE supplier_loop;
                END IF;
            END LOOP;
            CLOSE supplier_cursor;

            -- Update Purchase Order with total cost
            UPDATE PurchaseOrders
            SET total_cost = total_cost, status = 'Add to Inventory'
            WHERE po_id = po_var;

            -- Update Inventory based on allocations with shelf space
            INSERT INTO Inventory (warehouse_id, product_id, quantity, shelf_space, catalog_id)
            SELECT warehouse_id, product_id_var, quantity, product_shelf_space * quantity, catalog_id
            FROM temp_allocations
            JOIN (
                SELECT catalog_id, supplier_id, price, max_quantity
                FROM Catalog
                WHERE product_id = product_id_var
            ) AS temp_catalog ON temp_catalog.catalog_id = catalog_id
            ON DUPLICATE KEY UPDATE 
                Inventory.quantity = Inventory.quantity + VALUES(Inventory.quantity),
                Inventory.shelf_space = Inventory.shelf_space + VALUES(Inventory.shelf_space);

            -- Add an alert for successful PO creation
            SET alert_message = CONCAT('Purchase Order created with ID: ', po_var, 
                                       ' for ', quantity_var, ' units of product ID ', product_id_var, 
                                       '. Inventory allocated across multiple warehouses.');
            
            INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
            VALUES ('PurchaseOrder', po_var, alert_message, NOW());

            SELECT alert_message AS result;
        END IF;

        -- Clean up
        DROP TEMPORARY TABLE IF EXISTS temp_allocations;
    END main_block;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_cheapest_suppliers`(
    IN p_product_id INT
)
BEGIN
    -- Ensure TempSuppliers table is dropped if it exists
    DROP TEMPORARY TABLE IF EXISTS TempSuppliers;

    -- Create a temporary table to list all suppliers sorted by price
    CREATE TEMPORARY TABLE TempSuppliers AS
    SELECT supplier_id, catalog_id, price, max_quantity
    FROM Catalog
    WHERE product_id = p_product_id
    ORDER BY price;

    -- Select the cheapest supplier and catalog for the given product
    SELECT supplier_id, catalog_id, price
    FROM TempSuppliers
    ORDER BY price;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetLowStockProducts`()
BEGIN
    SELECT
        P.product_id,
        P.name AS product_name,
        P.safe_stock_level,
        SUM(I.quantity) AS current_stock,
        (P.safe_stock_level - SUM(I.quantity)) AS stock_deficit
    FROM
        Products P
    LEFT JOIN
        Inventory I ON P.product_id = I.product_id
    GROUP BY
        P.product_id, P.name, P.safe_stock_level
    HAVING
        current_stock < P.safe_stock_level;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetProductInventoryDetails`(IN product_id_var INT)
BEGIN
    -- Query the quantity, supplier, and price of the specified product in the current inventory
    SELECT 
        i.product_id,
        p.name AS product_name,
        s.name AS supplier_name,
        i.quantity,
        c.price
    FROM 
        Inventory i
    JOIN 
        Catalog c ON i.catalog_id = c.catalog_id
    JOIN 
        Suppliers s ON c.supplier_id = s.supplier_id
    JOIN 
        Products p ON i.product_id = p.product_id
    WHERE 
        i.product_id = product_id_var;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `MonthlyInventoryChanges`()
BEGIN
    SELECT 
        i.warehouse_id,
        i.product_id,
        DATE_FORMAT(t.transfer_date, '%Y-%m') AS month_year,
        COALESCE(SUM(CASE 
            WHEN t.from_warehouse_id = i.warehouse_id THEN -t.quantity
            WHEN t.to_warehouse_id = i.warehouse_id THEN t.quantity
            ELSE 0 
        END), 0) AS quantity_change
    FROM 
        Inventory i
    LEFT JOIN 
        WarehouseTransfers t ON i.product_id = t.product_id 
    GROUP BY 
        i.warehouse_id, i.product_id, month_year
    HAVING 
        quantity_change <> 0
    ORDER BY 
        i.warehouse_id, i.product_id, month_year;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `MostTransferredProducts`()
BEGIN
    SELECT 
        warehouse_id,
        product_id,
        total_transferred
    FROM (
        SELECT 
            warehouse_id,
            product_id,
            SUM(total_transferred) AS total_transferred,
            ROW_NUMBER() OVER (PARTITION BY warehouse_id ORDER BY SUM(total_transferred) DESC) AS row_num
        FROM (
            SELECT 
                from_warehouse_id AS warehouse_id,
                product_id,
                SUM(quantity) AS total_transferred
            FROM 
                WarehouseTransfers
            GROUP BY 
                from_warehouse_id, product_id
            
            UNION ALL
            
            SELECT 
                to_warehouse_id AS warehouse_id,
                product_id,
                SUM(quantity) AS total_transferred
            FROM 
                WarehouseTransfers
            GROUP BY 
                to_warehouse_id, product_id
        ) AS transfers
        GROUP BY 
            warehouse_id, product_id
    ) AS ranked_transfers
    WHERE 
        row_num <= 5
    ORDER BY 
        warehouse_id, row_num;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `process_sales_order`(
    IN p_order_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_safe_stock_level INT;
    DECLARE v_healthy_stock_level INT;
    DECLARE v_total_stock INT DEFAULT 0;
    DECLARE v_needed_quantity INT;
    DECLARE v_inventory_id INT;
    DECLARE v_current_stock INT;
    DECLARE done INT DEFAULT 0;
    
    DECLARE warehouse_cursor CURSOR FOR
        SELECT inventory_id, quantity FROM Inventory WHERE product_id = p_product_id;
    
    DECLARE below_safe_stock_cursor CURSOR FOR
        SELECT inventory_id, quantity FROM Inventory WHERE product_id = p_product_id AND quantity < v_safe_stock_level;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Get safe and healthy stock levels
    SELECT safe_stock_level, healthy_stock_level INTO v_safe_stock_level, v_healthy_stock_level 
    FROM Products WHERE product_id = p_product_id;

    -- Get total stock for the product
    SELECT SUM(quantity) INTO v_total_stock FROM Inventory WHERE product_id = p_product_id;

    -- Check if total stock is enough to fulfill the order
    IF v_total_stock < p_quantity THEN
        -- Insert alert and display the alert message
        INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
        VALUES ('Product', p_product_id, CONCAT('Insufficient stock for product ', p_product_id, ' to fulfill sales order ', p_order_id), NOW());
        SELECT CONCAT('Insufficient stock for product ', p_product_id, ' to fulfill sales order ', p_order_id) AS alert_message;
    ELSE
        -- Loop through warehouses to fulfill the order
        SET v_needed_quantity = p_quantity;
        OPEN warehouse_cursor;

        read_loop: LOOP
            FETCH warehouse_cursor INTO v_inventory_id, v_current_stock;
            IF done THEN
                LEAVE read_loop;
            END IF;

            IF v_current_stock >= v_needed_quantity THEN
                -- Update inventory
                UPDATE Inventory SET quantity = quantity - v_needed_quantity 
                WHERE inventory_id = v_inventory_id;

                SET v_needed_quantity = 0;
                LEAVE read_loop;
            ELSE
                -- Update inventory and reduce needed quantity
                UPDATE Inventory SET quantity = 0 
                WHERE inventory_id = v_inventory_id;

                SET v_needed_quantity = v_needed_quantity - v_current_stock;
            END IF;
        END LOOP;

        CLOSE warehouse_cursor;

        -- Reset done flag
        SET done = 0;

        -- Check if stock level falls below safe stock level in any inventory item
        OPEN below_safe_stock_cursor;

        read_loop: LOOP
            FETCH below_safe_stock_cursor INTO v_inventory_id, v_current_stock;
            IF done THEN
                LEAVE read_loop;
            END IF;

            -- Insert alert for low stock level and generate a suggestion instead of actual purchase order
            INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
            VALUES ('Product', p_product_id, CONCAT('Suggestion: Consider placing a purchase order for product ', p_product_id, ' in inventory ID ', v_inventory_id, '. Current stock is ', v_current_stock, ' units, below safe stock level of ', v_safe_stock_level, ' units.'), NOW());
			SELECT CONCAT('Suggestion: Consider placing a purchase order for product ', p_product_id, ' in inventory ID ', v_inventory_id, '. Current stock is ', v_current_stock, ' units, below safe stock level of ', v_safe_stock_level, ' units.') AS alert_message;
        END LOOP;

        CLOSE below_safe_stock_cursor;
    END IF;
END$$
DELIMITER ;
