-- Test4: добавить материализованные колонки BalPrefix4 и AccountKey.
-- BalPrefix4 = SUBSTR(NrAccount, 9, 4) — для sargable фильтрации вместо SUBSTR.
-- AccountKey = предрасчётанная конкатенация ключа Account.

ALTER TABLE PBI."Account"
    ADD COLUMN "BalPrefix4" SMALLINT;
ALTER TABLE PBI."Account"
    ADD COLUMN "AccountKey" VARCHAR(80);

ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "BalPrefix4" SMALLINT;
ALTER TABLE PBI."InfoYSR"
    ADD COLUMN "AccountKey" VARCHAR(80);

-- TableYTIGos: материализованные ключи Payer и Benef
-- Формат: NrAccount || '|' || NrEWallet (или NrAccount || '|' если NrEWallet IS NULL)
ALTER TABLE PBI."TableYTIGos"
    ADD COLUMN "AccountKeyPayer" VARCHAR(70);
ALTER TABLE PBI."TableYTIGos"
    ADD COLUMN "AccountKeyBenef" VARCHAR(70);
