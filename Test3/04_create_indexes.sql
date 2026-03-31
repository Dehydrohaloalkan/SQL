-- Test3 v2: индексы для UNION-подхода.
-- На Account индексы создать нельзя (ограничение базы).
-- На InfoYSR: по индексу на каждый BalPrefix для MATCHCOLS=2 в каждой UNION-ветке.
-- AccountKey в индексе даёт index-only access (SELECT в SRA читает только AccountKey).
-- Если AccountKey слишком раздувает индекс — убрать его; тогда будет MATCHCOLS=2 + data page access.

-- Удалить старый комбинированный индекс (если создан)
-- DROP INDEX PBI.IX_INFOYSR_DTBAL_BALP4_KEY;

CREATE INDEX PBI.IX_INFOYSR_DT_BP4
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix4" ASC, "AccountKey" ASC);

CREATE INDEX PBI.IX_INFOYSR_DT_BP3
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix3" ASC, "AccountKey" ASC);

CREATE INDEX PBI.IX_INFOYSR_DT_BP2
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix2" ASC, "AccountKey" ASC);

CREATE INDEX PBI.IX_INFOYSR_DT_BP1
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix1" ASC, "AccountKey" ASC);
