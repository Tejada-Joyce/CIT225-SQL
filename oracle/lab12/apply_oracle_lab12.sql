-- ------------------------------------------------------------------
--  Program Name:   apply_oracle_lab12.sql
--  Lab Assignment: Lab #12
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
--   sql> @apply_oracle_lab12.sql
--
-- ------------------------------------------------------------------

-- Run the prior lab script.
@/home/student/Data/cit225/oracle/lab11/apply_oracle_lab11.sql

-- Spool log file.
SPOOL apply_oracle_lab12.txt

-- --------------------------------------------------------------------------------
--  Step #1 : Create CALENDAR table.
-- --------------------------------------------------------------------------------
-- Conditionally drop table.
BEGIN
  FOR i IN (SELECT table_name
            FROM   user_tables
            WHERE  table_name = 'CALENDAR') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||i.table_name||' CASCADE CONSTRAINTS';
  END LOOP;
  FOR i IN (SELECT sequence_name
            FROM   user_sequences
            WHERE  sequence_name = 'CALENDAR_S1') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE '||i.sequence_name;
  END LOOP;
END;
/

-- --------------------------------------------------------------------------------
--  Step #1 : Create the CALENDAR table.
-- --------------------------------------------------------------------------------

CREATE TABLE calendar
( calendar_id                  NUMBER(22)
, calendar_name                VARCHAR2(10)     CONSTRAINT nn_calendar_1 NOT NULL
, calendar_short_name          VARCHAR2(3)      CONSTRAINT nn_calendar_2 NOT NULL
, start_date                   DATE             CONSTRAINT nn_calendar_3 NOT NULL
, end_date                     DATE             CONSTRAINT nn_calendar_4 NOT NULL
, created_by                   NUMBER(22)       CONSTRAINT nn_calendar_5 NOT NULL
, creation_date                DATE             CONSTRAINT nn_calendar_6 NOT NULL
, last_updated_by              NUMBER(22)       CONSTRAINT nn_calendar_7 NOT NULL
, last_update_date             DATE             CONSTRAINT nn_calendar_8 NOT NULL
, CONSTRAINT pk_calendar_1     PRIMARY KEY(calendar_id)
, CONSTRAINT fk_calendar_1     FOREIGN KEY(created_by) REFERENCES system_user(system_user_id)
, CONSTRAINT fk_calendar_2     FOREIGN KEY(last_updated_by) REFERENCES system_user(system_user_id));


-- --------------------------------------------------------------------------------
--  Step #1 : Create the CALENDAR sequence.
-- --------------------------------------------------------------------------------


CREATE SEQUENCE calendar_s1 START WITH 1;


-- Display the table organization.
SET NULL ''
COLUMN table_name   FORMAT A16
COLUMN column_id    FORMAT 9999
COLUMN column_name  FORMAT A22
COLUMN data_type    FORMAT A12
SELECT   table_name
,        column_id
,        column_name
,        CASE
           WHEN nullable = 'N' THEN 'NOT NULL'
           ELSE ''
         END AS nullable
,        CASE
           WHEN data_type IN ('CHAR','VARCHAR2','NUMBER') THEN
             data_type||'('||data_length||')'
           ELSE
             data_type
         END AS data_type
FROM     user_tab_columns
WHERE    table_name = 'CALENDAR'
ORDER BY 2;

-- Display non-unique constraints.
COLUMN constraint_name   FORMAT A22  HEADING "Constraint Name"
COLUMN search_condition  FORMAT A36  HEADING "Search Condition"
COLUMN constraint_type   FORMAT A1   HEADING "C|T"
SELECT   uc.constraint_name
,        uc.search_condition
,        uc.constraint_type
FROM     user_constraints uc INNER JOIN user_cons_columns ucc
ON       uc.table_name = ucc.table_name
AND      uc.constraint_name = ucc.constraint_name
WHERE    uc.table_name = UPPER('calendar')
AND      uc.constraint_type IN (UPPER('c'),UPPER('p'))
ORDER BY uc.constraint_type DESC
,        uc.constraint_name;

-- Display foreign key constraints.
COL constraint_source FORMAT A38 HEADING "Constraint Name:| Table.Column"
COL references_column FORMAT A40 HEADING "References:| Table.Column"
SELECT   uc.constraint_name||CHR(10)
||      '('||ucc1.table_name||'.'||ucc1.column_name||')' constraint_source
,       'REFERENCES'||CHR(10)
||      '('||ucc2.table_name||'.'||ucc2.column_name||')' references_column
FROM     user_constraints uc
,        user_cons_columns ucc1
,        user_cons_columns ucc2
WHERE    uc.constraint_name = ucc1.constraint_name
AND      uc.r_constraint_name = ucc2.constraint_name
AND      ucc1.position = ucc2.position -- Correction for multiple column primary keys.
AND      uc.constraint_type = 'R'
AND      ucc1.table_name = 'CALENDAR'
ORDER BY ucc1.table_name
,        uc.constraint_name;

-- --------------------------------------------------------------------------------
--  Step #2 : Seed CALENDAR table.
-- --------------------------------------------------------------------------------

-- Seed the table with 10 years of data.
DECLARE
  -- Create local collection data types.
  TYPE smonth IS TABLE OF VARCHAR2(3);
  TYPE lmonth IS TABLE OF VARCHAR2(9);

  -- Declare month arrays.
  short_month SMONTH := smonth('JAN','FEB','MAR','APR','MAY','JUN'
                              ,'JUL','AUG','SEP','OCT','NOV','DEC');
  long_month  LMONTH := lmonth('January','February','March','April','May','June'
                              ,'July','August','September','October','November','December');

  -- Declare base dates.
  start_date DATE := '01-JAN-09';
  end_date   DATE := '31-JAN-09';

  -- Declare years.
  month_id   NUMBER;
  years      NUMBER := 1;

BEGIN

  -- Loop through years and months.
  FOR i IN 1..years LOOP
    FOR j IN 1..short_month.COUNT LOOP
      -- Assign number from sequence.
      SELECT calendar_s1.nextval INTO month_id FROM dual;

      INSERT INTO calendar VALUES
      ( month_id
      , long_month(j)
      , short_month(j)
      , add_months(start_date,(j-1)+(12*(i-1)))
      , add_months(end_date,(j-1)+(12*(i-1)))
      , 1
      , SYSDATE
      , 1
      , SYSDATE);

    END LOOP;
  END LOOP;

END;
/

-- Set output page break interval.
SET PAGESIZE 49999

-- Query the data insert.
COL calendar_name        FORMAT A10  HEADING "Calendar|Name"
COL calendar_short_name  FORMAT A8  HEADING "Calendar|Short|Name"
COL start_date           FORMAT A9   HEADING "Start|Date"
COL end_date             FORMAT A9   HEADING "End|Date"
SELECT   calendar_name
,        calendar_short_name
,        start_date
,        end_date
FROM     calendar;

-- --------------------------------------------------------------------------------
--  Step #3 : Upload and transform data.
-- --------------------------------------------------------------------------------

-- Conditionally drop table.
SELECT 'Conditionally drop TRANSACTION_REVERSAL table.' AS "Statement" FROM dual;
BEGIN
  FOR i IN (SELECT table_name
            FROM   user_tables
            WHERE  table_name = 'TRANSACTION_REVERSAL') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||i.table_name||' CASCADE CONSTRAINTS';
  END LOOP;
END;
/

-- --------------------------------------------------------------------------------
--  Step #3 : Upload and transform data.
-- --------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------
--  Step #3 : Create the TRANSACTION_REVERSAL table.
-- --------------------------------------------------------------------------------
CREATE TABLE transaction_reversal
( transaction_id            NUMBER(22)
,   transaction_account     VARCHAR2(15)
,   transaction_type        NUMBER(22)
,   transaction_date        DATE
,   transaction_amount      NUMBER(22)
,   rental_id               NUMBER(22)
,   payment_method_type     NUMBER(22)
,   payment_account_number  VARCHAR2(19)
,   created_by              NUMBER(22)
,   creation_date           DATE
,   last_updated_by         NUMBER(22)
,   last_update_date        DATE)
  ORGANIZATION EXTERNAL
  ( TYPE oracle_loader
    DEFAULT DIRECTORY upload
    ACCESS PARAMETERS
    ( RECORDS DELIMITED BY NEWLINE CHARACTERSET US7ASCII
      BADFILE       'UPLOAD' : 'transaction_upload2.bad'
      DISCARDFILE   'UPLOAD' : 'transaction_upload2.dis'
      LOGFILE       'UPLOAD' : 'transaction_upload2.log'
      FIELDS TERMINATED BY ','
      OPTIONALLY ENCLOSED BY "'"
      MISSING FIELD VALUES ARE NULL )
      LOCATION ('transaction_upload2.csv'))
REJECT LIMIT UNLIMITED;


-- Set environment variables.
SET LONG 200000
 
-- Set a local variable of a character large object (CLOB).
VARIABLE ddl_text CLOB
 
-- Get the internal DDL command for the external TRANSACTION_REVERSAL table from the data dictionary.
SELECT dbms_metadata.get_ddl('TABLE','TRANSACTION_REVERSAL') FROM dual;



-- Select the uploaded records.
SELECT COUNT(*) FROM transaction_reversal;

-- Select the uploaded records.
-- DELETE FROM transaction WHERE transaction_account = '222-222-222-222';

-- --------------------------------------------------------------------------------
--  Step #3(b) : Insert records into the TRANSACTION_REVERSAL table.
-- --------------------------------------------------------------------------------

-- Move the data from TRANSACTION_REVERSAL to TRANSACTION.
INSERT INTO transaction
(SELECT transaction_s1.nextval
,   transaction_account
,   transaction_type
,   transaction_date
,   transaction_amount
,   rental_id
,   payment_method_type
,   payment_account_number
,   created_by
,   creation_date
,   last_updated_by
,   last_update_date
 FROM    transaction_reversal);


-- --------------------------------------------------------------------------------
--  Step #3(c) : Verify insert of records into the TRANSACTION_REVERSAL table.
-- --------------------------------------------------------------------------------
COLUMN "Debit Transactions"  FORMAT A20
COLUMN "Credit Transactions" FORMAT A20
COLUMN "All Transactions"    FORMAT A20
 
-- Check current contents of the model.
SELECT 'SELECT record counts' AS "Statement" FROM dual;
SELECT   LPAD(TO_CHAR(c1.transaction_count,'99,999'),19,' ') AS "Debit Transactions"
,        LPAD(TO_CHAR(c2.transaction_count,'99,999'),19,' ') AS "Credit Transactions"
,        LPAD(TO_CHAR(c3.transaction_count,'99,999'),19,' ') AS "All Transactions"
FROM    (SELECT COUNT(*) AS transaction_count FROM transaction WHERE transaction_account = '111-111-111-111') c1 CROSS JOIN
        (SELECT COUNT(*) AS transaction_count FROM transaction WHERE transaction_account = '222-222-222-222') c2 CROSS JOIN
        (SELECT COUNT(*) AS transaction_count FROM transaction) c3;


-- --------------------------------------------------------------------------------
--  Step #4 : Query data.
-- --------------------------------------------------------------------------------
-- SQL*Plus formatting instructions.
-- COLUMN Transaction FORMAT A15
-- COLUMN January   FORMAT A10
-- COLUMN February  FORMAT A10
-- COLUMN March     FORMAT A10
-- COLUMN F1Q       FORMAT A10
-- COLUMN April     FORMAT A10
-- COLUMN May       FORMAT A10
-- COLUMN June      FORMAT A10
-- COLUMN F2Q       FORMAT A10
-- COLUMN July      FORMAT A10
-- COLUMN August    FORMAT A10
-- COLUMN September FORMAT A10
-- COLUMN F3Q       FORMAT A10
-- COLUMN October   FORMAT A10
-- COLUMN November  FORMAT A10
-- COLUMN December  FORMAT A10
-- COLUMN F4Q       FORMAT A10
-- COLUMN YTD       FORMAT A12
-- 
-- SET LINESIZE 210

-- Reassign column values.
-- SELECT   transaction_account AS "Transaction"
-- ,        january AS "Jan"
-- ,        february AS "Feb"
-- ,        march AS "Mar"
-- ,        f1q AS "F1Q"
-- ,        april AS "Apr"
-- ,        may AS "May"
-- ,        june AS "Jun"
-- ,        f2q AS "F2Q"
-- ,        july AS "Jul"
-- ,        august AS "Aug"
-- ,        september AS "Sep"
-- ,        f3q AS "F3Q"
-- ,        october AS "Oct"
-- ,        november AS "Nov"
-- ,        december AS "Dec"
-- ,        f4q AS "F4Q"
-- ,        ytd AS "YTD"
-- FROM (
-- SELECT   CASE
--            WHEN t.transaction_account = '111-111-111-111' THEN 'Debit'
--            WHEN t.transaction_account = '222-222-222-222' THEN 'Credit'
--          END AS "TRANSACTION_ACCOUNT"
-- ,        CASE
--            WHEN t.transaction_account = '111-111-111-111' THEN 1
--            WHEN t.transaction_account = '222-222-222-222' THEN 2
--          END AS "SORTKEY"
-- ,        LPAD(TO_CHAR
--         (SUM(CASE
--                WHEN EXTRACT(MONTH FROM transaction_date) = 1 AND
--                     EXTRACT(YEAR FROM transaction_date) = 2009 THEN
--                  CASE
--                    WHEN cl.common_lookup_type = 'DEBIT'
--                    THEN t.transaction_amount
--                    ELSE t.transaction_amount * -1
--                  END
--              END),'99,999.00'),10,' ') AS "JANUARY"
-- ...
-- ,        LPAD(TO_CHAR
--         (SUM(CASE
--                WHEN EXTRACT(YEAR FROM transaction_date) = 2009 THEN
--                  CASE
--                    WHEN cl.common_lookup_type = 'DEBIT'
--                    THEN t.transaction_amount
--                    ELSE t.transaction_amount * -1
--                  END
--              END),'99,999.00'),10,' ') AS "YTD"
-- FROM     transaction t INNER JOIN common_lookup cl
-- ON       t.transaction_type = cl.common_lookup_id
-- WHERE    cl.common_lookup_table = 'TRANSACTION'
-- AND      cl.common_lookup_column = 'TRANSACTION_TYPE'
-- GROUP BY CASE
--            WHEN t.transaction_account = '111-111-111-111' THEN 'Debit'
--            WHEN t.transaction_account = '222-222-222-222' THEN 'Credit'
--          END
-- ,        CASE
--            WHEN t.transaction_account = '111-111-111-111' THEN 1
--            WHEN t.transaction_account = '222-222-222-222' THEN 2
--          END
-- UNION ALL
-- SELECT  'Total' AS "Account"
-- ,        3 AS "Sortkey"
-- ,        LPAD(TO_CHAR
--         (SUM(CASE
--                WHEN EXTRACT(MONTH FROM transaction_date) = 1 AND
--                     EXTRACT(YEAR FROM transaction_date) = 2009 THEN
--                  CASE
--                    WHEN cl.common_lookup_type = 'DEBIT'
--                    THEN t.transaction_amount
--                    ELSE t.transaction_amount * -1
--                  END
--              END),'99,999.00'),10,' ') AS "JANUARY"
-- ...
-- ,        LPAD(TO_CHAR
--         (SUM(CASE
--                WHEN EXTRACT(YEAR FROM transaction_date) = 2009 THEN
--                  CASE
--                    WHEN cl.common_lookup_type = 'DEBIT'
--                    THEN t.transaction_amount
--                    ELSE t.transaction_amount * -1
--                  END
--              END),'99,999.00'),10,' ') AS "YTD"
-- FROM     transaction t INNER JOIN common_lookup cl
-- ON       t.transaction_type = cl.common_lookup_id
-- WHERE    cl.common_lookup_table = 'TRANSACTION'
-- AND      cl.common_lookup_column = 'TRANSACTION_TYPE'
-- GROUP BY 'Total'
-- ORDER BY 2);

SPOOL OFF
