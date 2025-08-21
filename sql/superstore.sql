-- created a new schema and named it as superstore
-- using the table data import wizard imported the data from the cleaned and formatted CSV file into a single table and named it superstore

select * from superstore;

-- Modifying the order date and ship date column formats from DateTime to just Date

ALTER TABLE superstore MODIFY COLUMN Order_Date DATE;
ALTER TABLE superstore MODIFY COLUMN Ship_Date DATE;

-- ==========================================================
-- normalizing the single flat table into multiple tables
-- ==========================================================
DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;

-- Create Customers table

CREATE TABLE Customers (
    Customer_ID VARCHAR(20) PRIMARY KEY,
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50)
);

-- Insert unique customers (resolve duplicates by using GROUP BY)

INSERT INTO Customers (Customer_ID, Customer_Name, Segment, Country, City, State, Postal_Code, Region)
SELECT 
    Customer_ID,
    MAX(Customer_Name),
    MAX(Segment),
    MAX(Country),
    MAX(City),
    MAX(State),
    MAX(Postal_Code),
    MAX(Region)
FROM superstore
GROUP BY Customer_ID;

-- Create Products table

CREATE TABLE Products (
    Product_ID VARCHAR(20) PRIMARY KEY,
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(200)
);

-- Insert unique products
INSERT INTO Products (Product_ID, Category, Sub_Category, Product_Name)
SELECT 
    Product_ID,
    MAX(Category),
    MAX(Sub_Category),
    MAX(Product_Name)
FROM superstore
GROUP BY Product_ID;

-- Create Orders table

CREATE TABLE Orders (
    Order_ID VARCHAR(20) PRIMARY KEY,
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(20),
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID)
);

-- Insert orders that reference valid customers
INSERT INTO Orders (Order_ID, Order_Date, Ship_Date, Ship_Mode, Customer_ID)
SELECT DISTINCT 
    s.Order_ID,
    s.Order_Date,
    s.Ship_Date,
    s.Ship_Mode,
    s.Customer_ID
FROM superstore s
WHERE s.Customer_ID IN (SELECT Customer_ID FROM Customers);

-- Create OrderDetails table

CREATE TABLE OrderDetails (
    OrderDetail_ID INT AUTO_INCREMENT PRIMARY KEY,
    Order_ID VARCHAR(20),
    Product_ID VARCHAR(20),
    Sales DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(5,2),
    Profit DECIMAL(10,2),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

-- Insert order details that reference valid orders & products
INSERT INTO OrderDetails (Order_ID, Product_ID, Sales, Quantity, Discount, Profit)
SELECT 
    s.Order_ID,
    s.Product_ID,
    s.Sales,
    s.Quantity,
    s.Discount,
    s.Profit
FROM superstore s
WHERE s.Order_ID IN (SELECT Order_ID FROM Orders)
  AND s.Product_ID IN (SELECT Product_ID FROM Products);
 
-- ===================================================
	-- analysing the data for businees insights
-- ===================================================

-- Total number of customers
  
SELECT COUNT(*) AS Total_Customers
FROM Customers;

-- Finding total sales and total profit

SELECT 
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Total_Profit
FROM OrderDetails;

-- sales by region

SELECT 
    c.Region,
    ROUND(SUM(od.Sales),2) AS Total_Sales
FROM OrderDetails od
JOIN Orders o ON od.Order_ID = o.Order_ID
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region
ORDER BY Total_Sales DESC;

-- top5 customers by sales

SELECT 
    c.Customer_Name,
    ROUND(SUM(od.Sales),2) AS Total_Sales
FROM OrderDetails od
JOIN Orders o ON od.Order_ID = o.Order_ID
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY c.Customer_ID, c.Customer_Name
ORDER BY Total_Sales DESC
LIMIT 5;

-- sales and profit by category and sub-category

SELECT 
    p.Category,
    p.Sub_Category,
    ROUND(SUM(od.Sales),2) AS Total_Sales,
    ROUND(SUM(od.Profit),2) AS Total_Profit
FROM OrderDetails od
JOIN Products p ON od.Product_ID = p.Product_ID
GROUP BY p.Category, p.Sub_Category
ORDER BY Total_Sales DESC;

-- monthly sales trend

SELECT 
    DATE_FORMAT(o.Order_Date, '%Y-%m') AS Month,
    ROUND(SUM(od.Sales),2) AS Total_Sales
FROM OrderDetails od
JOIN Orders o ON od.Order_ID = o.Order_ID
GROUP BY DATE_FORMAT(o.Order_Date, '%Y-%m')
ORDER BY Month;

-- top10 profitable products

SELECT 
    p.Product_Name,
    ROUND(SUM(od.Profit),2) AS Total_Profit
FROM OrderDetails od
JOIN Products p ON od.Product_ID = p.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Total_Profit DESC
LIMIT 10;

-- average discount by region

SELECT 
    c.Region,
    ROUND(AVG(od.Discount),2) AS Avg_Discount
FROM OrderDetails od
JOIN Orders o ON od.Order_ID = o.Order_ID
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region
ORDER BY Avg_Discount DESC;

-- top10 losing orders or orders with negative profits

SELECT 
    o.Order_ID,
    SUM(od.Sales) AS Order_Sales,
    SUM(od.Profit) AS Order_Profit
FROM OrderDetails od
JOIN Orders o ON od.Order_ID = o.Order_ID
GROUP BY o.Order_ID
HAVING SUM(od.Profit) < 0
ORDER BY Order_Profit ASC
LIMIT 10;

-- life time values of top10 customers

SELECT 
    c.Customer_Name,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    ROUND(SUM(od.Sales),2) AS Total_Sales,
    ROUND(SUM(od.Profit),2) AS Total_Profit
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
JOIN OrderDetails od ON o.Order_ID = od.Order_ID
GROUP BY c.Customer_ID, c.Customer_Name
ORDER BY Total_Sales DESC
LIMIT 10;





  
  
  
  

