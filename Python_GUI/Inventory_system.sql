DROP DATABASE IF EXISTS inventory_mgmt;
CREATE DATABASE  IF NOT EXISTS inventory_mgmt;
USE inventory_mgmt;

CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255) NOT NULL,
    address VARCHAR(255) NULL
);


CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    selling_price DECIMAL(10, 2),
    safe_stock_level INT,
    healthy_stock_level INT,
    shelf_space INT
);


CREATE TABLE Catalog (
    catalog_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_id INT,
    product_id INT,
    max_quantity INT, 
    price DECIMAL(10, 2),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255) NOT NULL,
    address VARCHAR(255) NULL
);


CREATE TABLE Warehouses (
    warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    location VARCHAR(255) NULL,
    capacity INT
);


CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT,
    product_id INT,
    quantity INT,
    shelf_space INT,
    catalog_id INT, 
	FOREIGN KEY (catalog_id) REFERENCES Catalog(catalog_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


CREATE TABLE SalesOrders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    total_price DECIMAL(10, 2),
    delivery_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);


CREATE TABLE SalesOrderDetails (
    order_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    price_for_product DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES SalesOrders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


CREATE TABLE PurchaseOrders (
    po_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_id INT, 
    order_date DATE,
    expected_delivery_date DATE,
    status VARCHAR(50),
    total_cost DECIMAL(10, 2),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);



CREATE TABLE PurchaseOrderDetails (
    pod_id INT PRIMARY KEY AUTO_INCREMENT,
    po_id INT,
    catalog_id INT,
    quantity INT,
    cost_for_product DECIMAL(10, 2),
    FOREIGN KEY (po_id) REFERENCES PurchaseOrders(po_id),
    FOREIGN KEY (catalog_id) REFERENCES Catalog(catalog_id)
);


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


CREATE TABLE Alerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    entity_type VARCHAR(50),
    entity_id INT,
    message VARCHAR(1000),
    alert_date DATETIME
);

USE inventory_mgmt;

-- insert Supplier's data
INSERT INTO Suppliers (supplier_id, name, contact_info, address) VALUES 
(1, 'Supplier A', '123-456-7890', '123 East Supplier St.'),
(2, 'Supplier B', '234-567-8901', '456 West Supplier Ave.'),
(3, 'Supplier C', '345-678-9012', '789 North Supplier Rd.'),
(4, 'Supplier D', '456-789-0123', '101 South Supplier Blvd.'),
(5, 'Supplier E', '567-890-1234', '202 Central Supplier Ln.'),
(6, 'Supplier F', '678-901-2345', '303 Uptown Supplier Way');


-- INsert Product data
INSERT INTO Products (product_id, name, description, selling_price, safe_stock_level, healthy_stock_level, shelf_space) VALUES
(1, 'Laptop', 'A high-performance laptop with 16GB RAM and 512GB SSD.', 1200.00, 10, 50, 3),
(2, 'Smartphone', 'Latest model smartphone with 8GB RAM and 128GB storage.', 800.00, 20, 100, 1),
(3, 'Washing Machine', 'Energy-efficient washing machine with 7kg load capacity.', 500.00, 5, 25, 8),
(4, 'Refrigerator', 'Double-door refrigerator with 350L capacity and inverter technology.', 1000.00, 3, 15, 12),
(5, 'Microwave Oven', 'Compact microwave oven with 800W power and multiple presets.', 150.00, 15, 75, 2),
(6, 'Television', '55-inch 4K UHD Smart TV with HDR and voice control.', 700.00, 7, 35, 10),
(7, 'Tablet', '10-inch tablet with 4GB RAM and 64GB storage.', 300.00, 12, 60, 1),
(8, 'Smartwatch', 'Fitness smartwatch with heart rate monitor and GPS.', 200.00, 25, 125, 1),
(9, 'Digital Camera', 'Mirrorless camera with 24.2MP sensor and 4K video recording.', 1500.00, 4, 20, 3),
(10, 'Headphones', 'Wireless noise-cancelling headphones with 30-hour battery life.', 250.00, 18, 90, 1),
(11, 'Bluetooth Speaker', 'Portable Bluetooth speaker with deep bass and 12-hour playtime.', 100.00, 20, 100, 1),
(12, 'Smart Home Hub', 'Voice-controlled smart home hub with compatibility with major smart devices.', 130.00, 10, 50, 1),
(13, 'Electric Kettle', '1.7L electric kettle with auto shut-off and boil-dry protection.', 40.00, 30, 150, 2),
(14, 'Air Fryer', 'Digital air fryer with 3.7 quart capacity and multiple presets.', 120.00, 8, 40, 4),
(15, 'Vacuum Cleaner', 'Cordless vacuum cleaner with powerful suction and long battery life.', 350.00, 5, 25, 5),
(16, 'Coffee Maker', 'Programmable coffee maker with 12-cup capacity and built-in grinder.', 80.00, 10, 50, 3),
(17, 'Gaming Console', 'Next-gen gaming console with 1TB storage and 4K support.', 500.00, 6, 30, 3),
(18, 'Electric Scooter', 'Foldable electric scooter with 15-mile range and 15mph top speed.', 300.00, 4, 20, 7),
(19, 'Smart Door Lock', 'Keyless entry smart door lock with fingerprint and keypad access.', 180.00, 10, 50, 1),
(20, 'Robot Vacuum', 'Automatic robot vacuum with app control and self-charging.', 250.00, 5, 25, 4),
(21, 'Air Purifier', 'HEPA air purifier with 3-stage filtration for large rooms.', 200.00, 8, 40, 5),
(22, 'Instant Pot', '7-in-1 electric pressure cooker with 6-quart capacity.', 100.00, 12, 60, 3),
(23, 'Security Camera', 'Wireless security camera with motion detection and cloud storage.', 90.00, 20, 100, 1),
(24, 'Electric Toothbrush', 'Rechargeable electric toothbrush with multiple brush heads.', 70.00, 15, 75, 1),
(25, 'Hair Dryer', 'Ionic hair dryer with multiple heat and speed settings.', 60.00, 18, 90, 2),
(26, 'Smart Light Bulb', 'Color-changing smart LED bulb with app and voice control.', 25.00, 25, 125, 1),
(27, 'Fitness Tracker', 'Activity tracker with heart rate monitor and sleep tracking.', 50.00, 30, 150, 1),
(28, 'Portable Charger', '10000mAh portable charger with dual USB ports.', 30.00, 40, 200, 1),
(29, 'Electric Shaver', 'Rechargeable electric shaver with pop-up trimmer and wet/dry use.', 80.00, 10, 50, 1),
(30, 'Wireless Mouse', 'Ergonomic wireless mouse with adjustable DPI.', 25.00, 20, 100, 1),
(31, 'Keyboard', 'Mechanical keyboard with customizable RGB lighting.', 90.00, 10, 50, 1),
(32, 'Monitor', '27-inch 4K monitor with HDR and 144Hz refresh rate.', 350.00, 5, 25, 4),
(33, 'External Hard Drive', '2TB external hard drive with USB 3.0.', 80.00, 15, 75, 1),
(34, 'Printer', 'All-in-one wireless printer with scanner and copier.', 150.00, 7, 35, 3),
(35, 'Router', 'Dual-band WiFi router with advanced security features.', 120.00, 10, 50, 1),
(36, 'Smart Thermostat', 'WiFi-enabled smart thermostat with energy-saving features.', 200.00, 8, 40, 1),
(37, 'Electric Grill', 'Indoor electric grill with non-stick surface and temperature control.', 70.00, 12, 60, 4),
(38, 'Space Heater', 'Portable space heater with adjustable thermostat and safety features.', 60.00, 15, 75, 3),
(39, 'Dehumidifier', '50-pint dehumidifier with continuous drain option.', 200.00, 5, 25, 6),
(40, 'Electric Blanket', 'Heated electric blanket with multiple heat settings and auto shut-off.', 100.00, 10, 50, 3),
(41, 'Food Processor', '12-cup food processor with multiple attachments.', 150.00, 8, 40, 3),
(42, 'Slow Cooker', '6-quart slow cooker with programmable timer and lid lock.', 70.00, 12, 60, 3),
(43, 'Blender', 'High-speed blender with 64-ounce container and multiple speeds.', 200.00, 10, 50, 4),
(44, 'Stand Mixer', 'Professional stand mixer with 5-quart bowl and multiple attachments.', 300.00, 5, 25, 5),
(45, 'Water Filter', 'Countertop water filter with 5-stage filtration system.', 100.00, 10, 50, 2),
(46, 'Air Conditioner', 'Portable air conditioner with 10,000 BTU cooling capacity.', 400.00, 4, 20, 10),
(47, 'Toaster Oven', 'Countertop toaster oven with convection and rotisserie.', 150.00, 8, 40, 4),
(48, 'Electric Skillet', '12-inch electric skillet with non-stick coating and temperature control.', 80.00, 15, 75, 3),
(49, 'Rice Cooker', '10-cup rice cooker with fuzzy logic and multiple settings.', 100.00, 10, 50, 3),
(50, 'Pressure Washer', 'Electric pressure washer with 2000 PSI and multiple nozzles.', 180.00, 5, 25, 5);


-- Insert Catalog data
INSERT INTO Catalog (catalog_id, supplier_id, product_id, max_quantity, price) VALUES
(1, 1, 1, 30, 1150.00),
(2, 2, 1, 50, 1200.00),
(3, 3, 1, 70, 1250.00),
(4, 4, 2, 40, 750.00),
(5, 5, 2, 60, 800.00),
(6, 6, 2, 80, 850.00),
(7, 1, 3, 20, 450.00),
(8, 2, 3, 40, 500.00),
(9, 3, 3, 60, 550.00),
(10, 4, 4, 10, 950.00),
(11, 5, 4, 20, 1000.00),
(12, 6, 4, 30, 1050.00),
(13, 1, 5, 30, 140.00),
(14, 2, 5, 60, 150.00),
(15, 3, 5, 90, 160.00),
(16, 4, 6, 20, 650.00),
(17, 5, 6, 40, 700.00),
(18, 6, 6, 60, 750.00),
(19, 1, 7, 40, 280.00),
(20, 2, 7, 80, 300.00),
(21, 3, 7, 120, 320.00),
(22, 4, 8, 50, 180.00),
(23, 5, 8, 100, 200.00),
(24, 6, 8, 150, 220.00),
(25, 1, 9, 10, 1400.00),
(26, 2, 9, 20, 1500.00),
(27, 3, 9, 30, 1600.00),
(28, 4, 10, 25, 230.00),
(29, 5, 10, 50, 250.00),
(30, 6, 10, 75, 270.00),
(31, 1, 11, 50, 90.00),
(32, 2, 11, 100, 100.00),
(33, 3, 11, 150, 110.00),
(34, 4, 12, 40, 110.00),
(35, 5, 12, 80, 130.00),
(36, 6, 12, 120, 150.00),
(37, 1, 13, 50, 35.00),
(38, 2, 13, 100, 40.00),
(39, 3, 13, 150, 45.00),
(40, 4, 14, 20, 110.00),
(41, 5, 14, 40, 120.00),
(42, 6, 14, 60, 130.00),
(43, 1, 15, 10, 320.00),
(44, 2, 15, 20, 350.00),
(45, 3, 15, 30, 380.00),
(46, 4, 16, 30, 70.00),
(47, 5, 16, 60, 80.00),
(48, 6, 16, 90, 90.00),
(49, 1, 17, 10, 450.00),
(50, 2, 17, 20, 500.00),
(51, 3, 17, 30, 550.00),
(52, 4, 18, 10, 270.00),
(53, 5, 18, 20, 300.00),
(54, 6, 18, 30, 330.00),
(55, 1, 19, 40, 160.00),
(56, 2, 19, 80, 180.00),
(57, 3, 19, 120, 200.00),
(58, 4, 20, 15, 220.00),
(59, 5, 20, 30, 250.00),
(60, 6, 20, 45, 280.00),
(61, 1, 21, 20, 180.00),
(62, 2, 21, 40, 200.00),
(63, 3, 21, 60, 220.00),
(64, 4, 22, 30, 90.00),
(65, 5, 22, 60, 100.00),
(66, 6, 22, 90, 110.00),
(67, 1, 23, 40, 80.00),
(68, 2, 23, 80, 90.00),
(69, 3, 23, 120, 100.00),
(70, 4, 24, 25, 60.00),
(71, 5, 24, 50, 70.00),
(72, 6, 24, 75, 80.00),
(73, 1, 25, 40, 55.00),
(74, 2, 25, 80, 60.00),
(75, 3, 25, 120, 65.00),
(76, 4, 26, 50, 20.00),
(77, 5, 26, 100, 25.00),
(78, 6, 26, 150, 30.00),
(79, 1, 27, 50, 40.00),
(80, 2, 27, 100, 50.00),
(81, 3, 27, 150, 60.00),
(82, 4, 28, 40, 25.00),
(83, 5, 28, 80, 30.00),
(84, 6, 28, 120, 35.00),
(85, 1, 29, 20, 70.00),
(86, 2, 29, 40, 80.00),
(87, 3, 29, 60, 90.00),
(88, 4, 30, 50, 20.00),
(89, 5, 30, 100, 25.00),
(90, 6, 30, 150, 30.00),
(91, 1, 31, 40, 80.00),
(92, 2, 31, 80, 90.00),
(93, 3, 31, 120, 100.00),
(94, 4, 32, 10, 320.00),
(95, 5, 32, 20, 350.00),
(96, 6, 32, 30, 380.00),
(97, 1, 33, 40, 70.00),
(98, 2, 33, 80, 80.00),
(99, 3, 33, 120, 90.00),
(100, 4, 34, 20, 130.00),
(101, 5, 34, 40, 150.00),
(102, 6, 34, 60, 170.00),
(103, 1, 35, 30, 100.00),
(104, 2, 35, 60, 120.00),
(105, 3, 35, 90, 140.00),
(106, 4, 36, 20, 180.00),
(107, 5, 36, 40, 200.00),
(108, 6, 36, 60, 220.00),
(109, 1, 37, 20, 60.00),
(110, 2, 37, 40, 70.00),
(111, 3, 37, 60, 80.00),
(112, 4, 38, 20, 50.00),
(113, 5, 38, 40, 60.00),
(114, 6, 38, 60, 70.00),
(115, 1, 39, 10, 180.00),
(116, 2, 39, 20, 200.00),
(117, 3, 39, 30, 220.00),
(118, 4, 40, 20, 90.00),
(119, 5, 40, 40, 100.00),
(120, 6, 40, 60, 110.00),
(121, 1, 41, 30, 130.00),
(122, 2, 41, 60, 150.00),
(123, 3, 41, 90, 170.00),
(124, 4, 42, 40, 60.00),
(125, 5, 42, 80, 70.00),
(126, 6, 42, 120, 80.00),
(127, 1, 43, 10, 180.00),
(128, 2, 43, 20, 200.00),
(129, 3, 43, 30, 220.00),
(130, 4, 44, 10, 270.00),
(131, 5, 44, 20, 300.00),
(132, 6, 44, 30, 330.00),
(133, 1, 45, 40, 90.00),
(134, 2, 45, 80, 100.00),
(135, 3, 45, 120, 110.00),
(136, 4, 46, 10, 350.00),
(137, 5, 46, 20, 400.00),
(138, 6, 46, 30, 450.00),
(139, 1, 47, 30, 130.00),
(140, 2, 47, 60, 150.00),
(141, 3, 47, 90, 170.00),
(142, 4, 48, 20, 70.00),
(143, 5, 48, 40, 80.00),
(144, 6, 48, 60, 90.00),
(145, 1, 49, 20, 90.00),
(146, 2, 49, 40, 100.00),
(147, 3, 49, 60, 110.00),
(148, 4, 50, 10, 160.00),
(149, 5, 50, 20, 180.00),
(150, 6, 50, 30, 200.00);

-- Insert Customer Data
INSERT INTO Customers (customer_id, name, contact_info, address) VALUES
(1, 'John Smith', 'john.smith@example.com', '123 Maple St.'),
(2, 'Jane Doe', 'jane.doe@example.com', '456 Oak Ave.'),
(3, 'Michael Brown', 'michael.brown@example.com', '789 Pine Rd.'),
(4, 'Emily Davis', 'emily.davis@example.com', '101 Birch Blvd.'),
(5, 'David Wilson', 'david.wilson@example.com', '202 Cedar Ln.'),
(6, 'Sarah Johnson', 'sarah.johnson@example.com', '303 Spruce Way'),
(7, 'James Lee', 'james.lee@example.com', '404 Elm St.'),
(8, 'Jessica Martinez', 'jessica.martinez@example.com', '505 Walnut Ave.'),
(9, 'Daniel Garcia', 'daniel.garcia@example.com', '606 Cherry Rd.'),
(10, 'Laura Clark', 'laura.clark@example.com', '707 Aspen Blvd.'),
(11, 'Robert Lewis', 'robert.lewis@example.com', '808 Hickory Ln.'),
(12, 'Sophia Young', 'sophia.young@example.com', '909 Willow Way'),
(13, 'William Walker', 'william.walker@example.com', '1010 Sycamore St.'),
(14, 'Olivia Hall', 'olivia.hall@example.com', '1111 Maple Ave.'),
(15, 'Henry King', 'henry.king@example.com', '1212 Oak Rd.'),
(16, 'Linda Scott', 'linda.scott@example.com', '1313 Pine Blvd.'),
(17, 'Paul Harris', 'paul.harris@example.com', '1414 Birch Ln.'),
(18, 'Emma Rodriguez', 'emma.rodriguez@example.com', '1515 Cedar Way'),
(19, 'Charles Lopez', 'charles.lopez@example.com', '1616 Spruce St.'),
(20, 'Amelia White', 'amelia.white@example.com', '1717 Elm Ave.'),
(21, 'George Perez', 'george.perez@example.com', '1818 Walnut Rd.'),
(22, 'Abigail Thompson', 'abigail.thompson@example.com', '1919 Cherry Blvd.'),
(23, 'Ethan Martinez', 'ethan.martinez@example.com', '2020 Aspen Ln.'),
(24, 'Mia Anderson', 'mia.anderson@example.com', '2121 Hickory Way'),
(25, 'Benjamin Rivera', 'benjamin.rivera@example.com', '2222 Willow St.'),
(26, 'Lily Taylor', 'lily.taylor@example.com', '2323 Sycamore Ave.'),
(27, 'Alexander Torres', 'alexander.torres@example.com', '2424 Maple Rd.'),
(28, 'Chloe Nguyen', 'chloe.nguyen@example.com', '2525 Oak Blvd.'),
(29, 'Samuel Edwards', 'samuel.edwards@example.com', '2626 Pine Ln.'),
(30, 'Grace Flores', 'grace.flores@example.com', '2727 Birch Way'),
(31, 'Jackson Ramirez', 'jackson.ramirez@example.com', '2828 Cedar St.'),
(32, 'Avery Nelson', 'avery.nelson@example.com', '2929 Spruce Ave.'),
(33, 'Owen Bailey', 'owen.bailey@example.com', '3030 Elm Rd.'),
(34, 'Ella Gonzalez', 'ella.gonzalez@example.com', '3131 Walnut Blvd.'),
(35, 'Lucas Hayes', 'lucas.hayes@example.com', '3232 Cherry Ln.'),
(36, 'Victoria Kim', 'victoria.kim@example.com', '3333 Aspen Way'),
(37, 'Mason Carter', 'mason.carter@example.com', '3434 Hickory St.'),
(38, 'Aubrey Mitchell', 'aubrey.mitchell@example.com', '3535 Willow Ave.'),
(39, 'Logan Morgan', 'logan.morgan@example.com', '3636 Sycamore Rd.'),
(40, 'Hannah Adams', 'hannah.adams@example.com', '3737 Maple Blvd.'),
(41, 'Levi Cox', 'levi.cox@example.com', '3838 Oak Ln.'),
(42, 'Zoe Sanchez', 'zoe.sanchez@example.com', '3939 Pine Way'),
(43, 'Sebastian Brooks', 'sebastian.brooks@example.com', '4040 Birch St.'),
(44, 'Nora Price', 'nora.price@example.com', '4141 Cedar Ave.'),
(45, 'Aiden Reed', 'aiden.reed@example.com', '4242 Spruce Rd.'),
(46, 'Lillian Rogers', 'lillian.rogers@example.com', '4343 Elm Blvd.'),
(47, 'Dylan Cook', 'dylan.cook@example.com', '4444 Walnut Ln.'),
(48, 'Hazel Murphy', 'hazel.murphy@example.com', '4545 Cherry Way'),
(49, 'Wyatt Bell', 'wyatt.bell@example.com', '4646 Aspen St.'),
(50, 'Penelope Cooper', 'penelope.cooper@example.com', '4747 Hickory Ave.');

-- Insert Warehouse Data
INSERT INTO Warehouses (warehouse_id, location, capacity) VALUES
(1, 'New York', 2000),
(2, 'Los Angeles', 2500),
(3, 'Chicago', 2200),
(4, 'Houston', 2300),
(5, 'Phoenix', 1900);


-- Insert Inventory Data
INSERT INTO Inventory (inventory_id, warehouse_id, product_id, quantity, shelf_space, catalog_id) VALUES
-- Warehouse 1: Small stock
(1, 1, 1, 5, 15, 1),
(2, 1, 2, 10, 10, 4),
(3, 1, 3, 2, 16, 7),
(4, 1, 4, 1, 12, 10),
(5, 1, 5, 8, 16, 13),
(6, 1, 6, 3, 30, 16),
(7, 1, 7, 10, 10, 19),
(8, 1, 8, 5, 5, 22),
(9, 1, 9, 2, 6, 25),
(10, 1, 10, 6, 18, 28),
(11, 1, 11, 7, 7, 31),
(12, 1, 12, 4, 12, 34),
(13, 1, 13, 15, 30, 37),
(14, 1, 14, 6, 24, 40),
(15, 1, 15, 2, 10, 43),
-- Warehouse 2: Medium stock
(16, 2, 1, 15, 45, 2),
(17, 2, 2, 25, 25, 5),
(18, 2, 3, 8, 64, 8),
(19, 2, 4, 4, 48, 11),
(20, 2, 5, 20, 40, 14),
(21, 2, 6, 10, 100, 17),
(22, 2, 7, 20, 20, 20),
(23, 2, 8, 15, 15, 23),
(24, 2, 9, 10, 30, 26),
(25, 2, 10, 12, 36, 29),
(26, 2, 11, 25, 25, 32),
(27, 2, 12, 18, 54, 35),
(28, 2, 14, 12, 48, 41),
(29, 2, 16, 8, 40, 47),
(30, 2, 18, 5, 35, 53),
(31, 2, 20, 10, 50, 59),
-- Warehouse 3: Large stock
(32, 3, 1, 30, 90, 3),
(33, 3, 2, 40, 40, 6),
(34, 3, 3, 15, 120, 9),
(35, 3, 4, 10, 120, 12),
(36, 3, 5, 40, 80, 15),
(37, 3, 6, 20, 200, 18),
(38, 3, 7, 30, 30, 21),
(39, 3, 8, 25, 25, 24),
(40, 3, 9, 20, 60, 27),
(41, 3, 10, 24, 72, 30),
(42, 3, 11, 35, 35, 33),
(43, 3, 12, 28, 84, 36),
(44, 3, 14, 18, 72, 42),
(45, 3, 16, 15, 75, 48),
(46, 3, 18, 12, 84, 54),
(47, 3, 20, 18, 90, 60),
(48, 3, 22, 25, 100, 66),
(49, 3, 24, 22, 110, 72),
-- Warehouse 4: Very large stock
(50, 4, 1, 45, 135, 2),
(51, 4, 2, 60, 60, 5),
(52, 4, 3, 22, 176, 8),
(53, 4, 4, 15, 180, 11),
(54, 4, 5, 55, 110, 14),
(55, 4, 6, 30, 300, 17),
(56, 4, 7, 40, 40, 20),
(57, 4, 8, 35, 35, 23),
(58, 4, 9, 25, 75, 26),
(59, 4, 10, 30, 90, 29),
(60, 4, 11, 45, 45, 32),
(61, 4, 12, 38, 114, 35),
(62, 4, 14, 25, 100, 41),
(63, 4, 16, 20, 100, 47),
(64, 4, 18, 15, 105, 53),
(65, 4, 20, 25, 125, 59),
(66, 4, 22, 30, 120, 65),
(67, 4, 24, 28, 140, 71),
(68, 4, 26, 35, 140, 77),
-- Warehouse 5: Full stock
(69, 5, 1, 60, 180, 3),
(70, 5, 2, 80, 80, 6),
(71, 5, 3, 30, 240, 9),
(72, 5, 4, 20, 240, 12),
(73, 5, 5, 70, 140, 15),
(74, 5, 6, 40, 400, 18),
(75, 5, 7, 50, 50, 21),
(76, 5, 8, 45, 45, 24),
(77, 5, 9, 35, 105, 27),
(78, 5, 10, 48, 144, 30),
(79, 5, 11, 55, 55, 33),
(80, 5, 12, 50, 150, 36),
(81, 5, 14, 40, 160, 41),
(82, 5, 16, 35, 175, 47),
(83, 5, 18, 28, 196, 53),
(84, 5, 20, 40, 200, 59),
(85, 5, 22, 50, 200, 65),
(86, 5, 24, 45, 225, 71),
(87, 5, 26, 55, 220, 77),
(88, 5, 28, 60, 240, 83),
(89, 5, 30, 48, 240, 89);


-- Insert Mock Sales Orders 
INSERT INTO SalesOrders (order_id, customer_id, order_date, total_price, delivery_date, status) VALUES
(1, 1, '2024-01-10', 2400, '2024-01-15', 'Delivered'),
(2, 2, '2024-01-12', 1600, '2024-01-17', 'Delivered'),
(3, 3, '2024-01-14', 4600, '2024-01-19', 'Delivered'),
(4, 4, '2024-01-16', 3500, '2024-01-21', 'Delivered'),
(5, 5, '2024-01-18', 5700, '2024-01-23', 'Delivered'),
(6, 6, '2024-01-20', 2000, '2024-01-25', 'Delivered'),
(7, 7, '2024-01-22', 900, '2024-01-27', 'Delivered'),
(8, 8, '2024-01-24', 2700, '2024-01-29', 'Delivered'),
(9, 9, '2024-01-26', 3800, '2024-01-31', 'Delivered'),
(10, 10, '2024-01-28', 4600, '2024-02-02', 'Delivered'),
(11, 11, '2024-01-30', 3400, '2024-02-04', 'Delivered'),
(12, 12, '2024-02-01', 2400, '2024-02-06', 'Delivered'),
(13, 13, '2024-02-03', 1800, '2024-02-08', 'Delivered'),
(14, 14, '2024-02-05', 2100, '2024-02-10', 'Delivered'),
(15, 15, '2024-02-07', 1900, '2024-02-12', 'Delivered'),
(16, 16, '2024-02-09', 2000, '2024-02-14', 'Delivered'),
(17, 17, '2024-02-11', 3800, '2024-02-16', 'Delivered'),
(18, 18, '2024-02-13', 2310, '2024-02-18', 'Delivered'),
(19, 19, '2024-02-15', 3440, '2024-02-20', 'Delivered'),
(20, 20, '2024-02-17', 1900, '2024-02-22', 'Delivered'),
(21, 21, '2024-02-19', 3030, '2024-02-24', 'Delivered'),
(22, 22, '2024-02-21', 1500, '2024-02-26', 'Delivered'),
(23, 23, '2024-02-23', 2200, '2024-02-28', 'Delivered'),
(24, 24, '2024-02-25', 4180, '2024-03-02', 'Delivered'),
(25, 25, '2024-02-27', 2520, '2024-03-04', 'Delivered'),
(26, 26, '2024-02-29', 4400, '2024-03-06', 'Delivered'),
(27, 27, '2024-03-02', 8300, '2024-03-09', 'Delivered'),
(28, 28, '2024-03-04', 3500, '2024-03-11', 'Delivered'),
(29, 29, '2024-03-06', 6000, '2024-03-13', 'Delivered'),
(30, 30, '2024-03-08', 1300, '2024-03-15', 'Delivered'),
(31, 31, '2024-03-10', 5600, '2024-03-17', 'Shipped'),
(32, 32, '2024-03-12', 5500, '2024-03-19', 'Shipped'),
(33, 33, '2024-03-14', 6000, '2024-03-21', 'Shipped'),
(34, 34, '2024-03-16', 2100, '2024-03-23', 'Shipped'),
(35, 35, '2024-03-18', 2450, '2024-03-25', 'Shipped'),
(36, 36, '2024-03-20', 1690, '2024-03-27', 'Shipped'),
(37, 37, '2024-03-22', 1990, '2024-03-29', 'Shipped'),
(38, 38, '2024-03-24', 3310, '2024-03-31', 'Shipped'),
(39, 39, '2024-03-26', 2780, '2024-04-02', 'Shipped'),
(40, 40, '2024-03-28', 3550, '2024-04-04', 'Shipped'),
(41, 41, '2024-03-30', 1500, '2024-04-06', 'Shipped'),
(42, 42, '2024-04-01', 2500, '2024-04-08', 'Shipped'),
(43, 43, '2024-04-03', 4680, '2024-04-10', 'Shipped'),
(44, 44, '2024-04-05', 1420, '2024-04-12', 'Shipped'),
(45, 45, '2024-04-07', 4200, '2024-04-14', 'Shipped'),
(46, 46, '2024-04-09', 6500, '2024-04-16', 'Processing'),
(47, 47, '2024-04-11', 3300, '2024-04-18', 'Processing'),
(48, 48, '2024-04-13', 6500, '2024-04-20', 'Processing'),
(49, 49, '2024-04-15', 2200, '2024-04-22', 'Processing'),
(50, 50, '2024-04-17', 1100, '2024-04-24', 'Processing');


-- Insert Mock PO detail
INSERT INTO SalesOrderDetails (order_detail_id, order_id, product_id, quantity, price_for_product) VALUES
(1, 1, 1, 2, 2400),  -- Laptop x2
(2, 2, 2, 2, 1600),  -- Smartphone x2
(3, 3, 3, 6, 3000),  -- Washing Machine x6
(4, 3, 10, 10, 1600), -- Headphones x10
(5, 4, 4, 3, 3000),  -- Refrigerator x3
(6, 4, 6, 4, 500),   -- Television x4
(7, 5, 7, 9, 2700),  -- Tablet x9
(8, 5, 9, 2, 3000),  -- Digital Camera x2
(9, 6, 11, 15, 1500), -- Bluetooth Speaker x15
(10, 6, 13, 10, 500), -- Electric Kettle x10
(11, 7, 12, 20, 900), -- Smart Home Hub x20
(12, 8, 10, 10, 1500), -- Headphones x10
(13, 8, 16, 8, 1200),  -- Coffee Maker x8
(14, 9, 11, 25, 1500), -- Bluetooth Speaker x25
(15, 9, 15, 5, 1500),  -- Vacuum Cleaner x5
(16, 9, 8, 5, 800),    -- Smartwatch x5
(17, 10, 2, 5, 1200),  -- Smartphone x5
(18, 10, 4, 4, 2400),  -- Refrigerator x4
(19, 10, 17, 4, 1000), -- Gaming Console x4
(20, 11, 18, 7, 2100), -- Electric Scooter x7
(21, 11, 12, 5, 700),  -- Smart Home Hub x5
(22, 11, 5, 7, 600),   -- Microwave Oven x7
(23, 12, 1, 2, 1200),  -- Laptop x2
(24, 12, 20, 2, 1200), -- Robot Vacuum x2
(25, 13, 21, 9, 1800), -- Air Purifier x9
(26, 14, 22, 15, 1500), -- Instant Pot x15
(27, 14, 23, 5, 600),  -- Security Camera x5
(28, 15, 24, 10, 700), -- Electric Toothbrush x10
(29, 15, 25, 15, 1200), -- Hair Dryer x15
(30, 16, 27, 12, 600), -- Fitness Tracker x12
(31, 16, 28, 20, 600), -- Portable Charger x20
(32, 16, 29, 10, 800), -- Electric Shaver x10
(33, 17, 1, 2, 1200),  -- Laptop x2
(34, 17, 30, 10, 500), -- Wireless Mouse x10
(35, 17, 32, 6, 2100), -- Monitor x6
(36, 18, 33, 15, 1200), -- External Hard Drive x15
(37, 18, 34, 5, 750),  -- Printer x5
(38, 18, 35, 3, 360),  -- Router x3
(39, 19, 36, 7, 1400), -- Smart Thermostat x7
(40, 19, 37, 18, 1260), -- Electric Grill x18
(41, 19, 38, 13, 780), -- Space Heater x13
(42, 20, 39, 7, 1400), -- Dehumidifier x7
(43, 20, 40, 5, 500),  -- Electric Blanket x5
(44, 21, 42, 9, 630),  -- Slow Cooker x9
(45, 21, 43, 12, 2400), -- Blender x12
(46, 22, 44, 5, 1500),  -- Stand Mixer x5
(47, 23, 45, 10, 1000), -- Water Filter x10
(48, 23, 46, 3, 1200),  -- Air Conditioner x3
(49, 24, 47, 12, 1800), -- Toaster Oven x12
(50, 24, 48, 21, 1680), -- Electric Skillet x21
(51, 24, 49, 7, 700),   -- Rice Cooker x7
(52, 25, 50, 4, 720),   -- Pressure Washer x4
(53, 25, 1, 3, 1800),   -- Laptop x3
(54, 26, 2, 6, 2400),   -- Smartphone x6
(55, 26, 3, 4, 2000),   -- Washing Machine x4
(56, 27, 4, 5, 5000),   -- Refrigerator x5
(57, 27, 5, 10, 1500),  -- Microwave Oven x10
(58, 27, 6, 3, 1800),   -- Television x3
(59, 28, 7, 5, 1500),   -- Tablet x5
(60, 28, 8, 10, 2000),  -- Smartwatch x10
(61, 29, 9, 3, 4500),   -- Digital Camera x3
(62, 29, 10, 6, 1500),  -- Headphones x6
(63, 30, 11, 7, 700),   -- Bluetooth Speaker x7
(64, 30, 12, 5, 600),   -- Smart Home Hub x5
(65, 31, 13, 10, 500),  -- Electric Kettle x10
(66, 31, 14, 6, 600),   -- Air Fryer x6
(67, 31, 15, 15, 4500), -- Vacuum Cleaner x15
(68, 32, 16, 10, 1500), -- Coffee Maker x10
(69, 32, 17, 8, 4000),  -- Gaming Console x8
(70, 33, 18, 10, 3000), -- Electric Scooter x10
(71, 33, 19, 5, 600),   -- Smart Door Lock x5
(72, 33, 20, 4, 2400),  -- Robot Vacuum x4
(73, 34, 21, 6, 1200),  -- Air Purifier x6
(74, 34, 22, 3, 300),   -- Instant Pot x3
(75, 34, 23, 5, 600),   -- Security Camera x5
(76, 35, 24, 10, 700),  -- Electric Toothbrush x10
(77, 35, 25, 20, 1500), -- Hair Dryer x20
(78, 35, 26, 5, 250),   -- Smart Light Bulb x5
(79, 36, 27, 15, 750),  -- Fitness Tracker x15
(80, 36, 28, 10, 300),  -- Portable Charger x10
(81, 36, 29, 8, 640),   -- Electric Shaver x8
(82, 37, 30, 12, 300),  -- Wireless Mouse x12
(83, 37, 31, 8, 640),   -- Keyboard x8
(84, 37, 32, 3, 1050),  -- Monitor x3
(85, 38, 33, 20, 1600), -- External Hard Drive x20
(86, 38, 34, 5, 750),   -- Printer x5
(87, 38, 35, 8, 960),   -- Router x8
(88, 39, 36, 4, 800),   -- Smart Thermostat x4
(89, 39, 37, 18, 1260), -- Electric Grill x18
(90, 39, 38, 12, 720),  -- Space Heater x12
(91, 40, 39, 5, 1000),  -- Dehumidifier x5
(92, 40, 40, 3, 300),   -- Electric Blanket x3
(93, 40, 41, 15, 2250), -- Food Processor x15
(94, 41, 42, 10, 700),  -- Slow Cooker x10
(95, 41, 43, 4, 800),   -- Blender x4
(96, 42, 44, 5, 1500),  -- Stand Mixer x5
(97, 42, 45, 10, 1000), -- Water Filter x10
(98, 43, 46, 3, 1200),  -- Air Conditioner x3
(99, 43, 47, 12, 1800), -- Toaster Oven x12
(100, 43, 48, 21, 1680), -- Electric Skillet x21
(101, 44, 49, 7, 700),   -- Rice Cooker x7
(102, 44, 50, 4, 720),   -- Pressure Washer x4
(103, 45, 1, 3, 1800),   -- Laptop x3
(104, 45, 2, 6, 2400),   -- Smartphone x6
(105, 46, 3, 4, 2000),   -- Washing Machine x4
(106, 46, 4, 5, 5000),   -- Refrigerator x5
(107, 46, 5, 10, 1500),  -- Microwave Oven x10
(108, 47, 6, 3, 1800),   -- Television x3
(109, 47, 7, 5, 1500),   -- Tablet x5
(110, 48, 8, 10, 2000),  -- Smartwatch x10
(111, 48, 9, 3, 4500),   -- Digital Camera x3
(112, 49, 10, 6, 1500),  -- Headphones x6
(113, 49, 11, 7, 700),   -- Bluetooth Speaker x7
(114, 50, 12, 5, 600),   -- Smart Home Hub x5
(115, 50, 13, 10, 500);  -- Electric Kettle x10


-- Insert PO
INSERT INTO PurchaseOrders (po_id, supplier_id, order_date, expected_delivery_date, status, total_cost) VALUES
(1, 1, '2024-01-10', '2024-01-20', 'Delivered', 34500),
(2, 2, '2024-01-12', '2024-01-22', 'Delivered', 43000),
(3, 3, '2024-01-14', '2024-01-24', 'Shipped', 65000),
(4, 4, '2024-01-16', '2024-01-26', 'Processing', 41500),
(5, 5, '2024-01-18', '2024-01-28', 'Delivered', 65000),
(6, 6, '2024-01-20', '2024-01-30', 'Shipped', 86000),
(7, 1, '2024-01-22', '2024-02-01', 'Processing', 28750),
(8, 2, '2024-01-24', '2024-02-03', 'Delivered', 51000),
(9, 3, '2024-01-26', '2024-02-05', 'Delivered', 59500),
(10, 4, '2024-01-28', '2024-02-07', 'Shipped', 48000),
(11, 5, '2024-01-30', '2024-02-09', 'Processing', 145000),
(12, 6, '2024-02-01', '2024-02-11', 'Delivered', 85500),
(13, 1, '2024-02-03', '2024-02-13', 'Delivered', 57000),
(14, 2, '2024-02-05', '2024-02-15', 'Delivered', 43000),
(15, 3, '2024-02-07', '2024-02-17', 'Shipped', 65000),
(16, 4, '2024-02-09', '2024-02-19', 'Processing', 41500),
(17, 5, '2024-02-11', '2024-02-21', 'Delivered', 65000),
(18, 6, '2024-02-13', '2024-02-23', 'Shipped', 86000),
(19, 1, '2024-02-15', '2024-02-25', 'Processing', 28750),
(20, 2, '2024-02-17', '2024-02-27', 'Delivered', 51000),
(21, 3, '2024-02-19', '2024-03-01', 'Delivered', 59500),
(22, 4, '2024-02-21', '2024-03-03', 'Shipped', 48000),
(23, 5, '2024-02-23', '2024-03-05', 'Processing', 145000),
(24, 6, '2024-02-25', '2024-03-07', 'Delivered', 85500),
(25, 1, '2024-02-27', '2024-03-09', 'Delivered', 57000),
(26, 2, '2024-02-29', '2024-03-11', 'Delivered', 43000),
(27, 3, '2024-03-02', '2024-03-12', 'Shipped', 65000),
(28, 4, '2024-03-04', '2024-03-14', 'Processing', 41500),
(29, 5, '2024-03-06', '2024-03-16', 'Delivered', 65000),
(30, 6, '2024-03-08', '2024-03-18', 'Shipped', 86000),
(31, 1, '2024-03-10', '2024-03-20', 'Processing', 28750),
(32, 2, '2024-03-12', '2024-03-22', 'Delivered', 51000),
(33, 3, '2024-03-14', '2024-03-24', 'Delivered', 59500);


-- Insert PO details
INSERT INTO PurchaseOrderDetails (pod_id, po_id, catalog_id, quantity, cost_for_product) VALUES
(1, 1, 1, 30, 34500),  -- Supplier 1, Laptop x30, cost: 1150 each
(2, 2, 4, 40, 32000),  -- Supplier 2, Refrigerator x40, cost: 800 each
(3, 2, 5, 30, 11000),  -- Supplier 2, Microwave Oven x30, cost: 150 each
(4, 3, 7, 50, 22500),  -- Supplier 3, Tablet x50, cost: 450 each
(5, 3, 8, 50, 20000),  -- Supplier 3, Smartwatch x50, cost: 400 each
(6, 3, 9, 20, 12500),  -- Supplier 3, Digital Camera x20, cost: 625 each
(7, 3, 10, 25, 10000), -- Supplier 3, Headphones x25, cost: 400 each
(8, 4, 11, 30, 27000), -- Supplier 4, Bluetooth Speaker x30, cost: 900 each
(9, 4, 12, 15, 14500), -- Supplier 4, Smart Home Hub x15, cost: 950 each
(10, 5, 14, 20, 25000),-- Supplier 5, Air Fryer x20, cost: 1250 each
(11, 5, 15, 30, 30000),-- Supplier 5, Vacuum Cleaner x30, cost: 1000 each
(12, 5, 16, 10, 10000),-- Supplier 5, Coffee Maker x10, cost: 1000 each
(13, 6, 17, 20, 20000),-- Supplier 6, Gaming Console x20, cost: 1000 each
(14, 6, 18, 20, 15000),-- Supplier 6, Electric Scooter x20, cost: 750 each
(15, 6, 19, 20, 21000),-- Supplier 6, Smart Door Lock x20, cost: 1050 each
(16, 6, 20, 20, 30000),-- Supplier 6, Robot Vacuum x20, cost: 1500 each
(17, 7, 1, 25, 28750), -- Supplier 1, Laptop x25, cost: 1150 each
(18, 8, 4, 45, 36000), -- Supplier 2, Refrigerator x45, cost: 800 each
(19, 8, 5, 50, 15000), -- Supplier 2, Microwave Oven x50, cost: 150 each
(20, 9, 7, 55, 24750), -- Supplier 3, Tablet x55, cost: 450 each
(21, 9, 8, 40, 16000), -- Supplier 3, Smartwatch x40, cost: 400 each
(22, 9, 9, 30, 18750), -- Supplier 3, Digital Camera x30, cost: 625 each
(23, 10, 10, 40, 16000),-- Supplier 3, Headphones x40, cost: 400 each
(24, 10, 11, 25, 22500),-- Supplier 4, Bluetooth Speaker x25, cost: 900 each
(25, 10, 12, 10, 9500),-- Supplier 4, Smart Home Hub x10, cost: 950 each
(26, 11, 14, 60, 75000),-- Supplier 5, Air Fryer x60, cost: 1250 each
(27, 11, 15, 70, 70000),-- Supplier 5, Vacuum Cleaner x70, cost: 1000 each
(28, 12, 16, 30, 30000),-- Supplier 5, Coffee Maker x30, cost: 1000 each
(29, 12, 17, 30, 30000),-- Supplier 6, Gaming Console x30, cost: 1000 each
(30, 12, 18, 20, 15000),-- Supplier 6, Electric Scooter x20, cost: 750 each
(31, 12, 19, 10, 10500),-- Supplier 6, Smart Door Lock x10, cost: 1050 each
(32, 13, 20, 15, 22500),-- Supplier 6, Robot Vacuum x15, cost: 1500 each
(33, 13, 1, 30, 34500), -- Supplier 1, Laptop x30, cost: 1150 each
(34, 14, 4, 40, 32000), -- Supplier 2, Refrigerator x40, cost: 800 each
(35, 14, 5, 30, 11000), -- Supplier 2, Microwave Oven x30, cost: 150 each
(36, 15, 7, 50, 22500),-- Supplier 3, Tablet x50, cost: 450 each
(37, 15, 8, 50, 20000),-- Supplier 3, Smartwatch x50, cost: 400 each
(38, 15, 9, 20, 12500),-- Supplier 3, Digital Camera x20, cost: 625 each
(39, 15, 10, 25, 10000),-- Supplier 3, Headphones x25, cost: 400 each
(40, 16, 11, 30, 27000),-- Supplier 4, Bluetooth Speaker x30, cost: 900 each
(41, 16, 12, 15, 14500),-- Supplier 4, Smart Home Hub x15, cost: 950 each
(42, 17, 14, 20, 25000),-- Supplier 5, Air Fryer x20, cost: 1250 each
(43, 17, 15, 30, 30000),-- Supplier 5, Vacuum Cleaner x30, cost: 1000 each
(44, 17, 16, 10, 10000),-- Supplier 5, Coffee Maker x10, cost: 1000 each
(45, 18, 17, 20, 20000),-- Supplier 6, Gaming Console x20, cost: 1000 each
(46, 18, 18, 20, 15000),-- Supplier 6, Electric Scooter x20, cost: 750 each
(47, 18, 19, 20, 21000),-- Supplier 6, Smart Door Lock x20, cost: 1050 each
(48, 18, 20, 20, 30000),-- Supplier 6, Robot Vacuum x20, cost: 1500 each
(49, 19, 1, 25, 28750),-- Supplier 1, Laptop x25, cost: 1150 each
(50, 20, 4, 45, 36000),-- Supplier 2, Refrigerator x45, cost: 800 each
(51, 20, 5, 50, 15000),-- Supplier 2, Microwave Oven x50, cost: 150 each
(52, 21, 7, 55, 24750),-- Supplier 3, Tablet x55, cost: 450 each
(53, 21, 8, 40, 16000),-- Supplier 3, Smartwatch x40, cost: 400 each
(54, 21, 9, 30, 18750),-- Supplier 3, Digital Camera x30, cost: 625 each
(55, 22, 10, 40, 16000),-- Supplier 3, Headphones x40, cost: 400 each
(56, 22, 11, 25, 22500),-- Supplier 4, Bluetooth Speaker x25, cost: 900 each
(57, 22, 12, 10, 9500),-- Supplier 4, Smart Home Hub x10, cost: 950 each
(58, 23, 14, 60, 75000),-- Supplier 5, Air Fryer x60, cost: 1250 each
(59, 23, 15, 70, 70000),-- Supplier 5, Vacuum Cleaner x70, cost: 1000 each
(60, 24, 16, 30, 30000),-- Supplier 5, Coffee Maker x30, cost: 1000 each
(61, 24, 17, 30, 30000),-- Supplier 6, Gaming Console x30, cost: 1000 each
(62, 24, 18, 20, 15000),-- Supplier 6, Electric Scooter x20, cost: 750 each
(63, 24, 19, 10, 10500),-- Supplier 6, Smart Door Lock x10, cost: 1050 each
(64, 25, 20, 15, 22500),-- Supplier 6, Robot Vacuum x15, cost: 1500 each
(65, 25, 1, 30, 34500),-- Supplier 1, Laptop x30, cost: 1150 each
(66, 26, 4, 40, 32000),-- Supplier 2, Refrigerator x40, cost: 800 each
(67, 26, 5, 30, 11000),-- Supplier 2, Microwave Oven x30, cost: 150 each
(68, 27, 7, 50, 22500),-- Supplier 3, Tablet x50, cost: 450 each
(69, 27, 8, 50, 20000),-- Supplier 3, Smartwatch x50, cost: 400 each
(70, 27, 9, 20, 12500),-- Supplier 3, Digital Camera x20, cost: 625 each
(71, 27, 10, 25, 10000),-- Supplier 3, Headphones x25, cost: 400 each
(72, 28, 11, 30, 27000),-- Supplier 4, Bluetooth Speaker x30, cost: 900 each
(73, 28, 12, 15, 14500),-- Supplier 4, Smart Home Hub x15, cost: 950 each
(74, 29, 14, 20, 25000),-- Supplier 5, Air Fryer x20, cost: 1250 each
(75, 29, 15, 30, 30000),-- Supplier 5, Vacuum Cleaner x30, cost: 1000 each
(76, 29, 16, 10, 10000),-- Supplier 5, Coffee Maker x10, cost: 1000 each
(77, 30, 17, 20, 20000),-- Supplier 6, Gaming Console x20, cost: 1000 each
(78, 30, 18, 20, 15000),-- Supplier 6, Electric Scooter x20, cost: 750 each
(79, 30, 19, 20, 21000),-- Supplier 6, Smart Door Lock x20, cost: 1050 each
(80, 30, 20, 20, 30000),-- Supplier 6, Robot Vacuum x20, cost: 1500 each
(81, 31, 1, 25, 28750),-- Supplier 1, Laptop x25, cost: 1150 each
(82, 32, 4, 45, 36000),-- Supplier 2, Refrigerator x45, cost: 800 each
(83, 32, 5, 50, 15000),-- Supplier 2, Microwave Oven x50, cost: 150 each
(84, 33, 7, 55, 24750),-- Supplier 3, Tablet x55, cost: 450 each
(85, 33, 8, 40, 16000),-- Supplier 3, Smartwatch x40, cost: 400 each
(86, 33, 9, 30, 18750);-- Supplier 3, Digital Camera x30, cost: 625 each


TRUNCATE TABLE WarehouseTransfers;

-- Insert new warehouseTransfers
INSERT INTO WarehouseTransfers (from_warehouse_id, to_warehouse_id, product_id, quantity, transfer_date, status) VALUES
(1, 2, 1, 7, '2024-01-15', 'Completed'),
(2, 3, 2, 5, '2024-01-18', 'Completed'),
(3, 4, 3, 9, '2024-01-20', 'Completed'),
(4, 5, 4, 3, '2024-01-22', 'Completed'),
(5, 1, 5, 8, '2024-01-25', 'Completed'),
(1, 3, 6, 2, '2024-01-28', 'Completed'),
(2, 4, 7, 10, '2024-02-01', 'Completed'),
(3, 5, 8, 4, '2024-02-03', 'Completed'),
(4, 1, 9, 6, '2024-02-06', 'Completed'),
(5, 2, 10, 1, '2024-02-09', 'Completed'),
(1, 4, 11, 3, '2024-02-11', 'Completed'),
(2, 5, 12, 5, '2024-02-13', 'Completed'),
(3, 1, 13, 7, '2024-02-15', 'Completed'),
(4, 2, 14, 9, '2024-02-17', 'Completed'),
(5, 3, 15, 2, '2024-02-20', 'Completed'),
(1, 5, 16, 4, '2024-02-23', 'Completed'),
(2, 1, 17, 6, '2024-02-26', 'Completed'),
(3, 2, 18, 8, '2024-03-01', 'Completed'),
(4, 3, 19, 10, '2024-03-04', 'Completed'),
(5, 4, 20, 1, '2024-03-07', 'Completed'),
(1, 2, 21, 3, '2024-03-10', 'Completed'),
(2, 3, 22, 5, '2024-03-13', 'Completed'),
(3, 4, 23, 7, '2024-03-16', 'Completed'),
(4, 5, 24, 9, '2024-03-19', 'Completed'),
(5, 1, 25, 2, '2024-03-22', 'Completed'),
(1, 3, 26, 4, '2024-03-25', 'Completed'),
(2, 4, 27, 6, '2024-03-28', 'Completed'),
(3, 5, 28, 8, '2024-04-01', 'Completed'),
(4, 1, 29, 10, '2024-04-04', 'Completed'),
(5, 2, 30, 1, '2024-04-07', 'Completed'),
(2, 1, 11, 9, '2024-04-10', 'Completed'),
(1, 3, 14, 5, '2024-04-12', 'Completed'),
(3, 2, 18, 4, '2024-04-15', 'Completed'),
(4, 5, 20, 6, '2024-04-18', 'Completed'),
(5, 1, 23, 7, '2024-04-20', 'Completed'),
(2, 3, 27, 8, '2024-04-23', 'Completed'),
(1, 4, 29, 2, '2024-04-26', 'Completed'),
(4, 2, 34, 3, '2024-04-28', 'Completed'),
(5, 3, 38, 10, '2024-05-01', 'Completed'),
(3, 1, 42, 4, '2024-05-04', 'Completed'),
(1, 5, 45, 5, '2024-05-07', 'Completed'),
(2, 4, 49, 6, '2024-05-09', 'Completed'),
(4, 2, 5, 4, '2024-05-13', 'Completed'),
(5, 3, 9, 8, '2024-05-15', 'Completed'),
(1, 4, 13, 6, '2024-05-17', 'Completed'),
(2, 5, 17, 3, '2024-05-19', 'Completed');