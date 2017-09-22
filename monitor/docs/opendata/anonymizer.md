# Open Data Module
# Anonymizer Node

## Installation

Each X-Road instance needs its own instance of Anonymizer.

### Setting up X-Road instances

Let's first download the Anonymizer's code from the repository.

```bash
sudo apt-get -y upgrade
sudo apt-get install git -y
git clone https://stash.ria.ee/scm/xtee6/monitor.git
```

We'll run Anonymizer under its dedicated user.

```bash
sudo groupadd -f opmon
sudo useradd -r -s /bin/false -g opmon anonymizer
```
#### Create relevant X-Road instances

##### ee-dev

```bash
sudo mkdir -p /srv/app/ee-dev/logs; sudo chown root:opmon /srv/app/ee-dev/logs; sudo chmod g+w /srv/app/ee-dev/logs
sudo mkdir -p /srv/app/ee-dev/heartbeat; sudo chown root:opmon /srv/app/ee-dev/heartbeat; sudo chmod g+w /srv/app/ee-dev/heartbeat

# Create a folder for opmon group to allow anonymizer write its settings.db file, which stores last run's timestamp
sudo mkdir -p /srv/app/ee-dev/opendata_module/anonymizer/session_data; sudo chown root:opmon /srv/app/ee-dev/opendata_module/anonymizer/session_data; sudo chmod g+w /srv/app/ee-dev/opendata_module/anonymizer/session_data

sudo cp -u -r ~/monitor/opendata_module/anonymizer /srv/app/ee-dev/opendata_module

# Copy an X-Road instance settings template.
sudo cp /srv/app/ee-dev/opendata_module/anonymizer/instance_configurations/settings_ee-dev.py /srv/app/ee-dev/opendata_module/anonymizer/settings.py
```

##### ee-test

```bash
sudo mkdir -p /srv/app/ee-test/logs; sudo chown root:opmon /srv/app/ee-test/logs; sudo chmod g+w /srv/app/ee-test/logs
sudo mkdir -p /srv/app/ee-test/heartbeat; sudo chown root:opmon /srv/app/ee-test/heartbeat; sudo chmod g+w /srv/app/ee-test/heartbeat

sudo mkdir -p /srv/app/ee-test/opendata_module/anonymizer/session_data; sudo chown root:opmon /srv/app/ee-test/opendata_module/anonymizer/session_data; sudo chmod g+w /srv/app/ee-test/opendata_module/anonymizer/session_data

sudo cp -u -r ~/monitor/opendata_module/anonymizer /srv/app/ee-test/opendata_module
sudo cp /srv/app/ee-test/opendata_module/anonymizer/instance_configurations/settings_ee-test.py /srv/app/ee-test/opendata_module/anonymizer/settings.py
```

##### xtee-ci-xm

```bash
sudo mkdir -p /srv/app/xtee-ci-xm/logs; sudo chown root:opmon /srv/app/xtee-ci-xm/logs; sudo chmod g+w /srv/app/xtee-ci-xm/logs
sudo mkdir -p /srv/app/xtee-ci-xm/heartbeat; sudo chown root:opmon /srv/app/xtee-ci-xm/heartbeat; sudo chmod g+w /srv/app/xtee-ci-xm/heartbeat

sudo mkdir -p /srv/app/xtee-ci-xm/opendata_module/anonymizer/session_data; sudo chown root:opmon /srv/app/xtee-ci-xm/opendata_module/anonymizer/session_data; sudo chmod g+w /srv/app/xtee-ci-xm/opendata_module/anonymizer/session_data

sudo cp -u -r ~/monitor/opendata_module/anonymizer /srv/app/xtee-ci-xm/opendata_module
sudo cp /srv/app/ee-test/opendata_module/anonymizer/instance_configurations/settings_ee-test.py /srv/app/xtee-ci-xm/opendata_module/anonymizer/settings.py
```

### Installing Python libraries

Anonymizer has been written with Python 3.5.2 in mind, which is the default preinstalled _python3_ version for Ubuntu 16.04.3 LTS.

Let's first get _pip3_ tool for downloading 3rd party Python libraries for _python3_.

```bash
sudo apt-get -y upgrade
sudo apt-get install -y python3-pip
```

Install dependencies:
```bash
sudo pip3 install -r ~/monitor/opendata_module/anonymizer/requirements.txt
```

## Configuration

#### Primary

To get an "off-the-shelf" version running, one has to configure only the following parameters, given that no alterations have been/will be done to MongoDB and PostgreSQL databases with respect to database and interface/postgresql module's documentation. Otherwise user, database name, and port parameters along with anonymization patterns might need tuning.

```python
mongo_db['host_address']
mongo_db['password']
postgres['host_address']
postgres['password']
```

The parameters must be tuned in the following relevant X-Road instance anonymizer settings:

```bash
sudo nano /srv/app/ee-dev/opendata_module/anonymizer/settings.py
sudo nano /srv/app/ee-test/opendata_module/anonymizer/settings.py
sudo nano /srv/app/xtee-ci-xm/opendata_module/anonymizer/settings.py
```

#### Secondary

Other fine tuning parameters appearing in *settings.py* files are explained [here](configuration_parameters.md).

#### How to alter postgres table after redefining columns

Anonymizer doesn't offer automatic data table alteration system. If the Anonymizer's field translations file is changed during the production phase, then either the new one has to be calculated from the beginning or table alteration must be issued manually.

## Scheduling anonymization sessions

Anonymizer is meant to be run on regular basis. For that we use cron.

```bash
sudo crontab -e -u anonymizer
```

Let's add a cron job for each relevant X-Road instance.

```bash
0 0 * * * /usr/bin/python3 /srv/app/ee-dev/opendata_module/anonymizer/anonymize.py
0 0 * * * /usr/bin/python3 /srv/app/ee-test/opendata_module/anonymizer/anonymize.py
0 0 * * * /usr/bin/python3 /srv/app/ee-xtee-ci-xm/opendata_module/anonymizer/anonymize.py
```

## Scaling

#### Component characteristics

Main attribute: CPUs (can anonymize in parallel, number of threads must be defined in the settings).

Upscaling (more X-Road instances): additional CPUs and RAM to run Anonymizers in parallel.
Upscaling (more services): additional CPUs and RAM to process logs faster, as evey thread gets a batch of logs to process. 

Benefits from: fast connection to MongoDB and/or PostgreSQL.
_Doesn't store any data on disk (just enough to pull the application), communicates with MongoDB and PostgreSQL_.

## Logging and heartbeat

Anonymizer reads logging configuration from [**logging.yaml**](../../opendata_module/anonymizer/logging.yaml) and writes logs to **/srv/app/{x-road-instance-name}/logs/anonymizer_{x-road-instance-name}.log**. The path can be changed from an anonymizer's *settings.py* file. By default, Anonymizer uses TimedRotatingLogHandler to store daily logs for a week at INFO level. INFO level output contains the start and end info on an anonymization session. Everything else is at ERROR level, as anonymization can't tolerate to fail at subtasks.

Anonymizer outputs heartbeat several times over a single anonymization session to **/srv/app/{x-road-instance-name}/heartbeat/anonymizer_{x-road-instance-name}.json**. This can be changed from an anonymizer's *settings.py* file. Heartbeat is in the following format:

```python
{"version": "0.0.1", "status": "alive", "name": "Anonymizer", "timestamp": "01-09-2017 13-35-35", "message": "Started anonymization session."}
```

**status:** *alive* or *dead*, depending on whether anonymization session succeeded or exited with an error.

## Test run

#### Single session

One session of anonymization (or run of `anonymize.py`) is run by issuing

```python
# anonymize.py can take optional integer argument N, which anonymizes the first N records from MongoDB.
# Expect ~N..2*N records in PostgreSQL, as MongoDB stores producer and client records together, PostgreSQL separately.
sudo -H -u anonymizer python3 /srv/app/ee-dev/opendata_module/anonymizer/anonymize.py 100

# After testing, remove the settings.db, which acts as a last processing's timestamp bookmark.
# If not removed, next call of anonymize.py will continue from the logs of which minimum timestamp is that in settings.db.
sudo rm /srv/app/ee-dev/opendata_module/anonymizer/session_data/settings.db
```

**anonymize.py** instantiates the necessary classes responsible for fetching data, anonymizing it, and writing them to PostgreSQL database. 

#### Session data

The only value which is passed between any two consecutive anonymization sessions is the previous session timestamp. It is stored in `settings.db` SQLite database. The next session processes all the data in the *clean_data* collection within the range

```bash
min(current time - 1 week, previous session time) .. current time
```

#### Created PostgreSQL tables

After the first run with new *postgres* parameters, anonymizer creates 2 tables.

* Table with name *postgres['table_name']* stores the anonymized logs.
* Table with name *postgres['table_name']_log_index* is a time-wise rotational index which is used to avoid reprocessing logs due to time window defined by *time offset*. Too old entries are removed the the beginning of every session.

## Anonymization process

1. Anonymizer requests the past 10 days records, which are "done" (corrector doesn't make any further alterations to the record).
2. Batches of `postgres['buffer_size']` records are distributed to the processing threads.
3. Each batch is run against the index to filter out the already processed records.
4. Unprocessed records (dual records with potential client and producer data) are split into individual client and producer logs.
5. Each individual log is then
	1. checked whether it should be ignored, using custom hiding rules from `settings.py`;
	2. having its individual values changed to constant values by the custom substitution rules (for example set mime sizes to 0 if represented party code is X);
	3. transformed by custom transformers (Python functions). Custom transformers can perform more complicated or "dynamic" value alterations (for example reducing timestamp precision);
	4. written to PostgreSQL database.
