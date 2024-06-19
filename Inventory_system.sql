DROP DATABASE IF EXISTS inventory_mgmt;
CREATE DATABASE  IF NOT EXISTS inventory_mgmt;
USE inventory_mgmt;

-- 供应商
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255) NOT NULL,
    address VARCHAR(255) NULL,
    lead_time INT
);

-- 产品
CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    safe_stock_level INT, -- 最低需要重新购入的stock值
    healthy_stock_level INT, -- 正常需要的stock值
    shelf_space INT
);

-- SupplierProducts (关系表)
CREATE TABLE SupplierProducts (
    supplier_product_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_id INT,
    product_id INT,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 产品价格
CREATE TABLE ProductPrices (
    product_price_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_product_id INT,
    min_quantity INT,
    price DECIMAL(10, 2),
    FOREIGN KEY (supplier_product_id) REFERENCES SupplierProducts(supplier_product_id)
);

-- 客户
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255) NOT NULL,
    address VARCHAR(255) NULL
);

-- 仓库
CREATE TABLE Warehouses (
    warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    location VARCHAR(255) NULL,
    capacity INT
);

-- 仓库的库存
CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT,
    product_id INT,
    quantity INT,
    shelf_space INT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 客户订单
CREATE TABLE SalesOrders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    delivery_date DATE,
    status VARCHAR(50),
    lead_time_days INT, -- 需要么?是否可以直接使用supplier录入时的leadtime
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- order 的 product
CREATE TABLE SalesOrderDetails (
    order_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES SalesOrders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 生产schedule
CREATE TABLE ProductionPlans (
    production_plan_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_product_id INT,
    quantity INT,
    scheduled_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (supplier_product_id) REFERENCES SupplierProducts(supplier_product_id)
);

-- po 给 supplier
CREATE TABLE PurchaseOrders (
    po_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_id INT,
    order_date DATE,
    expected_delivery_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);


-- PO细节, 根据PO id, 和产品
CREATE TABLE PurchaseOrderDetails (
    pod_id INT PRIMARY KEY AUTO_INCREMENT,
    po_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (po_id) REFERENCES PurchaseOrders(po_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 仓库间调货
CREATE TABLE WarehouseTransfers (
    transfer_id INT PRIMARY KEY AUTO_INCREMENT,
    from_warehouse_id INT,
    to_warehouse_id INT,
    product_id INT,
    quantity INT,
    transfer_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (from_warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (to_warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


