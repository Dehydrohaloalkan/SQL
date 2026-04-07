CREATE INDEX PBI.IX_ACCOUNT_NB_BP4_COVER ON PBI."Account" (
    "NrBank" ASC,
    "BalPrefix4" ASC,
    "IDNAccount" ASC
) using stogroup SGPBI priqty 4800 secqty 4800 DEFER YES ~