-- Test3: индексы по материализованным колонкам (BalPrefix*, AccountKey)
-- Имена/параметры TS — согласовать с DBA.

-- Account (CTE AA): ведущая селективность NrBank + префикс; дальше удобен AccountKey
CREATE INDEX PBI.IX_ACCOUNT_NBR_BALP4_KEY
    ON PBI."Account" ("NrBank" ASC, "BalPrefix4" ASC, "AccountKey" ASC);

-- InfoYSR (CTE SRA): ведущая DtBalance + префикс; дальше AccountKey
CREATE INDEX PBI.IX_INFOYSR_DTBAL_BALP4_KEY
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix4" ASC, "AccountKey" ASC);

-- Опционально, если EXPLAIN показывает частое использование веток 1..3:
-- CREATE INDEX PBI.IX_ACCOUNT_NBR_BALP3_KEY ON PBI."Account" ("NrBank", "BalPrefix3", "AccountKey");
-- CREATE INDEX PBI.IX_ACCOUNT_NBR_BALP2_KEY ON PBI."Account" ("NrBank", "BalPrefix2", "AccountKey");
-- CREATE INDEX PBI.IX_ACCOUNT_NBR_BALP1_KEY ON PBI."Account" ("NrBank", "BalPrefix1", "AccountKey");
-- CREATE INDEX PBI.IX_INFOYSR_DTBAL_BALP3_KEY ON PBI."InfoYSR" ("DtBalance", "BalPrefix3", "AccountKey");
-- CREATE INDEX PBI.IX_INFOYSR_DTBAL_BALP2_KEY ON PBI."InfoYSR" ("DtBalance", "BalPrefix2", "AccountKey");
-- CREATE INDEX PBI.IX_INFOYSR_DTBAL_BALP1_KEY ON PBI."InfoYSR" ("DtBalance", "BalPrefix1", "AccountKey");

