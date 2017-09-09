# X-Road project - Open Data Module

## About

Open Data Module (**ODM**) provides

Anonymizer
: A pipeline for making RIA logs suitable for public use. It is achieved by fetching still unprocessed - but corrected data - from the Corrector Module's output, applying the defined anonymization procedures, and outputting the already anonymized data.

Interface
: An API and a GUI to access the already anonymized data.

## Open Data Module's architecture

![system diagram](img/opendata/opendata_overview.png "System overview")

**Open Data Module resides on 2 machines.**

Anonymizer and PostgreSQL share a machine without publicly accessible interface.

Open Data Module's Interface (API and GUI) should reside on a machine with public access.

## Installation and specific configuration

[**Node 1: Anonymizer and PostgreSQL**](opendata/anonymizer_postgresql.md)
[**Node 2: Interface**](opendata/interface.md)

## Scaling over X-Road instances

Each X-Road instance will have it's own set of Anonymizer, PostgreSQL tables, and Interface. X-Road instance INSTANCE will have its data anonymized by its dedicated Anonymizer, anonymized data is stored in a specific PostgreSQL table, and Interface --- configured to serve INSTANCE data --- serves the anonymized data.

If there are 3 X-Road instances, there should also be 3 Anonymizers, 3 PostgreSQL tables storing the logs, and 3 Interface applications running.

### Adding another X-Road instance

1. Pull repository to Node 1 (new location, e.g ~/anonymizers/instanceX)
2. Configure  [**opendata_config.py**](../opendata_module/anonymizer/opendata_config.py). If another X-Road instance is configured, substitute the configuration file and set appropriate and new `mongo_db['database_name']` and `mongo_db['database_name']` values.
3. Pull repository to Node 2 (new location, e.g /var/www/instanceX) Copy configuration to Node 2:/var/www/instanceX/monitor/opendata_module/interface/.
4. Add crontab for new Anonymizer instance and add another VirtualHost to Apache.

## Configuration

Most of the ODM (both Anonymizer and Interface) can be configured from the [**opendata_config.py**](../opendata_module/anonymizer/opendata_config.py) Python file. Anonymizer and Interface have their individual copies in their respective directories.

* **Anonymizer**
	[monitor/opendata_module/anonymizer/opendata_config.py](../opendata_module/anonymizer/opendata_config.py)
* **Interface**
	[monitor/opendata_module/interface/opendata_config.py](../opendata_module/interface/opendata_config.py)
	
The files are otherwise identical and should remain identical for a fixed X-Road instance.

**To set up Open Data Module for one X-Road instance, pull the module to Anonymizer and Interface nodes, configure the _opendata_config.py_ on one of the nodes and copy to the other.**

**Note:** _opendata_config.py_ can be served from Network File System and sotflinked to an appropriate directory to keep configuration file in synchronization.

### Configuration file parameters

Configuration file parameters and default values are described [here](opendata/configuration_parameters.md).

Following subsections describe all the configuration file parameters. **However, to do an "off-the-shelf" installation, only [MongoDB](opendata/configuration_parameters.md#mongo-conf), [PostgreSQL](opendata/configuration_parameters.md#postgres-conf) and [Django](opendata/configuration_parameters.md#django-conf) settings should need tuning (and possibly number of anonymizer's processing threads).**

## Inner processes

### Anonymization

1. Anonymizer requests the past 10 days records, which are "done" (corrector doesn't make any further alterations to the record).
2. Batches of *postgres['buffer_size']* records are distributed to the processing threads.
3. Each batch is run against the index to filter out the already processed records.
4. Unprocessed records (dual records with potentially client and producer data) are split into individual client and producer logs.
5. Each individual log is then
	1. checked whether it should be ignored, using custom hiding rules from *opendata_config.py*;
	2. having its individual values changed to constant values by the custom substitution rules (for example set mime sizes to 0 if represented party code is X);
	3. transformed by custom transformers (Python functions). Custom transformers can perform more complicated or "dynamic" value alterations (for example reducing timestamp precision);
	4. written to PostgreSQL database.


## Running

### Anonymizer

#### One session

One session of anonymization is run by issuing

```python
python anonymize.py
```

**anonymize.py** instantiates the necessary classes and writes *heartbeat* similar to
```python
{"version": "0.0.1", "mongodb": true, "name": "Anonymizer", "timestamp": "01-09-2017 13-35-35", "succeeded": true, "postgres": true}
```
 to Anonymizer's root directory. In addition to the general information, heartbeat also returns *mongodb* and *postgres* statuses, both of which must be *True* in order for anonymizer to work properly.

#### Session data

The only value which is passed between any two consecutive anonymization sessions is the previous session timestamp. It is stored in *settings.db* SQLite database. The next session processes all the data in the *clean_data* collection within the range

```bash
min(current time - 1 week, previous session time) .. current time
```

#### Scheduled anonymization

Anonymizer is meant to be run every day

In order to anonymize the logs and update Open Data PostgreSQL database on a regular basis, **cron(tab)** is recommended.

```bash
crontab -e
# Run anonymizer every day
0 0 * * * /usr/bin/python opendata_module/anonymizer/anonymizer.py
```

#### Created PostgreSQL tables

After the first run with new *postgres* parameters, anonymizer creates 2 tables.

* Table with name *postgres['table_name']* stores the anonymized logs.
* Table with name *postgres['table_name']_log_index* is a time-wise rotational index which is used to avoid reprocessing logs due to time window defined by *time offset*. Too old entries are removed the the beginning of every session.


### Interface

To test GUI and API, run

```bash
sudo python manage.py opendata_module/interface/runserver 0.0.0.0:80
```

By default the web interface will be served at http://localhost/gui.

**Note:** It should be served by an Apace or an equivalent server application, using wsgi handler at **opendata_module/interface/interface/wsgi.py**


## Usage

### API

API docs will be served from http://localhost:8000/api/docs with Swagger. (in progress)
