-- DB2 for z/OS: generated columns для префиксов + индексы
-- Цель: заменить SUBSTR(NrAccount,9,...) на индексируемые колонки.
-- ВАЖНО: этот вариант требует изменения таблиц (DDL). Согласуй с DBA.

--------------------------------------------------------------------------------
-- A) Добавляем generated columns в Account
--------------------------------------------------------------------------------
-- Префикс берётся с позиции 9, длиной 1..4.
-- Синтаксис GENERATED ALWAYS AS (...) зависит от режима (ROW CHANGE TIMESTAMP и т.п.).

-- ALTER TABLE PBI."Account"
--   ADD COLUMN "BalPrefix1" CHAR(1)
--     GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 1));
-- ALTER TABLE PBI."Account"
--   ADD COLUMN "BalPrefix2" CHAR(2)
--     GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 2));
-- ALTER TABLE PBI."Account"
--   ADD COLUMN "BalPrefix3" CHAR(3)
--     GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 3));
-- ALTER TABLE PBI."Account"
--   ADD COLUMN "BalPrefix4" CHAR(4)
--     GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 4));

-- Индексируем самый используемый вариант (обычно 4 символа), + NrBank как сильный фильтр
-- CREATE INDEX PBI.X_ACCOUNT_BANK_BALP4
--   ON PBI."Account" ("NrBank" ASC, "BalPrefix4" ASC);

--------------------------------------------------------------------------------
-- B) Добавляем generated columns в InfoYSR (если боль — SRA по DtBalance)
--------------------------------------------------------------------------------
-- ALTER TABLE PBI."InfoYSR"
--   ADD COLUMN "BalPrefix4" CHAR(4)
--     GENERATED ALWAYS AS (SUBSTR("NrAccount", 9, 4));

-- Индекс по дате + префиксу (вариант, если много балансовых счетов и префиксы сильно режут данные)
-- CREATE INDEX PBI.X_INFOYSR_DTBAL_BALP4
--   ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix4" ASC);

--------------------------------------------------------------------------------
-- C) Минимальная правка скрипта (идея, не применяю автоматически)
--------------------------------------------------------------------------------
-- Было:
--   SUBSTR("NrAccount", 9, 4) IN (SELECT BalAccount ... WHERE count_BalAccount='4')
-- Стало:
--   "BalPrefix4" IN (SELECT BalAccount ... WHERE count_BalAccount='4')

