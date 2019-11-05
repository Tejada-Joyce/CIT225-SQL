-- ------------------------------------------------------------------
--  Program Name:   apply_oracle_lab8.sql
--  Lab Assignment: Lab #8
--  Program Author: Michael McLaughlin
--  Creation Date:  02-Mar-2018
-- ------------------------------------------------------------------
-- Instructions:
-- ------------------------------------------------------------------
-- The two scripts contain spooling commands, which is why there
-- isn't a spooling command in this script. When you run this file
-- you first connect to the Oracle database with this syntax:
--
--   sqlplus student/student@xe
--
-- Then, you call this script with the following syntax:
--
--   sql> @apply_oracle_lab8.sql
--
-- ------------------------------------------------------------------

-- Call library files.
@/home/student/Data/cit225/oracle/lab7/apply_oracle_lab7.sql

-- Open log file.
SPOOL apply_oracle_lab8.txt

-- Set the page size.
SET ECHO ON
SET PAGESIZE 999

-- --------------------------------------------------------
--  Step #1
--  -------------------------------------------------------
--  Using the query from Lab 7, Step 4, insert the 135
--  rows in the PRICE table created in Lab 6.
-- --------------------------------------------------------
 
-- Insert step #1 statements here.
 
-- --------------------------------------------------------
INSERT INTO price
( price_id
, item_id
, price_type
, active_flag
, start_date
, end_date
, amount
, created_by
, creation_date
, last_updated_by
, last_update_date )
SELECT 
         price_s1.nextval AS price_id
,        i.item_id
,        cl.common_lookup_id AS price_type
,        af.active_flag
,        CASE
           WHEN  (TRUNC(SYSDATE) - i.release_date) <= 30 OR (TRUNC(SYSDATE) - i.release_date) > 30 AND af.active_flag = 'N'
           THEN  i.release_date
           ELSE  i.release_date + 31
         END AS start_date
,        CASE
           WHEN  (TRUNC(SYSDATE) - i.release_date) > 30 AND af.active_flag = 'N' THEN i.release_date + 30
         END AS end_date
,        CASE
           WHEN  (TRUNC(SYSDATE) - i.release_date) <= 30 THEN 
            CASE 
                WHEN dr.rental_days = 1 THEN 3
                WHEN dr.rental_days = 3 THEN 10
                WHEN dr.rental_days = 5 THEN 15
            END 
           WHEN  (TRUNC(SYSDATE) - i.release_date) > 30 AND af.active_flag = 'N' THEN 
            CASE 
                WHEN dr.rental_days = 1 THEN 3
                WHEN dr.rental_days = 3 THEN 10
                WHEN dr.rental_days = 5 THEN 15
            END    
           ELSE 
            CASE 
                WHEN dr.rental_days = 1 THEN 1
                WHEN dr.rental_days = 3 THEN 3
                WHEN dr.rental_days = 5 THEN 5
            END 
         END AS amount
,        1 AS created_by
,        SYSDATE AS creation_date
,        1 AS last_updated_by
,        SYSDATE AS last_update_date
FROM     item i CROSS JOIN
        (SELECT 'Y' AS active_flag FROM dual
         UNION ALL
         SELECT 'N' AS active_flag FROM dual) af CROSS JOIN
        (SELECT '1' AS rental_days FROM dual
         UNION ALL
         SELECT '3' AS rental_days FROM dual
         UNION ALL
         SELECT '5' AS rental_days FROM dual) dr INNER JOIN
         common_lookup cl ON dr.rental_days = SUBSTR(cl.common_lookup_type,1,1)
WHERE    cl.common_lookup_table = 'PRICE'
AND      cl.common_lookup_column = 'PRICE_TYPE'
AND NOT ( af.active_flag = 'N' AND (TRUNC(SYSDATE) - 30) < i.release_date );

-- ----------------------------------------------------------------------
--  Step #1 : Verify completion.
-- ----------------------------------------------------------------------
SELECT  'OLD Y' AS "Type"
,        COUNT(CASE WHEN amount = 1 THEN 1 END) AS "1-Day"
,        COUNT(CASE WHEN amount = 3 THEN 1 END) AS "3-Day"
,        COUNT(CASE WHEN amount = 5 THEN 1 END) AS "5-Day"
,        COUNT(*) AS "TOTAL"
FROM     price p , item i
WHERE    active_flag = 'Y' AND i.item_id = p.item_id
AND     (TRUNC(SYSDATE) - TRUNC(i.release_date)) > 30
AND      end_date IS NULL
UNION ALL
SELECT  'OLD N' AS "Type"
,        COUNT(CASE WHEN amount =  3 THEN 1 END) AS "1-Day"
,        COUNT(CASE WHEN amount = 10 THEN 1 END) AS "3-Day"
,        COUNT(CASE WHEN amount = 15 THEN 1 END) AS "5-Day"
,        COUNT(*) AS "TOTAL"
FROM     price p , item i
WHERE    active_flag = 'N' AND i.item_id = p.item_id
AND     (TRUNC(SYSDATE) - TRUNC(i.release_date)) > 30
AND NOT end_date IS NULL
UNION ALL
SELECT  'NEW Y' AS "Type"
,        COUNT(CASE WHEN amount =  3 THEN 1 END) AS "1-Day"
,        COUNT(CASE WHEN amount = 10 THEN 1 END) AS "3-Day"
,        COUNT(CASE WHEN amount = 15 THEN 1 END) AS "5-Day"
,        COUNT(*) AS "TOTAL"
FROM     price p , item i
WHERE    active_flag = 'Y' AND i.item_id = p.item_id
AND     (TRUNC(SYSDATE) - TRUNC(i.release_date)) < 31
AND      end_date IS NULL
UNION ALL
SELECT  'NEW N' AS "Type"
,        COUNT(CASE WHEN amount = 1 THEN 1 END) AS "1-Day"
,        COUNT(CASE WHEN amount = 3 THEN 1 END) AS "3-Day"
,        COUNT(CASE WHEN amount = 5 THEN 1 END) AS "5-Day"
,        COUNT(*) AS "TOTAL"
FROM     price p , item i
WHERE    active_flag = 'N' AND i.item_id = p.item_id
AND     (TRUNC(SYSDATE) - TRUNC(i.release_date)) < 31
AND      NOT (end_date IS NULL);
-- ----------------------------------------------------------------------
--  Step #2 : After inserting the data into the PRICE table, you should
--            add the NOT NULL constraint to the PRICE_TYPE column of
--            the PRICE table.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #2 : Add a constraint to PRICE table.
-- ----------------------------------------------------------------------

ALTER TABLE price
MODIFY (price_type NUMBER(22) CONSTRAINT nn_price_9 NOT NULL);


-- ----------------------------------------------------------------------
--  Step #2 : Verify the constraint is added to the PRICE table.
-- ----------------------------------------------------------------------
COLUMN CONSTRAINT FORMAT A10
SELECT   TABLE_NAME
,        column_name
,        CASE
           WHEN NULLABLE = 'N' THEN 'NOT NULL'
           ELSE 'NULLABLE'
         END AS CONSTRAINT
FROM     user_tab_columns
WHERE    TABLE_NAME = 'PRICE'
AND      column_name = 'PRICE_TYPE';

-- --------------------------------------------------------
--  Step #3
--  -------------------------------------------------------
--  Update the RENTAL_ITEM_PRICE column with valid price
--  values in the RENTAL_ITEM table.
-- --------------------------------------------------------
 
-- Insert step #3 statements here.
 
-- --------------------------------------------------------

-- Update the RENTAL_ITEM_PRICE column with valid values.
-- ----------------------------------------------------------------------
--   a. The TRUNC(SYSDATE + 1) value guarantees a range match when
--       inputs weren't truncated.
--   b. Change all the entries in the RENTAL table to TRUNC(SYSDATE)
--      values.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #3 : Fix the following update statement.
-- ----------------------------------------------------------------------
UPDATE   rental_item ri
SET      rental_item_price =
          (SELECT   p.amount
           FROM     price p INNER JOIN common_lookup cl1
           ON       p.price_type = cl1.common_lookup_id CROSS JOIN rental r
                    CROSS JOIN common_lookup cl2
           WHERE    p.item_id = ri.item_id
           AND      ri.rental_id = r.rental_id
           AND      ri.rental_item_type = cl2.common_lookup_id
           AND      cl1.common_lookup_code = cl2.common_lookup_code
           AND      r.check_out_date
                      BETWEEN p.start_date AND NVL(p.end_date, TRUNC(SYSDATE+1)));

-- ----------------------------------------------------------------------
--  Verify #3 : Query the RENTAL_ITEM_PRICE values.
-- ----------------------------------------------------------------------

-- Widen the display console.
SET LINESIZE 110
 
-- Set the column display values.
COL customer_name          FORMAT A20  HEADING "Contact|--------|Customer Name"
COL contact_id             FORMAT 9999 HEADING "Contact|--------|Contact|ID #"
COL customer_id            FORMAT 9999 HEADING "Rental|--------|Customer|ID #"
COL r_rental_id            FORMAT 9999 HEADING "Rental|------|Rental|ID #"
COL ri_rental_id           FORMAT 9999 HEADING "Rental|Item|------|Rental|ID #"
COL rental_item_id         FORMAT 9999 HEADING "Rental|Item|------||ID #"
COL price_item_id          FORMAT 9999 HEADING "Price|------|Item|ID #"
COL rental_item_item_id    FORMAT 9999 HEADING "Rental|Item|------|Item|ID #"
COL rental_item_price      FORMAT 9999 HEADING "Rental|Item|------||Price"
COL amount                 FORMAT 9999 HEADING "Price|------||Amount"
COL price_type_code        FORMAT 9999 HEADING "Price|------|Type|Code"
COL rental_item_type_code  FORMAT 9999 HEADING "Rental|Item|------|Type|Code"
SELECT   c.last_name||', '||c.first_name
||       CASE
           WHEN c.middle_name IS NOT NULL THEN ' '||c.middle_name
         END AS customer_name
,        c.contact_id
,        r.customer_id
,        r.rental_id AS r_rental_id
,        ri.rental_id AS ri_rental_id
,        ri.rental_item_id
,        p.item_id AS price_item_id
,        ri.item_id AS rental_item_item_id
,        ri.rental_item_price
,        p.amount
,        TO_NUMBER(cl2.common_lookup_code) AS price_type_code
,        TO_NUMBER(cl2.common_lookup_code) AS rental_item_type_code
FROM     price p INNER JOIN common_lookup cl1
ON       p.price_type = cl1.common_lookup_id
AND      cl1.common_lookup_table = 'PRICE'
AND      cl1.common_lookup_column = 'PRICE_TYPE' FULL JOIN rental_item ri 
ON       p.item_id = ri.item_id INNER JOIN common_lookup cl2
ON       ri.rental_item_type = cl2.common_lookup_id
AND      cl2.common_lookup_table = 'RENTAL_ITEM'
AND      cl2.common_lookup_column = 'RENTAL_ITEM_TYPE' RIGHT JOIN rental r
ON       ri.rental_id = r.rental_id FULL JOIN contact c
ON       r.customer_id = c.contact_id
WHERE    cl1.common_lookup_code = cl2.common_lookup_code
AND      r.check_out_date
BETWEEN  p.start_date AND NVL(p.end_date,TRUNC(SYSDATE) + 1)
ORDER BY 2, 3;
 
-- Reset the column display values to their default value.
SET LINESIZE 80

-- ----------------------------------------------------------------------
--  Step #4 : Add NOT NULL constraint on RENTAL_ITEM_PRICE column
--            of the RENTAL_ITEM table.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #4 : Alter the RENTAL_ITEM table.
-- ----------------------------------------------------------------------
ALTER TABLE rental_item
MODIFY (rental_item_price NUMBER CONSTRAINT nn_rental_item_8 NOT NULL);

-- ----------------------------------------------------------------------
--  Verify #4 : Add NOT NULL constraint on RENTAL_ITEM_PRICE column
--              of the RENTAL_ITEM table.
-- ----------------------------------------------------------------------
COLUMN CONSTRAINT FORMAT A10
SELECT   TABLE_NAME
,        column_name
,        CASE
           WHEN NULLABLE = 'N' THEN 'NOT NULL'
           ELSE 'NULLABLE'
         END AS CONSTRAINT
FROM     user_tab_columns
WHERE    TABLE_NAME = 'RENTAL_ITEM'
AND      column_name = 'RENTAL_ITEM_PRICE';

SPOOL OFF

-- Make all changes permanent.
COMMIT;
