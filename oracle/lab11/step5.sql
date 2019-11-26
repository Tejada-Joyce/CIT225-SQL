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
