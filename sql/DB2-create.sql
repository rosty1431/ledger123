CONNECT RESET@
ATTACH TO db2inst1@
CREATE DATABASE LEDGER USING CODESET UTF-8 TERRITORY US DFT_EXTENT_SZ 16@
CONNECT TO LEDGER@
CREATE BUFFERPOOL LEDGERBP_8K IMMEDIATE SIZE 1000 PAGESIZE 8192@
CREATE TABLESPACE LEDGER_TS PAGESIZE 8K MANAGED BY SYSTEM USING ('LEDGER_TS') PREFETCHSIZE 8 BUFFERPOOL LEDGERBP_8K@
CREATE TEMPORARY TABLESPACE LEDGER_TMP_8K PAGESIZE 8K MANAGED BY SYSTEM USING ('LEDGER_TMP_8K') BUFFERPOOL LEDGERBP_8K@
CONNECT RESET@
