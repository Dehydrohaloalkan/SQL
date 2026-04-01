-- Test3: опциональные индексы для Account и AccountStatus.
-- Цель: убрать tablespace scan AccountStatus (156M строк) из QBLOCKNO=3.
-- Сейчас это ~6-7 минут из 8 общих.

-- =====================================================================
-- 1. Account: позволяет фильтровать по NrBank + BalPrefix4 через индекс.
--    MATCHCOLS=2 при probe по (NrBank, BalPrefix4).
--    IDNAccount — для join с AccountStatus без обращения к data page.
--    AccountKey — покрывает SELECT (index-only access для AA CTE).
--    Если AccountKey раздувает индекс — можно убрать (будет data page access).
-- =====================================================================
CREATE INDEX PBI.IX_ACCOUNT_NB_BP4_COVER
    ON PBI."Account" (
        "NrBank"      ASC,
        "BalPrefix4"  ASC,
        "IDNAccount"  ASC,
        "AccountKey"  ASC
    );

-- Облегчённый вариант без AccountKey (~3 GB вместо ~15 GB):
-- CREATE INDEX PBI.IX_ACCOUNT_NB_BP4
--     ON PBI."Account" ("NrBank" ASC, "BalPrefix4" ASC, "IDNAccount" ASC);


-- =====================================================================
-- 2. AccountStatus: covering index для probe по IDNAccount.
--    Когда Account фильтруется первым (через индекс выше),
--    оптимизатор перевернёт join: Account → probe AccountStatus.
--    Все нужные колонки в индексе = index-only access для AC/AAC CTE.
-- =====================================================================
CREATE INDEX PBI.IX_ACST_IDNACC_COVER
    ON PBI."AccountStatus" (
        "IDNAccount"      ASC,
        "AccountStatus"   ASC,
        "StatusOwner"     ASC,
        "DtAccountOpen"   ASC,
        "DtAccountChange" ASC
    );
