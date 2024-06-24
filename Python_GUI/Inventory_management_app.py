import os
import sys
import sqlite3
import mysql.connector
from PyQt5.QtWidgets import (  # type: ignore
    QApplication, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QTableWidget, QTableWidgetItem, QMessageBox,
    QMainWindow, QAction, QDialog, QGridLayout, QFrame, QLineEdit,
    QSizePolicy, QSpacerItem)
from PyQt5.QtGui import QPixmap, QFont  # type: ignore
from PyQt5.QtCore import Qt  # type: ignore


class ProductApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.db_config = {
            'host': 'localhost',
            'user': 'root',
            'password': 'jinzhaolee',
            'database': 'inventory_mgmt'
        }
        self.conn = mysql.connector.connect(**self.db_config)
        self.cursor = self.conn.cursor()
        self.create_database()
        # self.create_procedures()
        self.initUI()

    def get_db_connection(self):
        return self.conn, self.db_config

    def load_sql_script(self, filename):
        with open(filename, 'r', encoding='utf-8') as file:
            sql_script = file.read()
        return sql_script

    def execute_sql_script(self, cursor, sql_script):
        sql_commands = sql_script.split(';')
        for command in sql_commands:
            command = command.strip()
            if command and not command.startswith('DELIMITER'):
                try:
                    # print(command)
                    cursor.execute(command)
                    print(f"Executed: {command}")
                    # 确保所有结果都被读取
                    while cursor.nextset():
                        pass
                except mysql.connector.Error as err:
                    print(f"Error: {err}")

    def create_database(self):
        # 获取脚本所在目录
        script_dir = os.path.dirname(os.path.abspath(__file__))
        create_db_sql_file_path = os.path.join(script_dir, 'Inventory_system.sql')
        procedures_sql_file_path = os.path.join(script_dir, 'Inventory_procedures.sql')

        # 连接到MySQL服务器
        server_config = self.db_config.copy()
        server_config.pop('database')  # 移除数据库参数以连接到MySQL服务器本身

        with mysql.connector.connect(**server_config) as conn:
            with conn.cursor() as cursor:
                # 加载并执行创建数据库的SQL文件
                create_db_sql_script = self.load_sql_script(create_db_sql_file_path)
                self.execute_sql_script(cursor, create_db_sql_script)

                # 切换到新创建的数据库
                cursor.execute(f"USE {self.db_config['database']}")

                # 加载并执行存储过程的SQL文件
                procedures_sql_script = self.load_sql_script(procedures_sql_file_path)
                # 手动处理存储过程定义
                for statement in procedures_sql_script.split('DELIMITER //'):
                    if statement.strip():
                        for sub_statement in statement.split('//'):
                            if sub_statement.strip():
                                self.execute_sql_script(cursor, sub_statement)

                conn.commit()

    def initUI(self):
        self.setWindowTitle('Product Management')
        self.setGeometry(100, 100, 1600, 1000)  # 设置窗口尺寸

        """
        # 菜单栏
        menubar = self.menuBar()
        fileMenu = menubar.addMenu('File')
        
        product_list_action = QAction('Product List', self)
        product_list_action.triggered.connect(self.show_product_list)
        fileMenu.addAction(product_list_action)
        
        stock_list_action = QAction('Stock List', self)
        stock_list_action.triggered.connect(self.show_stock_list)
        fileMenu.addAction(stock_list_action)
        """

        # 主布局
        main_layout = QHBoxLayout()

        # 左侧布局包含按钮、图片、输入框和信息
        left_layout = QVBoxLayout()

        # 图片展示区域
        self.image_label = QLabel(self)
        script_dir = os.path.dirname(os.path.abspath(__file__))
        image_path = os.path.join(script_dir, 'pic.png')
        pixmap = QPixmap(image_path)
        if pixmap.isNull():
            pixmap = QPixmap(500, 500)
            pixmap.fill(Qt.gray)  # 灰色填充占位
        else:
            pixmap = pixmap.scaled(500, 500, Qt.KeepAspectRatio)
        self.image_label.setPixmap(pixmap)
        self.image_label.setFixedSize(500, 500)
        self.image_label.setAlignment(Qt.AlignCenter)

        # 图片容器，用于居中显示图片
        image_container = QWidget()
        image_layout = QVBoxLayout()
        image_layout.addWidget(self.image_label, alignment=Qt.AlignCenter)
        image_container.setLayout(image_layout)

        left_layout.addWidget(image_container)

        # 按钮布局
        button_layout = QHBoxLayout()

        # 商品列表按钮
        product_list_button = QPushButton('Product List', self)
        product_list_button.clicked.connect(self.show_product_list)
        button_layout.addWidget(product_list_button)

        # 库存列表按钮
        stock_list_button = QPushButton('Inventory List', self)
        stock_list_button.clicked.connect(self.show_stock_list)
        button_layout.addWidget(stock_list_button)

        left_layout.addLayout(button_layout)
        left_layout.addSpacing(38)  # 添加间隔

        # 信息区域
        self.init_info_area(left_layout)

        # 输入框 + 按钮布局
        input_layout = QGridLayout()

        # 购买布局
        buy_id_label = QLabel('Product ID', self)
        self.buy_id_input = QLineEdit(self)
        buy_quantity_label = QLabel('Quantity', self)
        self.buy_quantity_input = QLineEdit(self)
        # buy_warehouse_label = QLabel('仓库ID', self)
        # self.buy_warehouse_input = QLineEdit(self)
        buy_button = QPushButton('Buy', self)
        buy_button.clicked.connect(self.buy_product)
        buy_button.setFixedWidth(80)

        input_layout.addWidget(buy_id_label, 0, 0)
        input_layout.addWidget(self.buy_id_input, 0, 1)
        input_layout.addWidget(buy_quantity_label, 1, 0)
        input_layout.addWidget(self.buy_quantity_input, 1, 1)
        # input_layout.addWidget(buy_warehouse_label, 2, 0)
        # input_layout.addWidget(self.buy_warehouse_input, 2, 1)
        input_layout.addWidget(buy_button, 0, 2, 3, 1, alignment=Qt.AlignCenter)

        # 卖出布局
        sell_id_label = QLabel('Product ID', self)
        self.sell_id_input = QLineEdit(self)
        sell_quantity_label = QLabel('Quantity', self)
        self.sell_quantity_input = QLineEdit(self)
        sell_customer_label = QLabel('Client ID', self)
        self.sell_customer_input = QLineEdit(self)
        sell_button = QPushButton('Sell', self)
        sell_button.clicked.connect(self.sell_product)
        sell_button.setFixedWidth(80)

        input_layout.addWidget(sell_id_label, 0, 3)
        input_layout.addWidget(self.sell_id_input, 0, 4)
        input_layout.addWidget(sell_quantity_label, 1, 3)
        input_layout.addWidget(self.sell_quantity_input, 1, 4)
        input_layout.addWidget(sell_customer_label, 2, 3)
        input_layout.addWidget(self.sell_customer_input, 2, 4)
        input_layout.addWidget(sell_button, 0, 5, 3, 1, alignment=Qt.AlignCenter)

        left_layout.addLayout(input_layout)

        # 中间间隔
        spacer = QWidget()
        spacer.setFixedWidth(50)

        # 右侧按钮区域
        right_layout = QGridLayout()
        button_functions = [
            self.button_function_1, self.button_function_2,
            self.button_function_3, self.button_function_4,
            self.button_function_5, self.button_function_6,
            self.button_function_7, self.button_function_8,
            # self.button_function_9, self.button_function_10
        ]
        button_names = [
            'Refresh', 'Boss Key', 'Catalog Management', 'Order Management',
            'Most frequently\ntransferred products', 'Monthly\ninventory changes','Low\ninventory products', 'Order Management',
            'Refresh', 'Boss Key', 'Catalog Management', 'Order Management',
            'Refresh', 'Boss Key', 'Catalog Management', 'Order Management',
            'Refresh', 'Boss Key', 'Catalog Management', 'Order Management'
        ]
        for i in range(7):  # 有多少个按钮
            button = QPushButton(button_names[i], self)
            button.setFixedHeight(100)  # 设置按钮固定高度
            button.clicked.connect(button_functions[i])  # 绑定不同的槽函数
            row = i // 3
            col = i % 3
            right_layout.addWidget(button, row, col)

        main_layout.addLayout(left_layout, 11)
        main_layout.addWidget(spacer, 2)
        main_layout.addLayout(right_layout, 7)

        container = QWidget()
        container.setLayout(main_layout)
        self.setCentralWidget(container)

    def init_info_area(self, left_layout):
        self.info_layout = QHBoxLayout()

        self.labels = [
            ("Inventory remaining", "01067"),
            ("Products on sale", "18"),
            ("Warehouse quantity", "6"),
            ("Total inventory value", "161000")
        ]

        self.info_boxes = []
        for i, (text, value) in enumerate(self.labels):
            info_box = QVBoxLayout()
            info_label = QLabel(text, self)
            info_value = QLabel(value, self)
            info_box.addWidget(info_label)
            info_box.addWidget(info_value)
            self.info_boxes.append((info_label, info_value))
            info_frame = QFrame(self)
            info_frame.setLayout(info_box)
            info_frame.setFrameShape(QFrame.Box)
            # row = i // 2
            # col = i % 2
            self.info_layout.addWidget(info_frame, alignment=Qt.AlignTop)

        left_layout.addLayout(self.info_layout)

    # --------------------------上面是UI部分---------------------------------
    # --------------------------下面是逻辑部分-------------------------------

    def insert_inventory(self, warehouse_id, product_id, quantity, shelf_space, catalog_id):
        try:
            self.cursor.execute('''
                INSERT INTO Inventory (warehouse_id, product_id, quantity, shelf_space, catalog_id)
                VALUES (?, ?, ?, ?, ?)
            ''', (warehouse_id, product_id, quantity, shelf_space, catalog_id))
            self.conn.commit()
        except sqlite3.Error as e:
            self.handle_error(e)

    # 修改某一条inventory，基本不会用到
    def update_inventory(self, inventory_id, warehouse_id, product_id, quantity, shelf_space, catalog_id):
        try:
            self.cursor.execute('''
                UPDATE Inventory
                SET warehouse_id = ?, product_id = ?, quantity = ?, shelf_space = ?, catalog_id = ?
                WHERE inventory_id = ?
            ''', (warehouse_id, product_id, quantity, shelf_space, catalog_id, inventory_id))
            self.conn.commit()
        except sqlite3.Error as e:
            self.handle_error(e)

    def handle_error(self, error):
        # 提取错误消息并显示
        error_message = str(error)
        QMessageBox.critical(self, 'Database Error', error_message, QMessageBox.Ok)

    # +++++++++++++++++++++++++++ 功能区 ++++++++++++++++++++++++++++++++++
    # +++++++++++++++++++++++++++ 功能区 ++++++++++++++++++++++++++++++++++
    # +++++++++++++++++++++++++++ 功能区 ++++++++++++++++++++++++++++++++++
    def show_product_list(self):
        conn, db_config = self.get_db_connection()
        self.product_list_window = ProductListWindow(conn, db_config)
        self.product_list_window.show()

    def show_stock_list(self):
        conn, db_config = self.get_db_connection()
        self.stock_list_window = StockListWindow(conn, db_config)
        self.stock_list_window.show()

    def show_catalog_list(self):
        conn, db_config = self.get_db_connection()
        self.catalog_list_window = CatalogListWindow(conn, db_config)
        self.catalog_list_window.show()

    def show_order_list(self):
        conn, db_config = self.get_db_connection()
        self.order_list_window = OrderListWindow(conn, db_config)
        self.order_list_window.show()

    def show_most_transferred_products(self):
        conn, db_config = self.get_db_connection()
        self.most_transferred_products_window = MostTransferredProductsWindow(conn, db_config)
        self.most_transferred_products_window.show()

    def show_monthly_inventory_changes(self):
        conn, db_config = self.get_db_connection()
        self.monthly_inventory_changes_window = MonthlyInventoryChangesWindow(conn, db_config)
        self.monthly_inventory_changes_window.show()

    def show_low_stock_products(self):
        conn, db_config = self.get_db_connection()
        self.low_stock_products_window = LowStockProductsWindow(conn, db_config)
        self.low_stock_products_window.show()

    def buy_product(self):
        product_id = int(self.buy_id_input.text())
        quantity = int(self.buy_quantity_input.text())

        conn, db_config = self.get_db_connection()
        cursor = conn.cursor()

        try:
            # Ensure TempSuppliers table exists and is populated
            cursor.execute('''
                DROP TEMPORARY TABLE IF EXISTS TempSuppliers;
                CREATE TEMPORARY TABLE TempSuppliers AS
                SELECT supplier_id, catalog_id, price, max_quantity
                FROM Catalog
                WHERE product_id = %s
                ORDER BY price;
            ''', (product_id,))
            cursor.fetchall()  # 清空结果集

            # Fetch the first supplier ID to initialize the PurchaseOrder
            cursor.execute('SELECT supplier_id FROM TempSuppliers LIMIT 1;')
            supplier_var = cursor.fetchone()[0]

            # Create Purchase Order
            cursor.execute('''
                INSERT INTO PurchaseOrders (supplier_id, order_date, status, total_cost)
                VALUES (%s, CURDATE(), 'Pending', 0);
            ''', (supplier_var,))
            conn.commit()
            po_var = cursor.lastrowid

            # Get product shelf space
            cursor.execute('SELECT shelf_space FROM Products WHERE product_id = %s;', (product_id,))
            product_shelf_space = cursor.fetchone()[0]

            # Initialize remaining quantity
            remaining_quantity = quantity

            # Temporary table to store allocations
            cursor.execute('''
                DROP TEMPORARY TABLE IF EXISTS temp_allocations;
                CREATE TEMPORARY TABLE temp_allocations (
                    warehouse_id INT,
                    quantity INT
                );
            ''')
            cursor.fetchall()  # 清空结果集

            # Open cursor to iterate through warehouses
            cursor.execute('SELECT warehouse_id, capacity FROM Warehouses ORDER BY capacity DESC;')
            warehouses = cursor.fetchall()

            for warehouse in warehouses:
                current_warehouse_id, current_warehouse_capacity = warehouse

                # Calculate current used capacity
                cursor.execute('''
                    SELECT IFNULL(SUM(Inventory.quantity * Products.shelf_space), 0)
                    FROM Inventory
                    JOIN Products ON Inventory.product_id = Products.product_id
                    WHERE Inventory.warehouse_id = %s;
                ''', (current_warehouse_id,))
                current_warehouse_used_capacity = cursor.fetchone()[0]

                # Calculate how much can be allocated to this warehouse
                allocatable_quantity = (current_warehouse_capacity - current_warehouse_used_capacity) // product_shelf_space

                if allocatable_quantity > 0:
                    if allocatable_quantity >= remaining_quantity:
                        cursor.execute('INSERT INTO temp_allocations (warehouse_id, quantity) VALUES (%s, %s);',
                                    (current_warehouse_id, remaining_quantity))
                        conn.commit()
                        remaining_quantity = 0
                        break
                    else:
                        cursor.execute('INSERT INTO temp_allocations (warehouse_id, quantity) VALUES (%s, %s);',
                                    (current_warehouse_id, allocatable_quantity))
                        conn.commit()
                        remaining_quantity -= allocatable_quantity

            # Check if all quantity could be allocated
            if remaining_quantity > 0:
                alert_message = f'Warning: Not enough warehouse capacity for the entire order of {quantity} units of product ID {product_id}. PO rejected. Unallocated quantity: {remaining_quantity}'

                cursor.execute('''
                    UPDATE PurchaseOrders
                    SET status = 'Rejected'
                    WHERE po_id = %s;
                ''', (po_var,))
                conn.commit()

                cursor.execute('''
                    INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
                    VALUES ('Product', %s, %s, NOW());
                ''', (product_id, alert_message))
                conn.commit()

                print(alert_message)
                return

            # Allocate the quantities from suppliers
            total_cost = 0
            remaining_quantity = quantity
            cursor.execute('SELECT supplier_id, catalog_id, price, max_quantity FROM TempSuppliers;')
            suppliers = cursor.fetchall()

            for supplier in suppliers:
                temp_supplier_id, temp_catalog_id, temp_price, temp_max_quantity = supplier
                supplier_quantity = min(temp_max_quantity, remaining_quantity)
                supplier_price = temp_price * supplier_quantity
                total_cost += supplier_price

                cursor.execute('''
                    INSERT INTO PurchaseOrderDetails (po_id, catalog_id, quantity, cost_for_product)
                    VALUES (%s, %s, %s, %s);
                ''', (po_var, temp_catalog_id, supplier_quantity, temp_price))
                conn.commit()

                remaining_quantity -= supplier_quantity
                if remaining_quantity == 0:
                    break

            cursor.execute('''
                UPDATE PurchaseOrders
                SET total_cost = %s, status = 'Add to Inventory'
                WHERE po_id = %s;
            ''', (total_cost, po_var))
            conn.commit()

            # Update Inventory based on allocations with shelf space
            cursor.execute('''
                INSERT INTO Inventory (warehouse_id, product_id, quantity, shelf_space, catalog_id)
                SELECT warehouse_id, %s, quantity, %s * quantity, %s
                FROM temp_allocations
                JOIN (
                    SELECT catalog_id, supplier_id, price, max_quantity
                    FROM Catalog
                    WHERE product_id = %s
                ) AS temp_catalog ON temp_catalog.catalog_id = %s
                ON DUPLICATE KEY UPDATE 
                    Inventory.quantity = Inventory.quantity + VALUES(Inventory.quantity),
                    Inventory.shelf_space = Inventory.shelf_space + VALUES(Inventory.shelf_space);
            ''', (product_id, product_shelf_space, temp_catalog_id, product_id, temp_catalog_id))
            conn.commit()

            alert_message = f'Purchase Order created with ID: {po_var} for {quantity} units of product ID {product_id}. Inventory allocated across multiple warehouses.'

            cursor.execute('''
                INSERT INTO Alerts (entity_type, entity_id, message, alert_date)
                VALUES ('PurchaseOrder', %s, %s, NOW());
            ''', (po_var, alert_message))
            conn.commit()

            print(alert_message)

        except mysql.connector.Error as err:
            print(f"Error: {err}")

        finally:
            cursor.close()
            conn.close()

    def sell_product(self):
        product_id = int(self.sell_id_input.text())
        quantity = int(self.sell_quantity_input.text())
        order_id = int(self.sell_customer_input.text())

        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()

        try:
            cursor.callproc('process_sales_order', [order_id, product_id, quantity])
            conn.commit()

            # 获取存储过程的结果
            for result in cursor.stored_results():
                print(result.fetchall())

        except mysql.connector.Error as err:
            print(f"Error: {err}")

        finally:
            cursor.close()
            conn.close()

    # +++++++++++++++++++++++++++ 功能区 end ++++++++++++++++++++++++++++++++++
    # +++++++++++++++++++++++++++ 功能区 end ++++++++++++++++++++++++++++++++++
    # +++++++++++++++++++++++++++ 功能区 end ++++++++++++++++++++++++++++++++++

    def button_function_1(self):
        # refresh

        self.update_info(self.get_inventory_summary())

    def button_function_2(self):
        # 按钮2的功能
        new_values = [
            ("Inventory remaining", "20000"),
            ("Products on sale", "80"),
            ("Warehouse quantity", "7"),
            ("Total inventory value", "14524000.00")
        ]
        self.update_info(new_values)

    def button_function_3(self):
        self.show_catalog_list()

    def button_function_4(self):
        self.show_order_list()

    def button_function_5(self):
        self.show_most_transferred_products()

    def button_function_6(self):
        self.show_monthly_inventory_changes()

    def button_function_7(self):
        self.show_low_stock_products()

    def button_function_8(self):
        pass

    def button_function_9(self):
        pass

    def button_function_10(self):
        pass

    def button_function_11(self):
        pass

    '''
    def check_alerts(self):
        self.cursor.execute('SELECT * FROM Alerts WHERE alert_id > ?', (self.last_alert_id,))
        alerts = self.cursor.fetchall()

        if alerts:
            self.last_alert_id = max(alert[0] for alert in alerts)

            # 收集所有新的 alert 消息
            alert_messages = "\n".join(
                f"ID: {alert[0]}, Type: {alert[1]}, Entity: {alert[2]}, Message: {alert[3]}, Date: {alert[4]}"
                for alert in alerts
            )

            # 报错
            QMessageBox.information(self, 'Alert', f'\n\n{alert_messages}', QMessageBox.Ok)
    '''

    def update_info(self, new_values: list):
        for (info_label, info_value), (_, new_value) in zip(self.info_boxes, new_values):
            info_value.setText(str(new_value))

    def get_inventory_summary(self):
        # Inventory remaining
        self.cursor.execute('''
        SELECT SUM(quantity) AS total_inventory
        FROM Inventory;
        ''')
        total_inventory = self.cursor.fetchone()[0]

        # Products on sale
        self.cursor.execute('''
        SELECT
            COUNT(DISTINCT product_id) AS on_sale_products
        FROM
            Catalog;
        ''')
        on_sale_products = self.cursor.fetchone()[0]

        # Warehouse quantity
        self.cursor.execute('''
        SELECT
            COUNT(*) AS warehouse_count
        FROM
            Warehouses;
        ''')
        warehouse_count = self.cursor.fetchone()[0]

        # Total inventory value
        self.cursor.execute('''
        SELECT
            SUM(Inventory.quantity * Catalog.price) AS total_inventory_value
        FROM
            Inventory
        JOIN
            Catalog ON Inventory.catalog_id = Catalog.catalog_id;
        ''')
        total_inventory_value = self.cursor.fetchone()[0]

        return [
            ("Inventory remaining", total_inventory),
            ("Products on sale", on_sale_products),
            ("Warehouse quantity", warehouse_count),
            ("Total inventory value", total_inventory_value)
        ]


class ProductListWindow(QDialog):
    def __init__(self, conn, db_config):
        super().__init__()
        self.conn = conn
        self.db_config = db_config
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Product List')
        self.setGeometry(200, 200, 1030, 1200)
        layout = QVBoxLayout()

        self.table = QTableWidget(self)
        self.table.setColumnCount(7)
        self.table.setHorizontalHeaderLabels(['ID', 'Name', 'Description', 'Market Price', 'Safe Stock Lv', 'Healthy Stock Lv', 'Shelf Space'])

        # 设置每列的宽度
        self.table.setColumnWidth(0, 50)   # ID列
        self.table.setColumnWidth(1, 150)  # Name列
        self.table.setColumnWidth(2, 300)  # Description列
        self.table.setColumnWidth(3, 150)  # Selling Price列
        self.table.setColumnWidth(4, 100)  # Safe Stock Level列
        self.table.setColumnWidth(5, 100)  # Healthy Stock Level列
        self.table.setColumnWidth(6, 100)  # Shelf Space列

        self.load_products()

        layout.addWidget(self.table)
        self.setLayout(layout)

    def load_products(self):
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM Products')
        rows = cursor.fetchall()

        self.table.setRowCount(0)
        for row in rows:
            self.table.insertRow(self.table.rowCount())
            for col, data in enumerate(row):
                self.table.setItem(self.table.rowCount() - 1, col, QTableWidgetItem(str(data)))

        cursor.close()


class StockListWindow(QDialog):
    def __init__(self, conn, db_config):
        super().__init__()
        self.conn = conn
        self.db_config = db_config
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Stock List')
        self.setGeometry(200, 200, 1000, 1200)
        layout = QVBoxLayout()

        self.table = QTableWidget(self)
        self.table.setColumnCount(7)
        self.table.setHorizontalHeaderLabels(['Product ID', 'Product Name', 'Warehouse ID', 'Quantity', 'Shelf Space', 'Catalog ID', 'Price'])
        
        # 设置每列的宽度
        self.table.setColumnWidth(0, 100)  # Product ID列
        self.table.setColumnWidth(1, 150)  # Product Name列
        self.table.setColumnWidth(2, 100)  # Warehouse ID列
        self.table.setColumnWidth(3, 100)  # Quantity列
        self.table.setColumnWidth(4, 100)  # Shelf Space列
        self.table.setColumnWidth(5, 100)  # Catalog ID列
        self.table.setColumnWidth(6, 100)  # Price列

        self.load_stock()

        layout.addWidget(self.table)
        self.setLayout(layout)

    def load_stock(self):
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT 
                Inventory.product_id, 
                Products.name AS product_name,
                Inventory.warehouse_id, 
                Inventory.quantity, 
                Inventory.shelf_space, 
                Inventory.catalog_id,
                Catalog.price
            FROM Inventory
            JOIN Catalog ON Inventory.catalog_id = Catalog.catalog_id
            JOIN Products ON Inventory.product_id = Products.product_id
            ORDER BY Inventory.product_id
        ''')
        rows = cursor.fetchall()

        self.table.setRowCount(0)
        for row in rows:
            self.table.insertRow(self.table.rowCount())
            for col, data in enumerate(row):
                self.table.setItem(self.table.rowCount() - 1, col, QTableWidgetItem(str(data)))

        cursor.close()


class CatalogListWindow(QDialog):
    def __init__(self, conn, db_config):
        super().__init__()
        self.conn = conn
        self.db_config = db_config
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Catalog List')
        self.setGeometry(200, 200, 1050, 600)
        layout = QVBoxLayout()

        self.table = QTableWidget(self)
        self.table.setColumnCount(6)
        self.table.setHorizontalHeaderLabels(['ID', 'Product Name', 'Description', 'Supplier Name', 'Max Quantity', 'Selling Price'])

        # 设置每列的宽度
        self.table.setColumnWidth(0, 50)   # ID列
        self.table.setColumnWidth(1, 150)  # Product Name列
        self.table.setColumnWidth(2, 300)  # Description列
        self.table.setColumnWidth(3, 150)  # Supplier Name列
        self.table.setColumnWidth(4, 100)  # Max Quantity列
        self.table.setColumnWidth(5, 200)  # Selling Price列

        self.load_catalog()

        layout.addWidget(self.table)
        self.setLayout(layout)

    def load_catalog(self):
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT 
                Catalog.catalog_id, 
                Products.name AS product_name,
                Products.description,
                Suppliers.name AS supplier_name,
                Catalog.max_quantity, 
                Catalog.price
            FROM Catalog
            JOIN Products ON Catalog.product_id = Products.product_id
            JOIN Suppliers ON Catalog.supplier_id = Suppliers.supplier_id
            ORDER BY Catalog.catalog_id
        ''')
        rows = cursor.fetchall()

        self.table.setRowCount(0)
        for row in rows:
            self.table.insertRow(self.table.rowCount())
            for col, data in enumerate(row):
                self.table.setItem(self.table.rowCount() - 1, col, QTableWidgetItem(str(data)))

        cursor.close()


class OrderListWindow(QDialog):
    def __init__(self, conn, db_config):
        super().__init__()
        self.conn = conn
        self.db_config = db_config
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Order List')
        self.setGeometry(200, 200, 1200, 600)
        layout = QVBoxLayout()

        self.table = QTableWidget(self)
        self.table.setColumnCount(9)
        self.table.setHorizontalHeaderLabels(['Order ID', 'Customer Name', 'Order Date', 'Total Price', 'Delivery Date', 'Status', 'Product Name', 'Quantity', 'Unit price'])
        
        # 设置每列的宽度
        self.table.setColumnWidth(0, 100)  # Order ID列
        self.table.setColumnWidth(1, 150)  # Customer Name列
        self.table.setColumnWidth(2, 100)  # Order Date列
        self.table.setColumnWidth(3, 100)  # Total Price列
        self.table.setColumnWidth(4, 100)  # Delivery Date列
        self.table.setColumnWidth(5, 100)  # Status列
        self.table.setColumnWidth(6, 150)  # Product Name列
        self.table.setColumnWidth(7, 100)  # Quantity列
        self.table.setColumnWidth(8, 100)  # Unit price列

        self.load_orders()

        layout.addWidget(self.table)
        self.setLayout(layout)

    def load_orders(self):
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT 
                SalesOrders.order_id, 
                Customers.name AS customer_name,
                SalesOrders.order_date,
                SalesOrders.total_price,
                SalesOrders.delivery_date,
                SalesOrders.status,
                Products.name AS product_name,
                SalesOrderDetails.quantity,
                SalesOrderDetails.price_for_product
            FROM SalesOrders
            JOIN Customers ON SalesOrders.customer_id = Customers.customer_id
            JOIN SalesOrderDetails ON SalesOrders.order_id = SalesOrderDetails.order_id
            JOIN Products ON SalesOrderDetails.product_id = Products.product_id
            ORDER BY SalesOrders.order_id
        ''')
        rows = cursor.fetchall()

        self.table.setRowCount(0)
        for row in rows:
            self.table.insertRow(self.table.rowCount())
            for col, data in enumerate(row):
                self.table.setItem(self.table.rowCount() - 1, col, QTableWidgetItem(str(data)))

        cursor.close()


class MostTransferredProductsWindow(QDialog):
    def __init__(self, conn, db_config):
        super().__init__()
        self.conn = conn
        self.db_config = db_config
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Most Transferred Products')
        self.setGeometry(200, 200, 800, 600)
        layout = QVBoxLayout()

        self.table = QTableWidget(self)
        self.table.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(['Warehouse ID', 'Product ID', 'Total Transferred', 'Product Name'])

        # 设置每列的宽度
        self.table.setColumnWidth(0, 150)  # Warehouse ID列
        self.table.setColumnWidth(1, 150)  # Product ID列
        self.table.setColumnWidth(2, 150)  # Total Transferred列
        self.table.setColumnWidth(3, 200)  # Product Name列

        self.load_data()

        layout.addWidget(self.table)
        self.setLayout(layout)

    def load_data(self):
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT 
                t.warehouse_id,
                t.product_id,
                t.total_transferred,
                p.name AS product_name
            FROM (
                SELECT 
                    warehouse_id,
                    product_id,
                    SUM(total_transferred) AS total_transferred,
                    ROW_NUMBER() OVER (PARTITION BY warehouse_id ORDER BY SUM(total_transferred) DESC) AS row_order
                FROM (
                    SELECT 
                        from_warehouse_id AS warehouse_id,
                        product_id,
                        SUM(quantity) AS total_transferred
                    FROM 
                        WarehouseTransfers
                    GROUP BY 
                        1,2
                    
                    UNION ALL
                    
                    SELECT 
                        to_warehouse_id AS warehouse_id,
                        product_id,
                        SUM(quantity) AS total_transferred
                    FROM 
                        WarehouseTransfers
                    GROUP BY 
                        1,2
                ) AS transfers
                GROUP BY 
                    1,2
            ) AS t
            JOIN Products p ON t.product_id = p.product_id
            WHERE row_order <= 5
            ORDER BY t.warehouse_id, row_order;
        ''')
        rows = cursor.fetchall()

        self.table.setRowCount(0)
        for row in rows:
            self.table.insertRow(self.table.rowCount())
            for col, data in enumerate(row):
                self.table.setItem(self.table.rowCount() - 1, col, QTableWidgetItem(str(data)))

        cursor.close()


class MonthlyInventoryChangesWindow(QDialog):
    def __init__(self, conn, db_config):
        super().__init__()
        self.conn = conn
        self.db_config = db_config
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Monthly Inventory Changes')
        self.setGeometry(200, 200, 1000, 600)
        layout = QVBoxLayout()

        self.table = QTableWidget(self)
        self.table.setColumnCount(5)
        self.table.setHorizontalHeaderLabels(['Warehouse ID', 'Product ID', 'Month and Year', 'Quantity Change', 'Product Name'])

        # 设置每列的宽度
        self.table.setColumnWidth(0, 150)  # Warehouse ID列
        self.table.setColumnWidth(1, 150)  # Product ID列
        self.table.setColumnWidth(2, 200)  # Month and Year列
        self.table.setColumnWidth(3, 150)  # Quantity Change列
        self.table.setColumnWidth(4, 200)  # Product Name列

        self.load_data()

        layout.addWidget(self.table)
        self.setLayout(layout)

    def load_data(self):
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT 
                i.warehouse_id,
                i.product_id,
                DATE_FORMAT(t.transfer_date, '%Y-%m') AS month_and_year,
                COALESCE(SUM(CASE 
                    WHEN t.from_warehouse_id = i.warehouse_id THEN -t.quantity
                    WHEN t.to_warehouse_id = i.warehouse_id THEN t.quantity
                    ELSE 0 
                END), 0) AS quantity_change,
                p.name AS product_name
            FROM 
                Inventory i
            LEFT JOIN 
                WarehouseTransfers t ON i.product_id = t.product_id 
            JOIN Products p ON i.product_id = p.product_id
            GROUP BY 
                i.warehouse_id, i.product_id, month_and_year
            HAVING 
                quantity_change <> 0
            ORDER BY 
                i.warehouse_id, i.product_id, month_and_year;
        ''')
        rows = cursor.fetchall()

        self.table.setRowCount(0)
        for row in rows:
            self.table.insertRow(self.table.rowCount())
            for col, data in enumerate(row):
                self.table.setItem(self.table.rowCount() - 1, col, QTableWidgetItem(str(data)))

        cursor.close()


class LowStockProductsWindow(QDialog):
    def __init__(self, conn, db_config):
        super().__init__()
        self.conn = conn
        self.db_config = db_config
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Low Stock Products')
        self.setGeometry(200, 200, 1000, 600)
        layout = QVBoxLayout()

        self.table = QTableWidget(self)
        self.table.setColumnCount(5)
        self.table.setHorizontalHeaderLabels(['Product ID', 'Product Name', 'Safe Stock Level', 'Current Stock', 'Restock Needed'])

        # 设置每列的宽度
        self.table.setColumnWidth(0, 150)  # Product ID列
        self.table.setColumnWidth(1, 200)  # Product Name列
        self.table.setColumnWidth(2, 150)  # Safe Stock Level列
        self.table.setColumnWidth(3, 150)  # Current Stock列
        self.table.setColumnWidth(4, 150)  # Restock Needed列

        self.load_data()

        layout.addWidget(self.table)
        self.setLayout(layout)

    def load_data(self):
        cursor = self.conn.cursor()
        cursor.execute('''
            SELECT
                P.product_id,
                P.name AS product_name,
                P.safe_stock_level,
                SUM(I.quantity) AS current_stock,
                (P.safe_stock_level - SUM(I.quantity)) AS restock_needed
            FROM
                Products P
            LEFT JOIN
                Inventory I ON P.product_id = I.product_id
            GROUP BY
                P.product_id, P.name, P.safe_stock_level
            HAVING
                current_stock < P.safe_stock_level;
        ''')
        rows = cursor.fetchall()

        self.table.setRowCount(0)
        for row in rows:
            self.table.insertRow(self.table.rowCount())
            for col, data in enumerate(row):
                self.table.setItem(self.table.rowCount() - 1, col, QTableWidgetItem(str(data)))

        cursor.close()


if __name__ == '__main__':
    app = QApplication(sys.argv)

    # 设置字体
    font = QFont("SimSun", 9)
    app.setFont(font)

    window = ProductApp()
    window.show()
    sys.exit(app.exec_())
