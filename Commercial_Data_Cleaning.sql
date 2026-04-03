-- ============================================================
-- SQL PROJECT QUERIES
-- Database: Commercial / Northwind-style database
-- Compatible with: SQL Server Management Studio (SSMS)
-- ============================================================


-- ============================================================
-- QUERY 2
-- Display male employees whose net salary (salary + commission)
-- >= 8000, ordered by descending seniority.
-- Columns: Employee Number, Full Name, Age, Seniority
-- ============================================================

SELECT
    EMPLOYEE_int                                        AS [Employee Number],
    FIRST_NAME + ' ' + LAST_NAME                       AS [First Name and Last Name],
    DATEDIFF(YEAR, BIRTH_DATE, GETDATE())               AS [Age],
    DATEDIFF(YEAR, HIRE_DATE,  GETDATE())               AS [Seniority]
FROM EMPLOYEES
WHERE TITLE IN ('Mr.', 'Dr.')                          -- Male employees
  AND (SALARY + ISNULL(COMMISSION, 0)) >= 8000          -- Net salary condition
ORDER BY [Seniority] DESC;                             -- Most senior first


-- ============================================================
-- QUERY 3
-- Display products meeting ALL five criteria:
--   C1: Quantity packaged in bottle(s)
--   C2: 3rd character of product name is 't' or 'T'
--   C3: Supplier number is 1, 2, or 3
--   C4: Unit price between 70 and 200
--   C5: Units on order is not null
-- Columns: product number, product name, supplier number,
--          units ordered, unit price
-- ============================================================

SELECT
    PRODUCT_REF     AS [Product Number],
    PRODUCT_NAME    AS [Product Name],
    SUPPLIER_int    AS [Supplier Number],
    UNITS_ON_ORDER  AS [Units Ordered],
    UNIT_PRICE      AS [Unit Price]
FROM PRODUCTS
WHERE QUANTITY        LIKE '%bottle%'                    -- C1: packaged in bottles
  AND SUBSTRING(PRODUCT_NAME, 3, 1) IN ('t', 'T')       -- C2: 3rd char is t/T
  AND SUPPLIER_int    IN (1, 2, 3)                       -- C3: supplier 1, 2, or 3
  AND UNIT_PRICE      BETWEEN 70 AND 200                 -- C4: price range
  AND UNITS_ON_ORDER  IS NOT NULL;                       -- C5: not null


-- ============================================================
-- QUERY 4
-- Display customers who reside in the same region as supplier 1
-- (same country, city, and last 3 digits of postal code).
-- Uses a SINGLE subquery.
-- Columns: all columns from CUSTOMERS
-- ============================================================

SELECT C.*
FROM CUSTOMERS C,
     (
         SELECT
             COUNTRY,
             CITY,
             RIGHT(POSTAL_CODE, 3) AS LAST3_PC
         FROM SUPPLIERS
         WHERE SUPPLIER_int = 1
     ) AS S
WHERE C.COUNTRY            = S.COUNTRY
  AND C.CITY               = S.CITY
  AND RIGHT(C.POSTAL_CODE, 3) = S.LAST3_PC;


-- ============================================================
-- QUERY 5
-- For each order between 10998 and 11003:
--   - New discount rate based on total order amount before discount
--   - Note: "apply old discount rate" if order between 10000–10999,
--           "apply new discount rate" otherwise
-- Columns: order number, new discount rate, discount rate note
-- ============================================================

SELECT
    OD.ORDER_int AS [Order Number],

    CASE
        WHEN SUM(OD.UNIT_PRICE * OD.QUANTITY) BETWEEN 0     AND 2000  THEN '0%'
        WHEN SUM(OD.UNIT_PRICE * OD.QUANTITY) BETWEEN 2001  AND 10000 THEN '5%'
        WHEN SUM(OD.UNIT_PRICE * OD.QUANTITY) BETWEEN 10001 AND 40000 THEN '10%'
        WHEN SUM(OD.UNIT_PRICE * OD.QUANTITY) BETWEEN 40001 AND 80000 THEN '15%'
        ELSE '20%'
    END AS [New Discount Rate],

    CASE
        WHEN OD.ORDER_int BETWEEN 10000 AND 10999 THEN 'Apply old discount rate'
        ELSE 'Apply new discount rate'
    END AS [Discount Rate Application Note]

FROM ORDER_DETAILS OD
WHERE OD.ORDER_int BETWEEN 10998 AND 11003
GROUP BY OD.ORDER_int;


-- ============================================================
-- QUERY 6
-- Display suppliers of beverage products.
-- Columns: supplier number, company, address, phone number
-- ============================================================

SELECT DISTINCT
    S.SUPPLIER_int  AS [Supplier Number],
    S.COMPANY       AS [Company],
    S.ADDRESS       AS [Address],
    S.PHONE         AS [Phone Number]
FROM SUPPLIERS S
INNER JOIN PRODUCTS   P ON S.SUPPLIER_int  = P.SUPPLIER_int
INNER JOIN CATEGORIES C ON P.CATEGORY_CODE = C.CATEGORY_CODE
WHERE C.CATEGORY_NAME = 'Beverages';


-- ============================================================
-- QUERY 7
-- Display customers from Berlin who have ordered AT MOST 1
-- dessert product (0 or 1 dessert product ordered).
-- Column: customer code
-- ============================================================

SELECT C.CUSTOMER_CODE
FROM CUSTOMERS C
WHERE C.CITY = 'Berlin'
  AND (
          SELECT COUNT(DISTINCT OD.PRODUCT_REF)
          FROM   ORDERS       O
          JOIN   ORDER_DETAILS OD  ON O.ORDER_int      = OD.ORDER_int
          JOIN   PRODUCTS      P   ON OD.PRODUCT_REF   = P.PRODUCT_REF
          JOIN   CATEGORIES    CAT ON P.CATEGORY_CODE  = CAT.CATEGORY_CODE
          WHERE  O.CUSTOMER_CODE  = C.CUSTOMER_CODE
            AND  CAT.CATEGORY_NAME = 'Desserts'
      ) <= 1;


-- ============================================================
-- QUERY 8
-- Display customers from France and the total amount of orders
-- placed every Monday in April 1998.
-- Include customers who have placed no such orders (LEFT JOIN).
-- Columns: customer number, company name, phone, total amount, country
-- ============================================================

SELECT
    C.CUSTOMER_CODE                                                       AS [Customer Number],
    C.COMPANY                                                             AS [Company Name],
    C.PHONE                                                               AS [Phone Number],
    ISNULL(SUM(OD.UNIT_PRICE * OD.QUANTITY * (1 - OD.DISCOUNT)), 0)      AS [Total Amount],
    C.COUNTRY                                                             AS [Country]
FROM CUSTOMERS C
LEFT JOIN ORDERS O
       ON  C.CUSTOMER_CODE   = O.CUSTOMER_CODE
       AND YEAR(O.ORDER_DATE)        = 1998
       AND MONTH(O.ORDER_DATE)       = 4
       AND DATENAME(WEEKDAY, O.ORDER_DATE) = 'Monday'
LEFT JOIN ORDER_DETAILS OD
       ON O.ORDER_int = OD.ORDER_int
WHERE C.COUNTRY = 'France'
GROUP BY C.CUSTOMER_CODE, C.COMPANY, C.PHONE, C.COUNTRY;


-- ============================================================
-- QUERY 9
-- Display customers who have ordered ALL products.
-- Columns: customer code, company name, telephone number
-- ============================================================

SELECT
    C.CUSTOMER_CODE AS [Customer Code],
    C.COMPANY       AS [Company Name],
    C.PHONE         AS [Telephone Number]
FROM CUSTOMERS C
WHERE NOT EXISTS
      (
          -- Products that this customer has NOT ordered
          SELECT P.PRODUCT_REF
          FROM   PRODUCTS P
          WHERE  NOT EXISTS
                 (
                     SELECT 1
                     FROM   ORDERS       O
                     JOIN   ORDER_DETAILS OD ON O.ORDER_int = OD.ORDER_int
                     WHERE  O.CUSTOMER_CODE = C.CUSTOMER_CODE
                       AND  OD.PRODUCT_REF  = P.PRODUCT_REF
                 )
      );


-- ============================================================
-- QUERY 10
-- For each customer from France, display the number of orders.
-- Columns: customer code, number of orders
-- ============================================================

SELECT
    C.CUSTOMER_CODE             AS [Customer Code],
    COUNT(O.ORDER_int)          AS [Number of Orders]
FROM CUSTOMERS C
LEFT JOIN ORDERS O ON C.CUSTOMER_CODE = O.CUSTOMER_CODE
WHERE C.COUNTRY = 'France'
GROUP BY C.CUSTOMER_CODE;


-- ============================================================
-- QUERY 11
-- Display number of orders in 1996, in 1997, and their difference.
-- Columns: Orders in 1996, Orders in 1997, Difference
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM ORDERS WHERE YEAR(ORDER_DATE) = 1996) AS [Orders in 1996],
    (SELECT COUNT(*) FROM ORDERS WHERE YEAR(ORDER_DATE) = 1997) AS [Orders in 1997],
    (SELECT COUNT(*) FROM ORDERS WHERE YEAR(ORDER_DATE) = 1996)
  - (SELECT COUNT(*) FROM ORDERS WHERE YEAR(ORDER_DATE) = 1997) AS [Difference];