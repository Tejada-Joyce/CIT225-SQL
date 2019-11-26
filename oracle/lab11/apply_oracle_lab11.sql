-- ------------------------------------------------------------------
--  Program Name:   apply_oracle_lab11.sql
--  Lab Assignment: Lab #11
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
--   sql> @apply_oracle_lab11.sql
--
-- ------------------------------------------------------------------

-- Run the prior lab script.
@/home/student/Data/cit225/oracle/lab9/apply_oracle_lab9.sql

-- Spool log file.
SPOOL apply_oracle_lab11.txt

-- --------------------------------------------------------
--  Step #1 : Merge statement to the rental table.
-- --------------------------------------------------------

-- Count rentals before insert.
SELECT   COUNT(*) AS "Rental before count"
FROM     rental;

-- Merge transaction data into rental table.
MERGE INTO rental target
USING ( SELECT   DISTINCT
         r.rental_id
,        c.contact_id
,        tu.check_out_date AS check_out_date
,        tu.return_date AS return_date
,        1 AS created_by
,        TRUNC(SYSDATE) AS creation_date
,        1 AS last_updated_by
,        TRUNC(SYSDATE) AS last_update_date
FROM     member m INNER JOIN contact c
ON       m.member_id = c.member_id INNER JOIN transaction_upload tu
ON       c.first_name = tu.first_name
AND      NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
AND      c.last_name = tu.last_name
AND       tu.account_number = m.account_number
LEFT JOIN rental r
ON       c.contact_id = r.customer_id
AND      TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
AND      TRUNC(tu.return_date) = TRUNC(r.return_date)) source
ON (target.rental_id = source.rental_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( rental_s1.NEXTVAL
, source.contact_id
, source.check_out_date
, source.return_date
, source.created_by
, source.creation_date
, source.last_updated_by
, source.last_update_date);


-- Count rentals after insert.
SELECT   COUNT(*) AS "Rental after merge"
FROM     rental;

-- --------------------------------------------------------
--  Step #2 : Merge statement to the rental_item table.
-- --------------------------------------------------------

-- Count rental items before insert.
SELECT   COUNT(*)
FROM     rental_item;

-- Merge transaction data into rental_item table.
MERGE INTO rental_item target
USING ( SELECT   
         ri.rental_item_id
,        r.rental_id
,        tu.item_id
,        TRUNC(r.return_date) - TRUNC(r.check_out_date) AS rental_item_price
,        cl.common_lookup_id AS rental_item_type
,        1001 AS created_by
,        TRUNC(SYSDATE) AS creation_date
,        1001 AS last_updated_by
,        TRUNC(SYSDATE) AS last_update_date
FROM     member m INNER JOIN contact c
         ON       m.member_id = c.member_id INNER JOIN transaction_upload tu
         ON       c.first_name = tu.first_name
         AND      NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
         AND      c.last_name = tu.last_name
         AND       tu.account_number = m.account_number
         LEFT JOIN rental r
         ON       c.contact_id = r.customer_id
         AND      TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
         AND      TRUNC(tu.return_date) = TRUNC(r.return_date)
         INNER JOIN common_lookup cl
         ON      cl.common_lookup_table = 'RENTAL_ITEM'         
         AND     cl.common_lookup_column = 'RENTAL_ITEM_TYPE'         
         AND     cl.common_lookup_type = tu.rental_item_type
         LEFT JOIN rental_item ri
         ON      r.rental_id = ri.rental_id) source
ON (target.rental_item_id = source.rental_item_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
(  rental_item_s1.nextval
 , source.rental_id
 , source.item_id
 , source.created_by
 , source.creation_date
 , source.last_updated_by
 , source.last_update_date
 , source.rental_item_type
 , source.rental_item_price);


-- Count rental items after insert.
SELECT   COUNT(*) AS "Rental Item after merge"
FROM     rental_item;

-- --------------------------------------------------------
--  Step #3 : Merge statement to the transaction table.
-- --------------------------------------------------------

-- Count transactions before insert
SELECT   COUNT(*) AS "Before Insert"
FROM     transaction;

-- Merge transaction data into transaction table.
MERGE INTO transaction target
USING ( SELECT    t.transaction_id
         ,        tu.payment_account_number AS transaction_account
         ,        cl1.common_lookup_id AS transaction_type
         ,        tu.transaction_date
         ,       (SUM(tu.transaction_amount) / 1.06) AS transaction_amount
         ,        r.rental_id
         ,        cl2.common_lookup_id AS payment_method_type
         ,        m.credit_card_number AS payment_account_number
         ,        1001 AS created_by
         ,        TRUNC(SYSDATE) AS creation_date
         ,        1001 AS last_updated_by
         ,        TRUNC(SYSDATE) AS last_update_date
         FROM     member m INNER JOIN contact c
         ON       m.member_id = c.member_id INNER JOIN transaction_upload tu
         ON       c.first_name = tu.first_name
         AND      NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
         AND      c.last_name = tu.last_name
         AND       tu.account_number = m.account_number
         LEFT JOIN rental r
         ON       c.contact_id = r.customer_id
         AND      TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
         AND      TRUNC(tu.return_date) = TRUNC(r.return_date)
         INNER JOIN common_lookup cl1
         ON      cl1.common_lookup_table = 'TRANSACTION'         
         AND     cl1.common_lookup_column = 'TRANSACTION_TYPE'         
         AND     cl1.common_lookup_type = tu.transaction_type
         INNER JOIN common_lookup cl2
         ON      cl2.common_lookup_table = 'TRANSACTION'         
         AND     cl2.common_lookup_column = 'PAYMENT_METHOD_TYPE'         
         AND     cl2.common_lookup_type = tu.payment_method_type
         LEFT JOIN transaction t
         ON      t.transaction_account = tu.payment_account_number
         AND     t.rental_id = r.rental_id
         AND     t.transaction_type = cl1.common_lookup_id
         AND     t.transaction_date = tu.transaction_date
         AND     t.payment_method_type = cl2.common_lookup_id
         AND     t.payment_account_number = m.credit_card_number
         GROUP BY t.transaction_id
         ,        tu.payment_account_number
         ,        cl1.common_lookup_id
         ,        tu.transaction_date
         ,        r.rental_id
         ,        cl2.common_lookup_id
         ,        m.credit_card_number
         ,        1001
         ,        TRUNC(SYSDATE)
         ,        1001
         ,        TRUNC(SYSDATE) ) source
ON (target.transaction_id = source.transaction_id)
WHEN MATCHED THEN
UPDATE SET target.last_updated_by = source.last_updated_by
,          target.last_update_date = source.last_update_date
WHEN NOT MATCHED THEN
INSERT VALUES
( transaction_s1.nextval
, source.transaction_account
, source.transaction_type
, source.transaction_date
, source.transaction_amount
, source.rental_id
, source.payment_method_type
, source.payment_account_number
, source.created_by
, source.creation_date
, source.last_updated_by
, source.last_update_date);


-- Count transactions after insert
SELECT   COUNT(*) AS "Transaction after merge"
FROM     transaction;
-- --------------------------------------------------------
--  Step #4(a) : Put merge statements in a procedure.
-- --------------------------------------------------------

-- Create a procedure to wrap the transformation of import to normalized tables.
CREATE OR REPLACE PROCEDURE upload_transactions IS
BEGIN
  -- Set save point for an all or nothing transaction.
  SAVEPOINT starting_point;

  -- Insert or update the table, which makes this rerunnable when the file hasn't been updated.
  MERGE INTO rental target
    USING ( SELECT   DISTINCT
            r.rental_id
    ,        c.contact_id
    ,        tu.check_out_date AS check_out_date
    ,        tu.return_date AS return_date
    ,        1 AS created_by
    ,        TRUNC(SYSDATE) AS creation_date
    ,        1 AS last_updated_by
    ,        TRUNC(SYSDATE) AS last_update_date
    FROM     member m INNER JOIN contact c
    ON       m.member_id = c.member_id INNER JOIN transaction_upload tu
    ON       c.first_name = tu.first_name
    AND      NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
    AND      c.last_name = tu.last_name
    AND       tu.account_number = m.account_number
    LEFT JOIN rental r
    ON       c.contact_id = r.customer_id
    AND      TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
    AND      TRUNC(tu.return_date) = TRUNC(r.return_date)) source
    ON (target.rental_id = source.rental_id)
    WHEN MATCHED THEN
    UPDATE SET target.last_updated_by = source.last_updated_by
    ,          target.last_update_date = source.last_update_date
    WHEN NOT MATCHED THEN
    INSERT VALUES
    ( rental_s1.NEXTVAL
    , source.contact_id
    , source.check_out_date
    , source.return_date
    , source.created_by
    , source.creation_date
    , source.last_updated_by
    , source.last_update_date);

  -- Insert or update the table, which makes this rerunnable when the file hasn't been updated.
  MERGE INTO rental_item target
    USING ( SELECT   
            ri.rental_item_id
    ,        r.rental_id
    ,        tu.item_id
    ,        TRUNC(r.return_date) - TRUNC(r.check_out_date) AS rental_item_price
    ,        cl.common_lookup_id AS rental_item_type
    ,        1001 AS created_by
    ,        TRUNC(SYSDATE) AS creation_date
    ,        1001 AS last_updated_by
    ,        TRUNC(SYSDATE) AS last_update_date
    FROM     member m INNER JOIN contact c
            ON       m.member_id = c.member_id INNER JOIN transaction_upload tu
            ON       c.first_name = tu.first_name
            AND      NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
            AND      c.last_name = tu.last_name
            AND       tu.account_number = m.account_number
            LEFT JOIN rental r
            ON       c.contact_id = r.customer_id
            AND      TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
            AND      TRUNC(tu.return_date) = TRUNC(r.return_date)
            INNER JOIN common_lookup cl
            ON      cl.common_lookup_table = 'RENTAL_ITEM'         
            AND     cl.common_lookup_column = 'RENTAL_ITEM_TYPE'         
            AND     cl.common_lookup_type = tu.rental_item_type
            LEFT JOIN rental_item ri
            ON      r.rental_id = ri.rental_id) source
    ON (target.rental_item_id = source.rental_item_id)
    WHEN MATCHED THEN
    UPDATE SET target.last_updated_by = source.last_updated_by
    ,          target.last_update_date = source.last_update_date
    WHEN NOT MATCHED THEN
    INSERT VALUES
    (  rental_item_s1.nextval
    , source.rental_id
    , source.item_id
    , source.created_by
    , source.creation_date
    , source.last_updated_by
    , source.last_update_date
    , source.rental_item_type
    , source.rental_item_price);

  -- Insert or update the table, which makes this rerunnable when the file hasn't been updated.
  MERGE INTO transaction target
    USING ( SELECT    t.transaction_id
            ,        tu.payment_account_number AS transaction_account
            ,        cl1.common_lookup_id AS transaction_type
            ,        tu.transaction_date
            ,       (SUM(tu.transaction_amount) / 1.06) AS transaction_amount
            ,        r.rental_id
            ,        cl2.common_lookup_id AS payment_method_type
            ,        m.credit_card_number AS payment_account_number
            ,        1001 AS created_by
            ,        TRUNC(SYSDATE) AS creation_date
            ,        1001 AS last_updated_by
            ,        TRUNC(SYSDATE) AS last_update_date
            FROM     member m INNER JOIN contact c
            ON       m.member_id = c.member_id INNER JOIN transaction_upload tu
            ON       c.first_name = tu.first_name
            AND      NVL(c.middle_name,'x') = NVL(tu.middle_name,'x')
            AND      c.last_name = tu.last_name
            AND       tu.account_number = m.account_number
            LEFT JOIN rental r
            ON       c.contact_id = r.customer_id
            AND      TRUNC(tu.check_out_date) = TRUNC(r.check_out_date)
            AND      TRUNC(tu.return_date) = TRUNC(r.return_date)
            INNER JOIN common_lookup cl1
            ON      cl1.common_lookup_table = 'TRANSACTION'         
            AND     cl1.common_lookup_column = 'TRANSACTION_TYPE'         
            AND     cl1.common_lookup_type = tu.transaction_type
            INNER JOIN common_lookup cl2
            ON      cl2.common_lookup_table = 'TRANSACTION'         
            AND     cl2.common_lookup_column = 'PAYMENT_METHOD_TYPE'         
            AND     cl2.common_lookup_type = tu.payment_method_type
            LEFT JOIN transaction t
            ON      t.transaction_account = tu.payment_account_number
            AND     t.rental_id = r.rental_id
            AND     t.transaction_type = cl1.common_lookup_id
            AND     t.transaction_date = tu.transaction_date
            AND     t.payment_method_type = cl2.common_lookup_id
            AND     t.payment_account_number = m.credit_card_number
            GROUP BY t.transaction_id
            ,        tu.payment_account_number
            ,        cl1.common_lookup_id
            ,        tu.transaction_date
            ,        r.rental_id
            ,        cl2.common_lookup_id
            ,        m.credit_card_number
            ,        1001
            ,        TRUNC(SYSDATE)
            ,        1001
            ,        TRUNC(SYSDATE) ) source
    ON (target.transaction_id = source.transaction_id)
    WHEN MATCHED THEN
    UPDATE SET target.last_updated_by = source.last_updated_by
    ,          target.last_update_date = source.last_update_date
    WHEN NOT MATCHED THEN
    INSERT VALUES
    ( transaction_s1.nextval
    , source.transaction_account
    , source.transaction_type
    , source.transaction_date
    , source.transaction_amount
    , source.rental_id
    , source.payment_method_type
    , source.payment_account_number
    , source.created_by
    , source.creation_date
    , source.last_updated_by
    , source.last_update_date);

  -- Save the changes.
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO starting_point;
    RETURN;
END;
/

-- Show errors if any.
SHOW ERRORS

-- --------------------------------------------------------
--  Step #4(b) : Execute the procedure for the first time.
-- --------------------------------------------------------

EXECUTE upload_transactions;

-- --------------------------------------------------------
--  Step #4(c) : Verify first merge statements results.
-- --------------------------------------------------------

COLUMN rental_count      FORMAT 99,999 HEADING "Rental|Count"
COLUMN rental_item_count FORMAT 99,999 HEADING "Rental|Item|Count"
COLUMN transaction_count FORMAT 99,999 HEADING "Transaction|Count"
 
SELECT   il1.rental_count
,        il2.rental_item_count
,        il3.transaction_count
FROM    (SELECT COUNT(*) AS rental_count FROM rental) il1 CROSS JOIN
        (SELECT COUNT(*) AS rental_item_count FROM rental_item) il2 CROSS JOIN
        (SELECT COUNT(*) AS transaction_count FROM TRANSACTION) il3;

-- --------------------------------------------------------
--  Step #4(d) : Execute the procedure for the second time.
-- --------------------------------------------------------

EXECUTE upload_transactions;

-- --------------------------------------------------------
--  Step #4(e) : Verify second merge statements results.
-- --------------------------------------------------------

COLUMN rental_count      FORMAT 99,999 HEADING "Rental|Count"
COLUMN rental_item_count FORMAT 99,999 HEADING "Rental|Item|Count"
COLUMN transaction_count FORMAT 99,999 HEADING "Transaction|Count"
 
SELECT   il1.rental_count
,        il2.rental_item_count
,        il3.transaction_count
FROM    (SELECT COUNT(*) AS rental_count FROM rental) il1 CROSS JOIN
        (SELECT COUNT(*) AS rental_item_count FROM rental_item) il2 CROSS JOIN
        (SELECT COUNT(*) AS transaction_count FROM TRANSACTION) il3;

-- --------------------------------------------------------
--  Step #5 : Demonstrate aggregation with sorting options.
-- --------------------------------------------------------
SET LINESIZE 200

SELECT
  il.month AS "Month Year"
, il.base AS "Base Revenue"
, il.plus10 AS "10 Plus Revenue"
, il.plus20 AS "20 Plus Revenue"
, il.only10 AS "10 Plus Difference"
, il.only20 AS "20 Plus Difference"
FROM
    (SELECT
        CONCAT(TO_CHAR(t.transaction_date, 'MON'), CONCAT('-', EXTRACT(YEAR FROM t.transaction_date))) AS MONTH
    ,   EXTRACT(MONTH FROM t.transaction_date) AS sortkey
    ,   TO_CHAR(SUM(t.transaction_amount), '$9,999,999.00') AS base
    ,   TO_CHAR(SUM(t.transaction_amount) * 1.1, '$9,999,999.00') AS plus10
    ,   TO_CHAR(SUM(t.transaction_amount) * 1.2, '$9,999,999.00') AS plus20
    ,   TO_CHAR(SUM(t.transaction_amount) * 0.1, '$9,999,999.00') AS only10
    ,   TO_CHAR(SUM(t.transaction_amount) * 0.2, '$9,999,999.00') AS only20
    FROM transaction t
    WHERE EXTRACT(YEAR FROM t.transaction_date) = 2009
    GROUP BY CONCAT(TO_CHAR(t.transaction_date, 'MON'), CONCAT('-', EXTRACT(YEAR FROM t.transaction_date)))
    ,   EXTRACT(MONTH FROM t.transaction_date)) il
ORDER BY il.sortkey;


SPOOL OFF

-- Make all changes permanent.
COMMIT;
