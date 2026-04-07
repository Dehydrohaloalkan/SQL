-- Test4: все индексы. Выполнять после 01-06, затем RUNSTATS.

-- Account: MATCHCOLS=2 (NrBank, BalPrefix4), covering (IDNAccount для JOIN)
CREATE INDEX PBI.IX_ACCOUNT_NB_BP4_COVER ON PBI."Account" (
    "NrBank" ASC,
    "BalPrefix4" ASC,
    "IDNAccount" ASC
) USING STOGROUP SGPBI PRIQTY 4800 SECQTY 4800 DEFER YES;

-- AccountStatus: probe по IDNAccount + screening по AccountStatus, DtAccountOpen, DtAccountChange.
-- StatusOwner убран — используется только в script A для редкого условия BalPrefix4='3119',
-- data page access для этого случая дешёвый.
CREATE INDEX PBI.IX_ACST_IDNACC ON PBI."AccountStatus" (
    "IDNAccount" ASC,
    "AccountStatus" ASC,
    "DtAccountOpen" ASC,
    "DtAccountChange" ASC
) USING STOGROUP SGPBI PRIQTY 4800 SECQTY 4800 DEFER YES;

-- InfoYSR: для SRA CTE — DtBalance + BalPrefix4 фильтрация
CREATE INDEX PBI.IX_INFOYSR_DT_BP4 ON PBI."InfoYSR" (
    "DtBalance" ASC,
    "BalPrefix4" ASC,
    "AccountKey" ASC
) USING STOGROUP SGPBI PRIQTY 4800 SECQTY 4800 DEFER YES;

-- TableYTIGos: фильтрация по NrBankMQ (используется в script B, PACC CTE)
CREATE INDEX PBI.IX_YTIGOG_NRBANK ON PBI."TableYTIGos" (
    "NrBankMQ" ASC
) USING STOGROUP SGPBI PRIQTY 480 SECQTY 480 DEFER YES;
