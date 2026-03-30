# Test2: индексы по выражениям `SUBSTR` (Db2 for z/OS)

Для Db2 for z/OS выражения вида `ADD COLUMN ... GENERATED ALWAYS AS (<expr>)` для вычисляемых колонок недоступны (обычно Db2/валидатор “ждёт IDENTITY/CHECK”).

Поэтому ускорение делаем так:

- создаём **индексы по выражениям** `SUBSTR("NrAccount", 9, N)`;
- запрос можно оставлять с `SUBSTR` в предикатах (см. `script_final.sql`).

## Ограничения

- Нужны права **CREATE** на индексы в схеме `PBI` (или куда согласуете индексы).
- Построение индексов на больших таблицах может быть **долгим**; согласовать окно с DBA.
- После DDL — **RUNSTATS** по таблицам/индексам (см. `04_runstats_hint.sql`).

## Файлы

| Файл | Назначение |
|------|------------|
| `01_alter_account_bal_prefix.sql` | Заглушка (generated columns не используем на z/OS) |
| `02_alter_infoysr_bal_prefix.sql` | Заглушка (generated columns не используем на z/OS) |
| `03_create_indexes.sql` | Индексы по `NrBank`/`DtBalance` + `SUBSTR(NrAccount,9,N)` |
| `04_runstats_hint.sql` | Памятка по RUNSTATS |
| `script_final.sql` | Запрос (аналог `../script.sql`) под индексы `SUBSTR` |

**Порядок:** `03` → `04` (по необходимости) → `script_final.sql`.

## Откат (идея)

Удаление — это **DROP INDEX** для созданных индексов из `03_create_indexes.sql`.
