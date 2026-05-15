CREATE INDEX PBI.IX_ACCSTATUS_JOIN_COVER ON PBI."AccountStatus" (
    "IDNAccount" ASC,
    "AccountStatus" ASC,
    "DtAccountOpen" ASC,
    "DtAccountChange" ASC,
    "StatusOwner" ASC
) using stogroup SGPBI priqty 9600 secqty 9600 DEFER YES ~

CREATE INDEX PBI.IX_ACCOUNT_NB_BA_COVER ON PBI."Account" (
    "NrBank" ASC,
    "BalAccount4" ASC,
    "BalAccount3" ASC,
    "BalAccount2" ASC,
    "IDNAccount" ASC,
    "NrAccount" ASC,
    "NrEWallet" ASC,
    "CdCurrency" ASC
) using stogroup SGPBI priqty 9600 secqty 9600 DEFER YES ~

CREATE INDEX PBI.IXE_YTIGOS_PAYER ON PBI."TableYTIGos" (
    "NrBankMQ" ASC,
    (SUBSTR("NrAccountPayer", 5, 4)) ASC
) using stogroup SGPBI priqty 240 secqty 240 DEFER YES ~

CREATE INDEX PBI.IXE_YTIGOS_BENEF ON PBI."TableYTIGos" (
    "NrBankMQ" ASC,
    (SUBSTR("NrAccountBenef", 5, 4)) ASC
) using stogroup SGPBI priqty 240 secqty 240 DEFER YES ~

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
