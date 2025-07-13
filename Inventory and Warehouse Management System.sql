DROP DATABASE IF EXISTS warehouse_db;
CREATE DATABASE warehouse_db;
USE warehouse_db;


CREATE TABLE Warehouses (
    warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_name VARCHAR(100),
    location VARCHAR(100)
);


CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_name VARCHAR(100),
    contact_info VARCHAR(150)
);


CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    description TEXT,
    unit_price DECIMAL(10, 2),
    reorder_level INT DEFAULT 10 
);

CREATE TABLE Stock (
    stock_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    warehouse_id INT,
    quantity INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);



INSERT INTO Warehouses (warehouse_name, location)
VALUES ('Central Warehouse', 'Delhi'),
       ('East Zone Warehouse', 'Kolkata'),
       ('West Zone Warehouse', 'Mumbai');


INSERT INTO Suppliers (supplier_name, contact_info)
VALUES ('ABC Traders', 'abc@traders.com'),
       ('Global Supplies', 'global@supplies.com');


INSERT INTO Products (product_name, description, unit_price, reorder_level)
VALUES ('Laptop', 'Dell i5 11th Gen', 55000.00, 5),
       ('Mouse', 'Wireless Mouse', 500.00, 10),
       ('Keyboard', 'Mechanical Keyboard', 1500.00, 8);


INSERT INTO Stock (product_id, warehouse_id, quantity)
VALUES (1, 1, 20),
       (2, 1, 8),
       (3, 1, 15),
       (1, 2, 2),
       (2, 2, 4),
       (3, 2, 5);
       
       SELECT p.product_name, w.warehouse_name, s.quantity
FROM Stock s
JOIN Products p ON s.product_id = p.product_id
JOIN Warehouses w ON s.warehouse_id = w.warehouse_id;

SELECT p.product_name, w.warehouse_name, s.quantity, p.reorder_level
FROM Stock s
JOIN Products p ON s.product_id = p.product_id
JOIN Warehouses w ON s.warehouse_id = w.warehouse_id
WHERE s.quantity < p.reorder_level;

CREATE TABLE StockAlerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    warehouse_id INT,
    alert_message VARCHAR(255),
    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER trg_low_stock
AFTER UPDATE ON Stock
FOR EACH ROW
BEGIN
    IF NEW.quantity < (SELECT reorder_level FROM Products WHERE product_id = NEW.product_id) THEN
        INSERT INTO StockAlerts (product_id, warehouse_id, alert_message)
        VALUES (NEW.product_id, NEW.warehouse_id, CONCAT('Low stock alert for product ID ', NEW.product_id));
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE transfer_stock (
    IN prod_id INT,
    IN from_warehouse INT,
    IN to_warehouse INT,
    IN qty INT
)
BEGIN
    DECLARE available_qty INT;

    -- Check available stock
    SELECT quantity INTO available_qty
    FROM Stock
    WHERE product_id = prod_id AND warehouse_id = from_warehouse;

    IF available_qty >= qty THEN
        -- Deduct from source warehouse
        UPDATE Stock
        SET quantity = quantity - qty
        WHERE product_id = prod_id AND warehouse_id = from_warehouse;

        -- Add to target warehouse
        INSERT INTO Stock (product_id, warehouse_id, quantity)
        VALUES (prod_id, to_warehouse, qty)
        ON DUPLICATE KEY UPDATE quantity = quantity + qty;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough stock to transfer.';
    END IF;
END$$

DELIMITER ;

CALL transfer_stock(3, 1, 2, 5);

SELECT * FROM Stock WHERE product_id = 1 AND warehouse_id = 2;

SELECT * FROM StockAlerts;

UPDATE Stock
SET quantity = 4
WHERE product_id = 1 AND warehouse_id = 2;

SELECT * FROM Stock WHERE product_id = 1 AND warehouse_id = 2;
SELECT * FROM StockAlerts ORDER BY alert_time DESC;



