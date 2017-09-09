# Open Data Module
# Anonymizer and PostgreSQL Node

## Installation

### Anonymizer

ODM is written in Python with 3.5.2 in mind. Although not tested, it should work with any modern Python 3.x version.

Modern Debian based distributions come with _python3_ preinstalled. Let's first get/update _pip_ tool for downloading dependencies.

```bash
sudo apt-get -y upgrade
sudo apt-get install -y python3-pip
```

Install dependencies:
```bash
sudo pip3 install -r monitor/opendata_module/anonymizer/requirements.txt
```

### PostgreSQL

#### Setting up the ODM database

Open Data Module depends on a running PostgreSQL instance. Opmon-opendata.ci.kit development server has an existing database `opendata` with user `opendata` and password `12345`.

ODM uses [PostgreSQL](https://www.postgresql.org/ "PostgreSQL") to store the anonymized data ready for public use. Current instructions are for PostgreSQL 9.3.

A database with remote connection capabilities must be set up beforehand. Relations and relevant indices will be created dyncamically during the first Anonymizer's run, according to the supplied configuration.

##### Downloading PostgreSQL 9.3

Ubuntu 14.04 has PostgreSQL 9.3 in its default apt repository.

```bash
sudo apt-get install postgresql
```

##### Creating a user and a database

Probably the easiest way to allow remote access to the database is to add a Linux user along with the matching PostgreSQL user and grant it all-privileges-access to the newly created database. We can then connect to the database using the user's credentials. The approach is inspired by [this tutorial](https://www.cyberciti.biz/faq/howto-add-postgresql-user-account/ "How to add a PostgreSQL user account").
 
Add a Linux user *opendata*.

`adduser opendata`

Switch to *postgres* user to create a database and *opendata* PostgreSQL user.

`sudo su -l postgres`

Enter PostgreSQL interactive terminal.

`psql`

Create *opendata* PostgreSQL user, *opendata* database and grant the privileges.

```
postgres=# CREATE USER opendata WITH PASSWORD '12345';
postgres=# CREATE DATABASE opendata WITH TEMPLATE template1 ENCODING 'utf8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
postgres=# GRANT ALL PRIVILEGES ON DATABASE opendata to opendata;
postgres=# \q
```

##### Allowing remote access

PostgreSQL needs remote access, since API resides on another machine (hopefully).

To allow remote access, permissions must be granted from both PostgreSQL and Linux sides.

The following configuration allows password authentication for all clients. 

To allow remote access from PostgreSQL, add the following lines to `/etc/postgresql/9.3/main/pg_hba.conf` in order to enable password authentication (md5 hash comparison) for all hosts:

```
host     all   all   0.0.0.0/0   md5
hostssl  all   all   0.0.0.0/0   md5
```

Then allow remote clients by changing or adding the following line in `/etc/postgresql/9.3/main/postgresql.conf`:

```
listen_addresses = '*'
```

##### Setting up rotational logging

To set up daily logging which stores logs for a week at default location **/var/lib/postgresql/9.3/main/pg_log**, add the following lines to `/etc/postgresql/9.3/main/postgresql.conf` 

```bash
logging_collector = on
log_filename = '%a.log'
log_truncate_on_rotation = on
log_rotation_age = 1d
```

##### Finally

Restart PostgreSQL:

`# service postgresql restart`


## Scaling

#### Component characteristics

* **Anonymizer**
	Main attribute: CPUs (can anonymize in parallel, number of threads must be defined in the settings).
	
	Upscaling (more X-Road instances): additional CPUs and RAM to run Anonymizers in parallel.
	Upscaling (more services): additional CPUs and RAM to process logs faster, as evey thread gets a batch of logs to process. 
	
	Benefits from: fast connection to MongoDB and/or PostgreSQL. Can even be on the same machine with PostgreSQL.
	_Doesn't store any data on disk (just enough to pull the application), communicates with MongoDB and PostgreSQL_.

* **PostgreSQL**
	Main attribute: disk space.
	
	Upscaling (more X-Road instances): additional disk space.
	Upscaling (more services): additional disk space and RAM to handle more daily logs
	Upscaling (more end users): additional RAM and CPUs for more simultaneous queries.
	Upscaling (over time): additional disk space to store more logs.
	
	Benefits from: decent disk I/O speed (fast HDD or SSD, preferably), fast connection to Anonymizer and Interface components.

## Networking

Port 5432 must be open for PostgreSQL.

```bash
sudo apt-get install ufw
sudo ufw enable
sudo ufw allow 22
sudo ufw allow 5432/tcp
```

## Logging and heartbeat

#### Anonymizer

Anonymizer reads logging configuration from [**logging.yaml**](../../opendata_module/anonymizer/logging.yaml) and writes logs to **monitor/opendata_module/anonymizer/logs/anonymizer.log**. By default, it uses TimedRotatingLogHandler to store daily logs for a week at INFO level. INFO level output contains the start and end info on an anonymization session. Everything else is at ERROR level, as anonymization can't tolerate to fail at subtasks.

Anonymizer outputs heartbeat after every anonymization session to **monitor/opendata_module/anonymizer/heartbeat.json**. Heartbeat is with the following format:

```python
{"version": "0.0.1", "mongodb": true, "name": "Anonymizer", "timestamp": "01-09-2017 13-35-35", "succeeded": true, "postgres": true}
```

**mongodb:** indicates whether MongoDB was accessible at run time with the provided configuration.
**postgres:** indicates whether PostgreSQL database was accessible.
**succeeded**: true only if no errors occured and both databases were accessible.

## Configuration

#### How to alter postgres table after redefining columns

Anonymizer doesn't offer automatic data table alteration system. If the Anonymizer's field translations file is changed during the production phase, then either the new one has to be calculated from the beginning or table alteration must be issued manually.
