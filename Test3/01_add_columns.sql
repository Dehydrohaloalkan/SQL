-- Test3 (Db2 for z/OS): добавляем обычные (не generated) колонки под префиксы и ключ отчёта.
-- Делать nullable, чтобы упростить backfill и не упираться в ограничения во время заполнения.

ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix1" CHAR(1);
ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix2" CHAR(2);
ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix3" CHAR(3);
ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix4" CHAR(4);
ALTER TABLE PBI."Account"
    ADD COLUMN "AccountKey" VARCHAR(80);

ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix1" CHAR(1);
ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix2" CHAR(2);
ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix3" CHAR(3);
ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix4" CHAR(4);
ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "AccountKey" VARCHAR(80);

