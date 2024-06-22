DROP DATABASE IF EXISTS inventory_mgmt;
CREATE DATABASE  IF NOT EXISTS inventory_mgmt;
USE inventory_mgmt;

-- 供应商
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255) NOT NULL,
    address VARCHAR(255) NULL
);

-- 产品
CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    selling_price DECIMAL(10, 2), -- 售价
    safe_stock_level INT, -- 最低需要重新购入的库存值
    healthy_stock_level INT, -- 正常需要的库存值
    shelf_space INT
);

-- 目录表
CREATE TABLE Catalog (
    catalog_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_id INT,
    product_id INT,
    max_quantity INT, -- 最大生产数量
    price DECIMAL(10, 2), -- 价格
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
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
    catalog_id INT, -- 连接到catalog中的item价格
	FOREIGN KEY (catalog_id) REFERENCES Catalog(catalog_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 客户订单
CREATE TABLE SalesOrders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    total_price INT,
    delivery_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- order 的 product
CREATE TABLE SalesOrderDetails (
    order_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    price_for_product,
    FOREIGN KEY (order_id) REFERENCES SalesOrders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
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
    catalog_id INT,
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


