-- DB2 for z/OS: новые индексы под фильтры запроса (имена/параметры TS — согласовать с DBA)
-- Выполнять после 01 и 02, когда столбцы BalPrefix* уже есть

-- Account (CTE AA)
-- 1) Ведущая селективность: NrBank + префиксы бал.счёта.
-- 2) Дальше в запросе делается EXCEPT/DISTINCT по ключу "Account" — поэтому имеет смысл,
--    чтобы AccountKey был частью ключа индекса (для упорядоченности без SORT, когда это возможно).
-- Примечание: из-за OR по BalPrefix1..4 один индекс не “покроет” все ветки идеально.
-- Минимально полезный индекс — по BalPrefix4 (самый конкретный предикат); остальные — опционально по EXPLAIN.
CREATE INDEX PBI.IX_ACCOUNT_GEN_NBR_BALP4_KEY
    ON PBI."Account" ("NrBank" ASC, "BalPrefix4" ASC, "AccountKey" ASC, "IDNAccount" ASC);

-- Опционально (добавлять только если план часто использует ветки 1..3 и не “дотягивается” до BalPrefix4):
-- CREATE INDEX PBI.IX_ACCOUNT_GEN_NBR_BALP3_KEY
--     ON PBI."Account" ("NrBank" ASC, "BalPrefix3" ASC, "AccountKey" ASC, "IDNAccount" ASC);
-- CREATE INDEX PBI.IX_ACCOUNT_GEN_NBR_BALP2_KEY
--     ON PBI."Account" ("NrBank" ASC, "BalPrefix2" ASC, "AccountKey" ASC, "IDNAccount" ASC);
-- CREATE INDEX PBI.IX_ACCOUNT_GEN_NBR_BALP1_KEY
--     ON PBI."Account" ("NrBank" ASC, "BalPrefix1" ASC, "AccountKey" ASC, "IDNAccount" ASC);

-- InfoYSR (CTE SRA)
-- Ведущий фильтр — DtBalance (обычно 1 дата). Дальше: тот же набор префиксов.
-- Для EXCEPT/DISTINCT по "Account" ключевое — быстро получить AccountKey на выбранной дате.
CREATE INDEX PBI.IX_INFOYSR_GEN_DTBAL_BALP4_KEY
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix4" ASC, "AccountKey" ASC);

-- Вариант, если оптимизатор выбирает “сначала дата → сразу ключ” (без привязки к префиксу):
-- CREATE INDEX PBI.IX_INFOYSR_GEN_DTBAL_ACCOUNTKEY
--     ON PBI."InfoYSR" ("DtBalance" ASC, "AccountKey" ASC);

-- Опционально (если EXPLAIN показывает, что часто выигрывают ветки 1..3):
-- CREATE INDEX PBI.IX_INFOYSR_GEN_DTBAL_BALP3_KEY
--     ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix3" ASC, "AccountKey" ASC);
-- CREATE INDEX PBI.IX_INFOYSR_GEN_DTBAL_BALP2_KEY
--     ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix2" ASC, "AccountKey" ASC);
-- CREATE INDEX PBI.IX_INFOYSR_GEN_DTBAL_BALP1_KEY
--     ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix1" ASC, "AccountKey" ASC);

-- “Чистые” индексы только по AccountKey обычно не нужны, если есть составные выше.
