-- Test3 v4: один индекс на InfoYSR вместо четырёх (все BalAccount раскрыты до 4 знаков).
-- На Account индексы создать нельзя (ограничение базы).

-- Удалить старые индексы (если были созданы):
-- DROP INDEX PBI.IX_INFOYSR_DTBAL_BALP4_KEY;
-- DROP INDEX PBI.IX_INFOYSR_DT_BP4;
-- DROP INDEX PBI.IX_INFOYSR_DT_BP3;
-- DROP INDEX PBI.IX_INFOYSR_DT_BP2;
-- DROP INDEX PBI.IX_INFOYSR_DT_BP1;

-- InfoYSR: (DtBalance, BalPrefix4, AccountKey) для MATCHCOLS=2 + index-only access.
-- Если AccountKey слишком раздувает индекс — убрать его.
CREATE INDEX PBI.IX_INFOYSR_DT_BP4
    ON PBI."InfoYSR" ("DtBalance" ASC, "BalPrefix4" ASC, "AccountKey" ASC);
