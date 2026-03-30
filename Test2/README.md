# Test2: автогенерируемые поля (GENERATED ALWAYS) для префиксов балансового счёта

Вариант для **DB2 for z/OS**: в таблицы `PBI."Account"` и `PBI."InfoYSR"` добавляются:

- **`BalPrefix1` … `BalPrefix4`** — то же, что `SUBSTR("NrAccount", 9, N)`;
- **`AccountKey`** — то же, что поле `"Account"` в отчёте (конкатенация `NrAccount` / `NrEWallet` / `CdCurrency` по правилам `script.sql`).

По префиксам строятся **индексы**; в `script_final.sql` нет ни `SUBSTR` в фильтрах, ни ручного `CASE` для ключа — берётся **`AccountKey`**.

## Ограничения

- Нужны права **ALTER** на таблицы и **CREATE** на индексы в схеме `PBI` (или куда согласуете индексы).
- На больших таблицах `ALTER … ADD COLUMN` и построение индекса могут быть **долгими**; согласовать окно с DBA.
- После DDL — **RUNSTATS** по таблицам/индексам (см. `04_runstats_hint.sql`).

## Файлы

| Файл | Назначение |
|------|------------|
| `01_alter_account_bal_prefix.sql` | `ALTER TABLE` — 4 generated column на `PBI."Account"` |
| `02_alter_infoysr_bal_prefix.sql` | `ALTER TABLE` — 4 generated column на `PBI."InfoYSR"` |
| `03_create_indexes.sql` | Новые индексы по `NrBank`/`DtBalance` + префиксам + (опц.) `AccountKey` |
| `04_runstats_hint.sql` | Памятка по RUNSTATS |
| `script_final.sql` | Запрос с использованием `BalPrefix*` (аналог `../script.sql`) |

**Порядок:** `01` → `02` → `03` → `04` (по необходимости) → `script_final.sql`.

## Откат (идея)

Удаление generated column в Db2 — отдельная операция `ALTER … DROP COLUMN` (имена столбцов как в DDL). Перед удалением столбцов — **DROP INDEX**, которые на них ссылаются.
