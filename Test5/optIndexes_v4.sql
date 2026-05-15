CREATE INDEX PBI.IX_ACCSTATUS_JOIN_COVER ON PBI."AccountStatus" (
    "IDNAccount" ASC,
    "AccountStatus" ASC,
    "DtAccountOpen" ASC,
    "DtAccountChange" ASC
) using stogroup SGPBI priqty 7200 secqty 7200 DEFER YES ~

CREATE INDEX PBI.IX_ACCSTATUS_OWNER_COVER ON PBI."AccountStatus" (
    "IDNAccount" ASC,
    "AccountStatus" ASC,
    "StatusOwner" ASC,
    "DtAccountOpen" ASC,
    "DtAccountChange" ASC
) using stogroup SGPBI priqty 9000 secqty 9000 DEFER YES ~

CREATE INDEX PBI.IX_ACCOUNT_NB_BA4 ON PBI."Account" (
    "NrBank" ASC,
    "BalAccount4" ASC,
    "IDNAccount" ASC
) using stogroup SGPBI priqty 6400 secqty 6400 DEFER YES ~

CREATE INDEX PBI.IX_ACCOUNT_BA2 ON PBI."Account" (
    "BalAccount2" ASC
) using stogroup SGPBI priqty 3840 secqty 3840 DEFER YES ~

CREATE INDEX PBI.IX_ACCOUNT_BA3 ON PBI."Account" (
    "BalAccount3" ASC
) using stogroup SGPBI priqty 3840 secqty 3840 DEFER YES ~

CREATE INDEX PBI.IX_ACCOUNT_BA4 ON PBI."Account" (
    "BalAccount4" ASC
) using stogroup SGPBI priqty 3840 secqty 3840 DEFER YES ~

CREATE INDEX PBI.IX_YTIGOS_BANK ON PBI."TableYTIGos" (
    "NrBankMQ" ASC
) using stogroup SGPBI priqty 60 secqty 60 DEFER YES ~

CREATE INDEX PBI.IX_YSRGOS_JOIN ON PBI."TableYSRGos" (
    "NrAccount" ASC,
    "CdCurrency" ASC,
    "NrEWallet" ASC,
    "NrBank" ASC,
    "DtBalance" ASC
) using stogroup SGPBI priqty 24 secqty 24 DEFER YES ~

CREATE INDEX PBI.IX_SPBICBY_FILTER ON PBI."SPBICBY" (
    "BICStatus" ASC,
    "CdActRecord" ASC,
    "NrBank" ASC,
    "CdBank" ASC
) using stogroup SGPBI priqty 12 secqty 12 DEFER YES ~

CREATE INDEX PBI.IX_SPACCINC_FILTER ON PBI."SPAccGosInclude" (
    "PrYSR" ASC,
    "count_NrAccount" ASC,
    "NrAccountOrder" ASC
) using stogroup SGPBI priqty 12 secqty 12 DEFER YES ~

CREATE INDEX PBI.IX_SPACCEXC_FILTER ON PBI."SPAccGosExclude" (
    "PrYSR" ASC,
    "count_NrAccount" ASC,
    "NrAccountOrder" ASC
) using stogroup SGPBI priqty 12 secqty 12 DEFER YES ~

CREATE INDEX PBI.IX_SPDATESCTL_FILTER ON PBI."SPDatesControl" (
    "PrYSR_Month" ASC,
    "LastWorkDayMonth" DESC
) using stogroup SGPBI priqty 12 secqty 12 DEFER YES ~
