# Open Data Module

## Configuration file parameters

Following subsections describe all the [configuration file](../../opendata_module/anonymizer/opendata_config.p) parameters. 

#### Anonymizer

##### Field translations file

Field translation file defines, how the (nested) field names in MongoDB are mapped to the PostgreSQL database field names.

Entries in MongoDB are "dual", meaning that one entry holds both a *client* log together with the matching *producer* log. Entries in PostgreSQL are singular, meaning that client and producer logs are separated.

The file is also used to determine all the relevant MongoDB fields, meaning that even if it's an identity mapping (field name in MongoDB matches the field name in PostgreSQL), the mapping must exist.

The file must always be located in **opendata_module/anonymizer/cfg_lists/** folder. Default file is called **field_translations.list** and is located at **opendata_module/anonymizer/cfg_lists/field_translations.list**.

```python
anonymizer['field_translations_file'] = 'field_translations.list'
```

The file rows must follow the format

```
mongodb.collections[.nested].path -> postgresql_column_name
```

Example rows from the default file:

```
client.securityServerType -> securityServerType
producer.securityServerType -> securityServerType
totalDuration -> totalDuration
producerDurationProducerView -> producerDurationProducerView
```


##### Transformers
Transformers are custom Python functions which take in a singular record with the final Open Data database schema (no "client." or "producer." preficies, postgresql_column_name keys) in the form of Python dictionary and can change one or many values. By default, only a transformer for reducing *requestInTs* accuracy is implemented and installed.

The following statement says that only **opendata_module/anonymizer/transformers/default**:reduce_request_in_ts_precision is applied in the anonymization process. All custom transformers must be located within the *transformers* directory.

```
anonymizer['transformers'] = ['default.reduce_request_in_ts_precision']
```

The corresponding transformer function is the following

```python
def reduce_request_in_ts_precision(record):
    timestamp = int(record['requestInTs'] / 1000)
    initial_datetime = datetime.fromtimestamp(timestamp)
    altered_datetime = initial_datetime.replace(minute=0, second=0)
    record['requestInTs'] = int(altered_datetime.timestamp())
    return record
```

and removes minute and second precision from *requestInTs* field.

##### Processing threads

Reading from MongoDB is done in the master thread. All the processing and writing is done in parallel among the defined number of threads (subprocesses due to [GIL](https://wiki.python.org/moin/GlobalInterpreterLock "Global Interpreter Lock")).

```python
anonymizer['threads'] = 2
```

##### Time offset

Anonymizer gives time for the corrector to get its *clean_data* table sorted out. This is done by providing a history, which defines how far back will the anonymizer look in hope to see that formerly "in progress" corrections have been completed. That temporal span is called the "time offset". *Time offset* + 7 days is also the duration during which Mongodb id-s are stored in the rotational log index.

**Note:** *time offset* should match or exceed corrector's time offset. 

```python
anonymizer['time_offset'] = relativedelta(days=10)
```
Anonymizer's time offset uses *dateutils.relativedelta* to allow to specify a temporal difference from microseconds to years.


#### MongoDB<a name="mongo-conf"></a>

MongoDB settings define the connection parameters for an existing MongoDB database.

```python
mongo_db['host_address'] = 'opmon.ci.kit'
mongo_db['port'] = 27017
mongo_db['auth_db'] = 'auth_db'
mongo_db['user'] = 'dev_user'
mongo_db['password'] = 'jdu21docxce'
mongo_db['database_name'] = 'query_db_ee-dev'
mongo_db['table_name'] = 'clean_data'
```

**Note:** *auth_db* is the table in MongoDB which is responsible for authentication. If MongoDB is set up without specific admin on authentication database, *mongo_db['auth_db']* should be the same as *mongo_db['database_name']*.

**Note:** *database_name* depends on X-Road instance.

#### PostgreSQL<a name="postgres-conf"></a>

PostgreSQL settings define the connection parameters for the existing PostgreSQL database (see Installation).

```
postgres['buffer_size'] = 1000
postgres['host_address'] = 'opmon-opendata.ci.kit'
postgres['port'] = 5432
postgres['database_name'] = 'opendata'
postgres['table_name'] = 'logs'
postgres['user'] = 'opendata'
postgres['password'] = '12345'
```

The odd man is the *buffer_size*, which defines how many records will be processed and sent to the PostgreSQL database by one subprocess at a time.

**Note:** *table_name* must differ between X-Road instances.

#### Hiding rules

Hiding rules allow to define sets of (feature name, feature value regular expression) pairs. If all the pairs of any set match a record, the record will never see the daylight in the Open Data database.

The following example defines a single rule, which hides records with `clientXRoadInstance=EE` and `clientMemberClass=GOV` and `clientMemberCode=70005938` or `clientMemberCode=70000591`.

```python
hiding_rules = [[{'feature': 'clientXRoadInstance', 'regex': '^EE$'},
                {'feature': 'clientMemberClass', 'regex': '^GOV$'},
                {'feature': 'clientMemberCode', 'regex': '^(70005938|70000591)$'}],
                ]
```

#### Substitution rules

Substitution rules allow to hide/alter specific field values with a similar format to hiding rules.

The following example changes "clientMemberClass" values to "X-tee salaklass" for all the records of which "clientXRoadInstance=XYZ". 

```python
substitution_rules = [
    {
        'conditions': [
            {'feature': 'clientXRoadInstance', 'regex': '^XYZ$'},
        ],
        'substitutes': [
            {'feature': 'clientMemberClass', 'value': 'X-tee salaklass'}
        ]
    },
]
```

**Note:** *conditions* can have many constraints like in the hiding rules example and *substitutes* can change many values at once when increasing the list.

#### Field data file

Field data file maps descriptions, PostgreSQL data types and optionally agent-specificity to final (PostgreSQL) fields. 

Field data file, just like _opendata_config.py_ is duplicated for both Anonymizer (_monitor/opendata_module/anonymizer/cfg_lists/field_data.yaml_) and Interface (_monitor/opendata_module/interface/cfg_lists/field_data.yaml_). Anonymizer and Interface of the same X-Road instance must have identical field data files.

**Descriptions** are listed in API served gzipped tarball meta files and visible when hovering over GUI's features in preview mode.

**Data types** must be correct and exact PostgreSQL data types, as they are used in automatically creating PostgreSQL database schemas. 

**Agent-specificity** can be defined in order to allow only a single agent ("client","producer") to have a *non-null* value.

```python
field_data_file = 'cfg_lists/field_data.yaml'
```

The following YAML file shows, how "id" and "totalDuration" fields are described. They are both stored as integers and in addition, "totalDuration" is only "available" for "client" logs. Producers also have the "totalDuration" field for data integrity, but their "totalDuration" value is always *null*.

```yaml
fields:
    id:
        description: Unique identifier of the record
        type: integer
    totalDuration:
        description: To DOOOO
        type: integer
        agent: client
```

#### Interface

Most of the interface-specific settings, such as hosts, static directories etc can be defined in the Django settings file [**opendata_module/interface/interface/settings.py**](../../opendata_module/interface/interface/settings.py).

However, disclaimer, preview_limit, and heartbeat_interval can be set in the general Open Data configuration file [*opendata_config.py*](../../opendata_module/anonymizer/opendata_config.py).

##### Disclaimer

Text which will be shown in the GUI and meta files accompanying the downloaded logs.

```python
disclaimer = '<b>DISCLAIMER: </b>This is a disclaimer from the configuration.'
```

##### Preview limit

Preview limit defines the number of records which will be available in the GUI's preview panel.

```python
preview_limit = 100
```

##### Heartbeat interval

Heartbeat interval defines in seconds, how often should the constantly running Django application output a heartbeat.

```python
heartbeat_interval = 3600
```
