# X-Road v6 monitor project - Open Data Module, API documentation

## About

Open Data API allows to query daily logs or log samples programmatically without the necessity to interact with the graphical user interface.

In order to achieve that, handlers allow to query the following data:

* Minimum and maximum date of the available logs;
* Column names, types, descriptions and available oeprators;
* All daily logs in **tar.gz** format;
* Sample logs for a day in **JSON** format.

### Response codes

* **[200]** - Expected response has been delivered.
* **[400]** - Malformed query: consult the given documentation and 	response message.
* **[500]** - Query was fine, but something went wrong internally (a bug has slipped past): consult administrator.

### Error format

All API error messages are in JSON format and look similar to

```bash
{"error": "Missing \\"date\\" field."}
```

### Supported HTTP request methods

API supports all the HTTP request methods:

* GET
* POST (and its derivates PUT and DELETE)

### POST payload

POST expects query to be in JSON format and be the whole request body. 

#### Examples

**cURL:**

```bash
curl -XPOST /api/daily_logs -d '{"date": "2017-09-15"}'
```

**Python:**

```python
import requests
import json

requests.post('http://api_host_address/api/daily_logs', data=json.dumps({'date': '2017-09-15'}))
```


## Handlers

### Minimum and maximum date

Logs can only be downloaded on a daily basis. The handler provides a date range, from which it is sensible to query.

```bash
GET /api/date_range
```

#### Parameters

None

#### Returns

Minimum and maximum date of the logs in the database.

```bash
{'date': {'min': '2017-09-19', 'max': '2017-09-25'}}
```

### Column data

It is possible to provide several data column specific parameters when querying daily logs. This handler gives an overview of the columns.

```bash
GET /api/column_data
```

#### Parameters

None

#### Returns


Metadata of the existing columns.

```bash
{"columns": [
    {"type": "string", "valid_operators": ["=", "!="], "name": "clientSubsystemCode", "description": "Subsystem code of the X-Road member (client)"},
    {"type": "integer", "valid_operators": ["=", "!=", "<", "<=", ">", ">="], "name": "responseAttachmentCount", "description": "Number of attachments of the response"},
    {"type": "string", "valid_operators": ["=", "!="], "name": "clientMemberCode", "description": "Member code of the X-Road member (client)"},
    {"type": "string", "valid_operators": ["=", "!="], "name": "serviceMemberClass", "description": "Member class of the X-Road member (service provider)"},
    {"type": "integer", "valid_operators": ["=", "!=", "<", "<=", ">", ">="], "name": "id", "description": "Unique identifier of the record"}, 
    {"type": "string", "valid_operators": ["=", "!="], "name": "securityServerType", "description": "Type of the security server"}, 
    {"type": "string", "valid_operators": ["=", "!="], "name": "serviceMemberCode", "description": "Member code of the X-Road member (service provider)"},
    {"type": "integer", "valid_operators": ["=", "!=", "<", "<=", ">", ">="], "name": "responseSoapSize", "description": "Size of the response (bytes)"},
    {"type": "boolean", "valid_operators": ["=", "!="], "name": "succeeded", "description": "True, if request mediation succeeded, false otherwise."},
    ...
]}
```

### Logs' sample

Retrieve N first logs, which have matched the query, in JSON format.

```bash
POST /api/logs_sample
```
#### Parameters

**date** (mandatory)

Specifies the day of which logs are fetched.

> **type:** string
> **format**: YYYY-MM-DD
> **example:** `{"date": "2017-09-21"}`

**columns** (optional)

Specifies the columns to return.

_Note:_ If missing or an empty list, all available columns are included.

> **type:** list of strings
> **example:** `{"columns": ["clientSubsystemCode", "messageId", "succeeded"]}`

**constraints** (optional)

Specifies the criteria which the returned logs must meet. 

_Note:_  If missing or an empty list, no constraints will be applied to the logs other than the date and all the day's logs are returned.

> **type:** list of JSON objects
> **format:** `{"column": "columnName", "operator": "validOperator", "value": "someValue"}`
> > **column:** name of the column
> > **operator:** valid operator for the column's data type (`"=", "!=", "<", "<=", ">", ">="`)
> **example:** `{"constraints": [{"operator": "=", "value": "a12c-035f11052dc6", "column": "messageId"}]}`

**order clauses** (optional)

Specifies the order in which to return the logs.

_Note:_ If missing or an empty list, logs are ordered by "id".
_Note:_ Different order clauses may return different logs, depending on whether database optimizer first limits or first orders the queried data.

> **type:** list of JSON objects
> **format:** `{"column": "columnName", "order: "asc|desc"}`

#### Returns

JSON object with "data" key holding list of logs. Each log is represented as a list with deterministic column order (in the same order as the columns were provided). If columns were not provide, the order is identical to the column order from [column data](#column-data).

```bash
{"data": [
	["4905", "001e90e8-c1c4-4edc-80a4-1a0f8945774a", "2017-09-21", "3", "True", "113"],
	["10325", "00336a85-1a72-48e4-bf5a-215c3f9af497", "2017-09-21", "3", "True", "146"],
	["155975", "004061a2-7e6f-48cf-9d30-e43c26e7b763", "2017-09-21", "3", "True", "148"],
	...
]}
```

#### Example query

```bash
curl -XPOST /api/logs_sample -d '
{
    "date": "2017-09-21",
    "columns": ["id","messageId","requestInDate","responseAttachmentCount","succeeded","totalDuration"]
    "constraints": [{"column":"totalDuration","operator":"<=","value":"150"}]
    'order-clauses": [{"column":"messageId","order":"asc"}]
}
'
```

### Daily logs

Retrieve all logs for a specified date in a **tar.gz** archive. The archive consists of two files:

* **YYYY-MM-DD.json**
* **meta.json**

```bash
POST /api/daily_logs
```

#### Parameters

Identical to [logs' sample](#logs-sample).

#### Returns

Binary `YYYY-MM-DD@QUERY_TIMSTAMP.tar.gz` file with MIME type "application/gzip".

#### Example query

```bash
curl -XPOST /api/daily_logs -d '
{
    "date": "2017-09-21",
    "columns": ["id","messageId","requestInDate","responseAttachmentCount","succeeded","totalDuration"]
    "constraints": [{"column":"totalDuration","operator":"<=","value":"150"}]
    'order-clauses": [{"column":"messageId","order":"asc"}]
}
'
```