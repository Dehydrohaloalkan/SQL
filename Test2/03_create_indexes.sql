-- DB2 for z/OS: новые индексы под фильтры запроса (имена/параметры TS — согласовать с DBA)
-- Выполнять после 01 и 02, когда столбцы BalPrefix* уже есть

-- Account: сильный фильтр по списку NrBank + префикс (для CTE AA)
CREATE INDEX PBI.IX_ACCOUNT_GEN_NBR_BALP4
    ON PBI."Account" ("NrBank" ASC, "BalPrefix4" ASC);

-- InfoYSR: ведущий фильтр по дате остатка + префикс (для CTE SRA)
CREATE INDEX PBI.IX_INFOYSR_GEN_DTBAL_BALP4
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix4" ASC);

-- Дополнительно (если оптимизатор всё ещё сканирует по длине префикса 1..3):
-- CREATE INDEX PBI.IX_ACCOUNT_GEN_NBR_BALP3 ON PBI."Account" ("NrBank" ASC, "BalPrefix3" ASC);
-- CREATE INDEX PBI.IX_INFOYSR_GEN_DTBAL_BALP3 ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix3" ASC);
