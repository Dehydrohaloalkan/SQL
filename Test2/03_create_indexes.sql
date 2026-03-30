-- DB2 for z/OS: новые индексы под фильтры запроса (имена/параметры TS — согласовать с DBA)
-- Вариант без generated columns: индексы по выражениям SUBSTR(...)

-- Account (CTE AA)
-- Для Db2 for z/OS проще и совместимее сделать индексы по выражению SUBSTR(...),
-- тогда исходный script.sql (с SUBSTR в предикатах) сможет использовать индекс.
CREATE INDEX PBI.IX_ACCOUNT_NBR_SUB4
    ON PBI."Account" ("NrBank" ASC, SUBSTR("NrAccount", 9, 4) ASC);

-- Опционально (если EXPLAIN показывает частое использование веток 1..3):
-- CREATE INDEX PBI.IX_ACCOUNT_NBR_SUB3
--     ON PBI."Account" ("NrBank" ASC, SUBSTR("NrAccount", 9, 3) ASC);
-- CREATE INDEX PBI.IX_ACCOUNT_NBR_SUB2
--     ON PBI."Account" ("NrBank" ASC, SUBSTR("NrAccount", 9, 2) ASC);
-- CREATE INDEX PBI.IX_ACCOUNT_NBR_SUB1
--     ON PBI."Account" ("NrBank" ASC, SUBSTR("NrAccount", 9, 1) ASC);

-- InfoYSR (CTE SRA)
-- Ведущий фильтр — DtBalance (обычно одна дата) + выражение SUBSTR по префиксу.
CREATE INDEX PBI.IX_INFOYSR_DTBAL_SUB4
    ON PBI."InfoYSR" ("DtBalance" ASC, SUBSTR("NrAccount", 9, 4) ASC);

-- Опционально (если EXPLAIN показывает частое использование веток 1..3):
-- CREATE INDEX PBI.IX_INFOYSR_DTBAL_SUB3
--     ON PBI."InfoYSR" ("DtBalance" ASC, SUBSTR("NrAccount", 9, 3) ASC);
-- CREATE INDEX PBI.IX_INFOYSR_DTBAL_SUB2
--     ON PBI."InfoYSR" ("DtBalance" ASC, SUBSTR("NrAccount", 9, 2) ASC);
-- CREATE INDEX PBI.IX_INFOYSR_DTBAL_SUB1
--     ON PBI."InfoYSR" ("DtBalance" ASC, SUBSTR("NrAccount", 9, 1) ASC);
