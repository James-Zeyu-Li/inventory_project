
USE inventory_mgmt;
DROP PROCEDURE IF EXISTS create_purchase_order;
DROP PROCEDURE IF EXISTS find_cheapest_suppliers;


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
    
    -- list all result in temperary chart sort by price
    CREATE TEMPORARY TABLE TempSuppliers AS
    SELECT supplier_id, catalog_id, price, max_quantity
    FROM Catalog
    WHERE product_id = product_id
    ORDER BY price;
END//


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
        -- Create Purchase Order
        INSERT INTO PurchaseOrders (supplier_id, order_date, status, total_cost)
        VALUES (NULL, CURDATE(), 'Add to Inventory', 0);

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
            SET total_cost = total_cost
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



-- trigger, if PO contains products that is not in the product list warning, item not in product list
-- if in product list but not in inventory list, add to inventory list.
-- 还未检测
drop trigger if exists trg_after_insert_purchase_order_details;
DELIMITER //

-- 创建新的触发器
CREATE TRIGGER trg_after_insert_purchase_order_details
AFTER INSERT ON PurchaseOrderDetails
FOR EACH ROW
BEGIN
    DECLARE product_id_var INT;
    DECLARE warehouse_id_var INT;

    -- 获取 product_id
    SELECT product_id INTO product_id_var
    FROM Catalog
    WHERE catalog_id = NEW.catalog_id;

    -- 获取 warehouse_id
    SELECT warehouse_id INTO warehouse_id_var
    FROM PurchaseOrders
    WHERE po_id = NEW.po_id;

    -- 检查产品是否在指定仓库的 Inventory 表中
    IF NOT EXISTS (SELECT 1 FROM Inventory WHERE product_id = product_id_var AND warehouse_id = warehouse_id_var) THEN
        -- 将产品添加到 Inventory 表中
        INSERT INTO Inventory (warehouse_id, product_id, quantity, shelf_space, catalog_id)
        VALUES (warehouse_id_var, product_id_var, NEW.quantity, 
                (SELECT shelf_space FROM Products WHERE product_id = product_id_var), NEW.catalog_id);
    END IF;
END//
DELIMITER ;


-- 3: average price per prodict among all warehouses. Take paramenter product ID to calculate for that product.
DROP PROCEDURE IF EXISTS calculate_average_price_per_product;
DELIMITER //

CREATE PROCEDURE calculate_average_price_per_product(IN product_id_var INT)
item_exist: BEGIN
    DECLARE product_exists INT;

    -- Check if the product exists
    SELECT COUNT(*) INTO product_exists
    FROM Products
    WHERE product_id = product_id_var;

    -- If the product does not exist, insert an alert and exit
    IF product_exists = 0 THEN
        INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
        VALUES ('Product', product_id_var, CONCAT('Alert: Product ID ', product_id_var, ' does not exist.'), NOW());
        LEAVE item_exist;
    END IF;

    -- 创建临时表来保存每个产品的总成本和总数量
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

    -- 计算每个产品的平均购入价格并显示
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

    -- 清除临时表
    DROP TEMPORARY TABLE TempProductCosts;
END//
DELIMITER ;

CALL calculate_average_price_per_product(1);



-- 4: 做一个query 显示现在的inventory对应的product 的数量, from 哪个supplier, 价格是多少, parameter product id
DROP PROCEDURE IF EXISTS Get_Product_Inventory_Details;
DELIMITER //

CREATE PROCEDURE Get_Product_Inventory_Details(IN product_id_var INT)
BEGIN
    -- 查询指定产品在当前库存中的数量、供应商及其价格
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
END//
DELIMITER ;

-- 调用存储过程示例
CALL Get_Product_Inventory_Details(1);




-- 6: When sales order being create, subtract the amount from the inventory
-- if all inventories from all warehouses can't fufill the SO requests, send system alert.

DROP PROCEDURE IF EXISTS process_sales_order;

DELIMITER //

CREATE PROCEDURE process_sales_order (
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
    
    DECLARE inventory_cursor CURSOR FOR
        SELECT inventory_id, quantity FROM Inventory WHERE product_id = p_product_id;
    
    DECLARE below_safe_stock_cursor CURSOR FOR
        SELECT inventory_id, quantity FROM Inventory WHERE product_id = p_product_id AND quantity < v_safe_stock_level;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- 获取安全库存和健康库存水平
    SELECT safe_stock_level, healthy_stock_level INTO v_safe_stock_level, v_healthy_stock_level 
    FROM Products WHERE product_id = p_product_id;

    -- 获取产品的总库存
    SELECT SUM(quantity) INTO v_total_stock FROM Inventory WHERE product_id = p_product_id;

    -- 检查总库存是否足够满足订单
    IF v_total_stock < p_quantity THEN
        -- 插入警报
        INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
        VALUES ('Product', p_product_id, CONCAT('Insufficient stock for product ', p_product_id, ' to fulfill sales order ', p_order_id), NOW());
    ELSE
        -- 循环库存以满足订单
        SET v_needed_quantity = p_quantity;
        OPEN inventory_cursor;

        read_loop: LOOP
            FETCH inventory_cursor INTO v_inventory_id, v_current_stock;
            IF done THEN
                LEAVE read_loop;
            END IF;

            IF v_current_stock >= v_needed_quantity THEN
                -- 更新库存
                UPDATE Inventory SET quantity = quantity - v_needed_quantity 
                WHERE inventory_id = v_inventory_id;

                SET v_needed_quantity = 0;
                LEAVE read_loop;
            ELSE
                -- 更新库存并减少所需数量
                UPDATE Inventory SET quantity = 0 
                WHERE inventory_id = v_inventory_id;

                SET v_needed_quantity = v_needed_quantity - v_current_stock;
            END IF;
        END LOOP;

        CLOSE inventory_cursor;

        -- 重置 done 标志
        SET done = 0;

        -- 检查任何库存项目的库存水平是否低于安全库存水平
        OPEN below_safe_stock_cursor;

        read_loop: LOOP
            FETCH below_safe_stock_cursor INTO v_inventory_id, v_current_stock;
            IF done THEN
                LEAVE read_loop;
            END IF;

            -- 插入警报
            INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
            VALUES ('Product', p_product_id, CONCAT('Stock level for product ', p_product_id, ' in inventory ID ', v_inventory_id, ' has fallen below the safety stock level.'), NOW());

            -- 建议采购订单以恢复到健康库存水平
            INSERT INTO PurchaseOrders (supplier_id, order_date, expected_delivery_date, status, total_cost)
            SELECT supplier_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Pending', (v_healthy_stock_level - v_current_stock) * price
            FROM Catalog
            JOIN Products ON Catalog.product_id = Products.product_id
            WHERE Products.product_id = p_product_id
            LIMIT 1;

            -- 插入采购订单详情
            INSERT INTO PurchaseOrderDetails (po_id, catalog_id, quantity, cost_for_product)
            SELECT LAST_INSERT_ID(), Catalog.catalog_id, (v_healthy_stock_level - v_current_stock), Catalog.price
            FROM Catalog
            JOIN Products ON Catalog.product_id = Products.product_id
            WHERE Products.product_id = p_product_id
            LIMIT 1;
        END LOOP;

        CLOSE below_safe_stock_cursor;
    END IF;
END //

DELIMITER ;

-- 6: alert if Inventory is not enough for SO
DROP TRIGGER IF EXISTS trg_after_insert_sales_order_details;

DELIMITER //

CREATE TRIGGER trg_after_insert_sales_order_details
AFTER INSERT ON SalesOrderDetails
FOR EACH ROW
BEGIN
    CALL process_sales_order(NEW.order_id, NEW.product_id, NEW.quantity);
END //

DELIMITER ;




-- 7: alert if Sales order brings the stock level less than safety stock
-- generate a purchase order suggesstion which bring the stock level back to healthy stock
drop trigger if exists after_inventory_update;
DELIMITER //

CREATE TRIGGER after_inventory_update
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    DECLARE v_safe_stock_level INT;
    DECLARE v_healthy_stock_level INT;

    -- 获取安全库存和健康库存水平
    SELECT safe_stock_level, healthy_stock_level INTO v_safe_stock_level, v_healthy_stock_level 
    FROM Products WHERE product_id = NEW.product_id;

    -- 检查是否低于安全库存
    IF NEW.quantity < v_safe_stock_level THEN
        -- 插入警报
        INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
        VALUES ('Product', NEW.product_id, CONCAT('Stock level for product ', NEW.product_id, ' has fallen below the safety stock level.'), NOW());

        -- 建议采购订单以恢复到健康库存水平
        INSERT INTO PurchaseOrders (supplier_id, order_date, expected_delivery_date, status, total_cost)
        SELECT supplier_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Pending', (v_healthy_stock_level - NEW.quantity) * price
        FROM Catalog
        WHERE product_id = NEW.product_id
        LIMIT 1;

        -- 插入采购订单详情
        INSERT INTO PurchaseOrderDetails (po_id, catalog_id, quantity, cost_for_product)
        SELECT LAST_INSERT_ID(), catalog_id, (v_healthy_stock_level - NEW.quantity), price
        FROM Catalog
        WHERE product_id = NEW.product_id
        LIMIT 1;
    END IF;
END //

DELIMITER ;







-- Liuyi 
-- 9. Find products with stock levels below the safe stock level to restock them on time

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

-- 10.Compare prices for the same product from different suppliers
DELIMITER //

CREATE PROCEDURE CompareProductPrices(IN productName VARCHAR(255))
BEGIN
    DECLARE lowestPrice DECIMAL(10, 2);
    DECLARE bestSupplier VARCHAR(255);
    DECLARE currentSupplier VARCHAR(255);
    DECLARE currentPrice DECIMAL(10, 2);
    DECLARE done INT DEFAULT 0;

    DECLARE supplierCursor CURSOR FOR 
        SELECT s.name, c.price
        FROM Catalog c
        JOIN Products p ON c.product_id = p.product_id
        JOIN Suppliers s ON c.supplier_id = s.supplier_id
        WHERE p.name = productName;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET lowestPrice = NULL;
    SET bestSupplier = NULL;

    OPEN supplierCursor;

    supplier_loop: LOOP
        FETCH supplierCursor INTO currentSupplier, currentPrice;
        IF done THEN
            LEAVE supplier_loop;
        END IF;

        IF lowestPrice IS NULL OR currentPrice < lowestPrice THEN
            SET lowestPrice = currentPrice;
            SET bestSupplier = currentSupplier;
        END IF;
    END LOOP supplier_loop;

    CLOSE supplierCursor;

    IF lowestPrice IS NOT NULL THEN
        SELECT CONCAT('The best supplier for product ', productName, ' is ', bestSupplier, ' with a price of ', lowestPrice) AS result;
    ELSE
        SELECT CONCAT('No suppliers found for product ', productName) AS result;
    END IF;
END //

DELIMITER ;

CALL CompareProductPrices('Laptop');


-- 11. Report monthly inventory changes by warehouse
DROP PROCEDURE IF EXISTS MonthlyInventoryChanges

DELIMITER //

USE inventory_mgmt;

CREATE PROCEDURE MonthlyInventoryChanges()
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
END //

DELIMITER ;

CALL MonthlyInventoryChanges();


-- 12. Identify the most frequently transferred products between warehouses to improve transfer processes
DELIMITER //

DROP PROCEDURE IF EXISTS MostTransferredProducts //

CREATE PROCEDURE MostTransferredProducts()
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
END //

DELIMITER ;
CALL MostTransferredProducts()
