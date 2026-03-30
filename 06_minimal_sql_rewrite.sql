-- DB2 for z/OS: минимальные переписывания SQL (без DDL)
-- Цель: дать оптимизатору более “прямую” форму (anti-join вместо EXCEPT, EXISTS вместо IN).
-- ВАЖНО: применять только после EXPLAIN текущего плана, чтобы не ухудшить.

--------------------------------------------------------------------------------
-- 1) Замена EXCEPT на anti-join
--------------------------------------------------------------------------------
-- Было (логика):
--   AACS = DISTINCT(Account) из AAC
--          EXCEPT DISTINCT(Account) из SRA
-- Часто быстрее:
--   AACS = DISTINCT(Account) из AAC
--          LEFT JOIN DISTINCT(Account) из SRA
--          WHERE SRA.Account IS NULL

-- Пример каркаса (нужно подставить ваши CTE AAC/SRA как есть):
--
-- WITH ...,
-- AAC AS (...),
-- SRA AS (...),
-- AACS AS (
--   SELECT DISTINCT A.Account
--   FROM AAC A
--   LEFT JOIN (SELECT DISTINCT Account FROM SRA) S
--     ON S.Account = A.Account
--   WHERE S.Account IS NULL
-- ),
-- Q1 AS (
--   SELECT DISTINCT NrBank, DtBalance, Account
--   FROM AAC
--   WHERE Account IN (SELECT Account FROM AACS)
-- )
-- SELECT ...

--------------------------------------------------------------------------------
-- 2) Замена IN (subquery) на EXISTS/JOIN
--------------------------------------------------------------------------------
-- В Q1:
--   WHERE Account IN (SELECT Account FROM AACS)
-- часто лучше:
--   WHERE EXISTS (SELECT 1 FROM AACS X WHERE X.Account = AAC.Account)

-- Пример:
-- Q1 AS (
--   SELECT DISTINCT A.NrBank, A.DtBalance, A.Account
--   FROM AAC A
--   WHERE EXISTS (SELECT 1 FROM AACS X WHERE X.Account = A.Account)
-- )

--------------------------------------------------------------------------------
-- 3) Подсказка Db2: материализовать CTE (если ваш Db2 поддерживает)
--------------------------------------------------------------------------------
-- В Db2 есть возможность влиять на переписывание/материализацию CTE (зависит от версии/настроек).
-- Это уже “тонкая настройка”, лучше смотреть конкретный EXPLAIN.

