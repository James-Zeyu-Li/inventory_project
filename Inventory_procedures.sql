
USE inventory_mgmt;
DROP PROCEDURE IF EXISTS create_purchase_order;
DROP PROCEDURE IF EXISTS find_cheapest_suppliers;

-- Zeyu Li
-- 1: find cheapest supplier

DELIMITER //
CREATE PROCEDURE find_cheapest_suppliers(
    IN product_id INT,
    OUT cheapest_supplier_id INT,
    OUT cheapest_catalog_id INT,
    OUT cheapest_price DECIMAL(10, 2)
)
BEGIN
    DROP TEMPORARY TABLE IF EXISTS TempSuppliers;
    
    -- find supplier and catalog
    SELECT supplier_id, catalog_id, price
    INTO cheapest_supplier_id, cheapest_catalog_id, cheapest_price
    FROM Catalog
    WHERE product_id = product_id
    ORDER BY price
    LIMIT 1;
    
    -- list all result in temperary chart
    CREATE TEMPORARY TABLE TempSuppliers AS
    SELECT supplier_id, catalog_id, price, max_quantity
    FROM Catalog
    WHERE product_id = product_id
    ORDER BY price;
END//


-- Zeyu Li
-- 2: check if inventory after PO will be larger than warehouse capacity
-- if after PO the capacity is larger than the all warehouse capacity
-- Check the warehouse capacity.
-- Calculate the current used capacity.
-- Calculate the new total capacity if the PO is added.
-- Compare the new total capacity with the warehouse capacity.
-- Trigger an alert and prevent the PO from being created if the capacity is exceeded. Add to alert chart.
-- if one warehouse can take partial, check if other warehouse has capability to take other parts. 
DELIMITER //
CREATE PROCEDURE create_purchase_order(
    IN product_id_var INT,
    IN quantity_var INT
)
BEGIN
    DECLARE supplier_var INT;
    DECLARE catalog_var INT;
    DECLARE price_var DECIMAL(10, 2);
    DECLARE po_var INT;
    DECLARE remaining_quantity INT;
    DECLARE current_warehouse_id INT;
    DECLARE current_warehouse_capacity INT;
    DECLARE current_warehouse_used_capacity INT;
    DECLARE allocatable_quantity INT;
    DECLARE product_shelf_space INT;
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE alert_message VARCHAR(1000);

    DECLARE warehouse_cursor CURSOR FOR 
        SELECT warehouse_id, capacity 
        FROM Warehouses 
        ORDER BY capacity DESC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    main_block: BEGIN
        -- Find cheapest supplier
        CALL find_cheapest_suppliers(product_id_var, supplier_var, catalog_var, price_var);

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
            
            INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
            VALUES ('Product', product_id_var, alert_message, NOW());

            SELECT alert_message AS result;
            LEAVE main_block;
        ELSE
            -- All quantity could be allocated, create PO and update inventory
            INSERT INTO PurchaseOrders (supplier_id, order_date, status, total_cost)
            VALUES (supplier_var, CURDATE(), ' Add to Inventory', price_var * quantity_var);

            SET po_var = LAST_INSERT_ID();

            -- Create Purchase Order Detail
            INSERT INTO PurchaseOrderDetails (po_id, catalog_id, quantity, cost_for_product)
            VALUES (po_var, catalog_var, quantity_var, price_var);

            -- Update Inventory based on allocations
            INSERT INTO Inventory (warehouse_id, product_id, quantity, catalog_id)
            SELECT warehouse_id, product_id_var, quantity, catalog_var
            FROM temp_allocations
            ON DUPLICATE KEY UPDATE Inventory.quantity = Inventory.quantity + VALUES(Inventory.quantity);

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
END//
DELIMITER ;

-- 测试1：库存足够的情况
CALL create_purchase_order(1, 10); 
-- 预期结果：PO 成功创建，库存更新，警报记录成功的 PO 创建

-- 测试2：库存不足的情况
CALL create_purchase_order(1, 100000); 
-- 预期结果：PO 创建失败，警报记录库存不足

-- 测试3：部分库存足够的情况
CALL create_purchase_order(2, 500); 
-- 预期结果：PO 成功创建，部分数量分配到多个仓库，库存更新，警报记录成功的 PO 创建

-- 测试4：单个仓库不足的情况，但总库存足够
CALL create_purchase_order(3, 15); 
-- 预期结果：PO 成功创建，数量分配到多个仓库，库存更新，警报记录成功的 PO 创建

-- 测试5：检查最便宜供应商选择
CALL create_purchase_order(4, 5); 
-- 预期结果：PO 成功创建，选择最便宜的供应商，库存更新，警报记录成功的 PO 创建

-- 验证 PurchaseOrders 表
SELECT * FROM PurchaseOrders ORDER BY po_id DESC LIMIT 1;

-- 验证 PurchaseOrderDetails 表
SELECT * FROM PurchaseOrderDetails ORDER BY pod_id DESC LIMIT 1;

-- 验证 Inventory 表
SELECT * FROM Inventory WHERE product_id = 1;

-- 验证 Alerts 表
SELECT * FROM Alerts ORDER BY alert_id DESC LIMIT 1;









-- Zeyu Li
-- alert if Sales order brings the stock level less than safety stock
-- generate a purchase order with detail which bring the  stock level back to healthy stock waiting for confirmation. 

-- check stock level
DELIMITER //

CREATE PROCEDURE check_stock_level(
    IN p_product_id INT,
    IN p_current_quantity INT,
    OUT p_needs_reorder BOOLEAN,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE safe_stock_level_var INT;
    
    SELECT safe_stock_level INTO v_safe_stock_level
    FROM Products 
    WHERE product_id = p_product_id;

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
END //

DELIMITER ;



-- Liuyi 
-- 10. 找出库存低于安全库存水平的产品，以便及时补货: 

DELIMITER //
USE inventory_mgmt;
CREATE PROCEDURE GetLowStockProducts()
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
END //

DELIMITER ;

CALL GetLowStockProducts();





