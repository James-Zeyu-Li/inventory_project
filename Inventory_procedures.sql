
USE inventory_mgmt;


-- 1: find cheapest supplier
DELIMITER //

CREATE PROCEDURE find_cheapest_suppliers(
    IN product_id INT,
    OUT cheapest_supplier_id INT,
    OUT cheapest_catalog_id INT,
    OUT cheapest_price DECIMAL(10, 2)
)
BEGIN
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
    ORDER BY price ASC;
END//

DELIMITER ;


-- 2: check if inventory in a warehouse is larger than warehouse capacity
-- if after PO the capacity is larger than the all warehouse capacity 
DELIMITER //

CREATE TRIGGER check_warehouse_capacity_before_po
BEFORE INSERT ON PurchaseOrders
FOR EACH ROW
BEGIN
    DECLARE warehouse_capacity INT;
    DECLARE used_capacity INT;
    DECLARE total_quantity INT;
    DECLARE new_quantity INT;
    DECLARE capacity_exceeded_message VARCHAR(255);

    -- 获取目标仓库的容量信息
    SELECT capacity INTO warehouse_capacity
    FROM Warehouses
    WHERE warehouse_id = NEW.warehouse_id;

    -- 计算当前仓库中所有商品的总数量
    SELECT IFNULL(SUM(quantity), 0) INTO used_capacity
    FROM Inventory
    WHERE warehouse_id = NEW.warehouse_id;

    -- 假设NEW.quantity表示新的订单数量
    SET new_quantity = NEW.quantity;

    -- 计算新的总数量
    SET total_quantity = used_capacity + new_quantity;

    -- 检查新的总数量是否超过仓库容量
    IF total_quantity > warehouse_capacity THEN
        -- 生成警告信息
        SET capacity_exceeded_message = CONCAT(
            'Alert! Warehouse ID ', NEW.warehouse_id, 
            ' will exceed its capacity. Current total quantity with new order: ', total_quantity, 
            ', Capacity: ', warehouse_capacity, '.'
        );
        
        -- 发出警告并终止插入操作
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = capacity_exceeded_message;
    END IF;
END //

DELIMITER ;

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






