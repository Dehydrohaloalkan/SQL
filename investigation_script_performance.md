# Расследование медленной работы `script.sql`

## Цель
Понять, почему скрипт выполняется ~50 минут, и какие изменения/индексы/переписывание запросов это исправят.

## Контекст выполнения (заполнить)
- **СУБД / версия**: DB2 for z/OS V12
- **Схема**: `PBI`
- **Как запускается**: вручную, ежедневно
- **Параметры**: нет
- **Ограничения**: менять скрипт минимально; вероятно нужны надстройки над таблицами (индексы/статистики/материализация/таблицы-помощники)



### 1) `PBI."Account"`
- **Использование в скрипте**: CTE `AA` — основная выборка счетов, фильтры по банку и по префиксам балансовых счетов через `SUBSTR("NrAccount", 9, N)`.
- **Поля из запроса**:
  - `IDNAccount`, `NrBank`, `NrAccount`, `NrEWallet`, `CdCurrency`
- **Кол-во строк (примерно)**: ~155 000 000
- **Ключи/ограничения (из описания)**:
  - `IDNAccount` — отмечен как PK 
- **Фильтры/условия**:
  - `NrBank IN (SELECT ... FROM PBI."SPBICBY" ...)`
  - `NrBank <> '042'`
  - `NrBank IN ('108','110',...,'964')`
  - `SUBSTR("NrAccount", 9, 1/2/3/4) IN (SELECT "BalAccount" FROM PBI."SPAccountControl" WHERE ... )`

#### Схема `PBI."Account"`
| Схема | Колонка            | Таблица   | Тип           | По умолчанию | NULL | PK  | Unique | FK  |
|-------|--------------------|-----------|---------------|--------------|------|-----|--------|-----|
| `PBI` | `IDNAccount`       | `Account` | `BIGINT`      |              | нет  | да  | да     | нет |
| `PBI` | `NrBank`           | `Account` | `CHAR(3)`     |              | нет  | нет | нет    | нет |
| `PBI` | `CdBank`           | `Account` | `VARCHAR(11)` |              | нет  | нет | нет    | нет |
| `PBI` | `NrAccount`        | `Account` | `CHAR(28)`    |              | нет  | нет | нет    | нет |
| `PBI` | `CdCurrency`       | `Account` | `CHAR(3)`     |              | нет  | нет | нет    | нет |
| `PBI` | `NrEWallet`        | `Account` | `VARCHAR(34)` | NULL         | да   | нет | нет    | нет |
| `PBI` | `AccountStatus`    | `Account` | `CHAR(1)`     | 0            | нет  | нет | нет    | нет |
| `PBI` | `IDNAccountStatus` | `Account` | `BIGINT`      | 0            | нет  | нет | нет    | нет |
| `PBI` | `IDNInfoYSB`       | `Account` | `BIGINT`      | 0            | нет  | нет | нет    | нет |
| `PBI` | `DtTmProcessing`   | `Account` | `TIMESTAMP`   |              | нет  | нет | нет    | нет |

#### Индекс `x1`
| Колонка      | Направление | Тип      |
|--------------|-------------|----------|
| `IDNAccount` | `ASC`       | `BIGINT` |

#### Индекс `x2`
| Колонка      | Направление | Тип           |
|--------------|-------------|---------------|
| `NrBank`     | `ASC`       | `CHAR(3)`     |
| `NrAccount`  | `ASC`       | `CHAR(28)`    |
| `NrEWallet`  | `ASC`       | `VARCHAR(34)` |
| `CdCurrency` | `ASC`       | `CHAR(3)`     |

#### Индекс `x3`
| Колонка     | Направление | Тип           |
|-------------|-------------|---------------|
| `CdBank`    | `ASC`       | `VARCHAR(11)` |
| `NrAccount` | `ASC`       | `CHAR(28)`    |
| `NrEWallet` | `ASC`       | `VARCHAR(34)` |



### 2) `PBI."SPBICBY"`
- **Использование**: подзапрос в `AA` для ограничения `NrBank` по статусам.
- **Поля из запроса**:
  - `NrBank`, `BICStatus`, `CdActRecord`
- **Кол-во строк (примерно)**: ~70
- **Фильтры/условия**:
  - `BICStatus IN ('0','1') AND CdActRecord='0'`

#### Схема `PBI."SPBICBY"` (полностью из файла `1`)
| Схема | Колонка           | Таблица   | Тип           | По умолчанию | NULL |  PK | Unique |  FK | Проверена |
|-------|-------------------|-----------|---------------|--------------|-----:|----:|-------:|----:|----------:|
| `PBI` | `CdBank`          | `SPBICBY` | `VARCHAR(11)` |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `CdHeadBank`      | `SPBICBY` | `CHAR(8)`     |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `NrBank`          | `SPBICBY` | `CHAR(3)`     |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `CdBankStatus`    | `SPBICBY` | `CHAR(1)`     |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `BICStatus`       | `SPBICBY` | `CHAR(1)`     |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `NrAccount`       | `SPBICBY` | `CHAR(28)`    | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `NmBankShort`     | `SPBICBY` | `VARCHAR(80)` |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `CdControl`       | `SPBICBY` | `CHAR(4)`     | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `DtControl`       | `SPBICBY` | `DATE`        | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `CdBankSuccessor` | `SPBICBY` | `VARCHAR(11)` | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `CdUNP`           | `SPBICBY` | `CHAR(9)`     | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `CdActRecord`     | `SPBICBY` | `CHAR(1)`     |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `DtBegin`         | `SPBICBY` | `DATE`        |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `DtEnd`           | `SPBICBY` | `DATE`        | NULL         |   да | нет |    нет | нет |       нет |

#### Индекс `x1`
| Колонка  | Направление | Тип           |
|----------|-------------|---------------|
| `CdBank` | `ASC`       | `VARCHAR(11)` |



### 3) `PBI."SPAccountControl"`
- **Использование**: 4 раза в `AA` и 4 раза в `SRA` (всего 8 подзапросов `IN`), чтобы проверять префикс `BalAccount` длиной 1..4.
- **Поля из запроса**:
  - `BalAccount`, `count_BalAccount`, `PrYSR`
- **Кол-во строк (примерно)**: ~172
- **Индексы**: нет
- **Фильтры/условия**:
  - `PrYSR='1'` и `count_BalAccount IN ('1','2','3','4')`

#### Схема `PBI."SPAccountControl"`
| Схема | Колонка            | Таблица            | Тип          | По умолчанию | NULL |  PK | Unique |  FK | Проверена |
|-------|--------------------|--------------------|--------------|--------------|-----:|----:|-------:|----:|----------:|
| `PBI` | `BalAccount`       | `SPAccountControl` | `VARCHAR(4)` | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `count_BalAccount` | `SPAccountControl` | `INTEGER`    | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `PrYSR`            | `SPAccountControl` | `INTEGER`    | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `YSB_NrEWallet`    | `SPAccountControl` | `INTEGER`    | NULL         |   да | нет |    нет | нет |       нет |



### 4) `PBI."AccountStatus"`
- **Использование**: CTE `AC` — `INNER JOIN` с `AA` по `IDNAccount`; дополнительно фильтр по `StatusOwner` для части счетов (`SUBSTR(Account,9,4)='3119'`).
- **Поля из запроса**:
  - `IDNAccount`, `AccountStatus`, `DtAccountOpen`, `DtAccountChange`, `StatusOwner`
- **Кол-во строк (примерно)**: ~156 000 000
- **JOIN**:
  - `AA.IDNAccount = AccountStatus.IDNAccount`
- **Фильтры/условия**:
  - `NOT (SUBSTR("Account", 9, 4)='3119' AND StatusOwner IN ('INP','IZP'))`

#### Схема `PBI."AccountStatus"` (полностью из файла `1`)
| Схема | Колонка            | Таблица         | Тип         | По умолчанию | NULL |  PK | Unique |  FK | Проверена |
|-------|--------------------|-----------------|-------------|--------------|-----:|----:|-------:|----:|----------:|
| `PBI` | `IDNAccountStatus` | `AccountStatus` | `BIGINT`    |              |  нет |  да |     да | нет |       нет |
| `PBI` | `IDNAccount`       | `AccountStatus` | `BIGINT`    |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `IDNNrID`          | `AccountStatus` | `BIGINT`    | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `IDNUNP`           | `AccountStatus` | `BIGINT`    | 0            |  нет | нет |    нет | нет |       нет |
| `PBI` | `DtAccountOpen`    | `AccountStatus` | `DATE`      |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `DtAccountChange`  | `AccountStatus` | `DATE`      |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `StatusOwner`      | `AccountStatus` | `CHAR(3)`   |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `AccountStatus`    | `AccountStatus` | `CHAR(1)`   |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `DtTmProcessing`   | `AccountStatus` | `TIMESTAMP` |              |  нет | нет |    нет | нет |       нет |

#### Индекс `x1`
| Колонка            | Направление | Тип      |
|--------------------|-------------|----------|
| `IDNAccountStatus` | `ASC`       | `BIGINT` |

#### Индекс `x2`
| Колонка            | Направление | Тип      |
|--------------------|-------------|----------|
| `IDNAccount`       | `ASC`       | `BIGINT` |
| `IDNAccountStatus` | `ASC`       | `BIGINT` |



### 5) `PBI."SPDatesControl"`
- **Использование**: CTE `D` — получает `MAX(LastWorkDayMonth)` для месяца.
- **Поля из запроса**:
  - `LastWorkDayMonth`, `PrYSR_Month`
- **Кол-во строк (примерно)**: ~23
- **Индексы**: нет
- **Фильтры/условия**:
  - `PrYSR_Month='1'`

#### Схема `PBI."SPDatesControl"`
| Схема | Колонка            | Таблица          | Тип       | По умолчанию | NULL |  PK | Unique |  FK | Проверена |
|-------|--------------------|------------------|-----------|--------------|-----:|----:|-------:|----:|----------:|
| `PBI` | `LastWorkDayMonth` | `SPDatesControl` | `DATE`    | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `PrYSR_Month`      | `SPDatesControl` | `INTEGER` | NULL         |   да | нет |    нет | нет |       нет |



### 6) `PBI."InfoYSR"`
- **Использование**: CTE `SRA` — счета, по которым уже есть остатки на дату `D.DtBalance`.
- **Поля из запроса**:
  - `NrAccount`, `NrEWallet`, `CdCurrency`, `DtBalance`
- **Кол-во строк (примерно)**: ~237 000 000
- **Ключи/ограничения (из описания)**:
  - `IDNInfoYSR` — PK
- **Фильтры/условия**:
  - `DtBalance IN (SELECT DtBalance FROM D)`
  - те же проверки `SUBSTR("NrAccount", 9, 1..4) IN (SELECT BalAccount FROM PBI."SPAccountControl" ...)`

#### Схема `PBI."InfoYSR"`

| Схема | Колонка          | Таблица   | Тип             | По умолчанию | NULL |  PK | Unique |  FK | Проверена |
|-------|------------------|-----------|-----------------|--------------|-----:|----:|-------:|----:|----------:|
| `PBI` | `IDNInfoYSR`     | `InfoYSR` | `BIGINT`        | NULL         |   да |  да |     да | нет |       нет |
| `PBI` | `IDNAccount`     | `InfoYSR` | `BIGINT`        |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `IDNInputFile`   | `InfoYSR` | `BIGINT`        |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `Number`         | `InfoYSR` | `VARCHAR(35)`   |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `NrBank`         | `InfoYSR` | `CHAR(3)`       |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `CdBank`         | `InfoYSR` | `VARCHAR(11)`   |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `NrAccount`      | `InfoYSR` | `CHAR(28)`      |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `NrEWallet`      | `InfoYSR` | `VARCHAR(34)`   | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `CdCurrency`     | `InfoYSR` | `CHAR(3)`       |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `PrBalance`      | `InfoYSR` | `CHAR(1)`       |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `DtBalance`      | `InfoYSR` | `DATE`          |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `SumCurrency`    | `InfoYSR` | `DECIMAL(23,5)` |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `SumBYN`         | `InfoYSR` | `DECIMAL(23,5)` |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `DtOperation`    | `InfoYSR` | `DATE`          | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `PrOperation`    | `InfoYSR` | `CHAR(1)`       | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `SumOperation`   | `InfoYSR` | `DECIMAL(23,5)` | NULL         |   да | нет |    нет | нет |       нет |
| `PBI` | `DtTmProcessing` | `InfoYSR` | `TIMESTAMP`     |              |  нет | нет |    нет | нет |       нет |
| `PBI` | `BalanceStatus`  | `InfoYSR` | `CHAR(1)`       | 0            |  нет | нет |    нет | нет |       нет |

#### Индекс `x1`
| Колонка      | Направление | Тип      |
|--------------|-------------|----------|
| `IDNInfoYSR` | `ASC`       | `BIGINT` |

#### Индекс `x2`
| Колонка         | Направление | Тип           |
|-----------------|-------------|---------------|
| `DtBalance`     | `DESC`      | `DATE`        |
| `NrBank`        | `ASC`       | `CHAR(3)`     |
| `NrAccount`     | `ASC`       | `CHAR(28)`    |
| `NrEWallet`     | `ASC`       | `VARCHAR(34)` |
| `CdCurrency`    | `ASC`       | `CHAR(3)`     |
| `BalanceStatus` | `DESC`      | `CHAR(1)`     |

