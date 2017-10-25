# X-Road v6 monitor project - Collector Module

## About

The collector module is part of [X-Road v6 monitor project](../readme.md), which includes modules of [Database module](database_module.md), Collector module (this document), [Corrector module](corrector_module.md), [Analysis module](analysis_module.md), [Reports module](reports_module.md) and [Opendata module](opendata_module.md).

Overall system, its users and rights, processes and directories are designed in a way, that all modules can reside in one server (different users but in same group) and also in separate servers. 

Overall system is also designed in a way, that allows to monitor data from different X-Road v6 instances (`ee-dev`, `ee-test`, `EE`), see also [X-Road v6 environments](https://www.ria.ee/en/x-road-environments.html#v6).

Overall system is also designed in a way, that can be used by X-Road Centre for all X-Road members as well as for Member own monitoring (includes possibilities to monitor also members data exchange partners).

The **collector module** is responsible to retrieve data from X-Road v6 security servers and insert into the database module. The execution of the collector module is performed automatically via a **cron job** task.

The module source code can be found at (ACL-protected):

```
https://stash.ria.ee/projects/XTEE6/repos/monitor/browse
```

and can be downloaded into server (ACL-protected):

```bash
export TMPDIR="/tmp" ; mkdir --parents ${TMPDIR}; cd ${TMPDIR}
# NB! git clone required only once
git clone https://stash.ria.ee/scm/xtee6/monitor.git
# when want just to refresh existing repository, use pull
cd ${TMPDIR}/monitor; git pull https://stash.ria.ee/scm/xtee6/monitor.git
```

## Installation

This sections describes the necessary steps to install the **collector module** in a Linux Ubuntu 16.04. To a complete overview of different modules and machines, please refer to the [System Architecture](system_architecture.md) documentation.

## Networking

### Outgoing

- The collector module needs http-access to the X-Road CENTRALSERVER to get from global configuration list of members security servers.
- The collector module needs http-access to the current member SECURITY SERVER to get the data is collected.
- The collector module needs access to the Database Module (see [Database_Module](database_module.md)).

### Incoming

No incoming connection is needed in the collector module.

## Install required packages

To install the necessary packages, execute the following commands:

```bash
sudo apt-get update
sudo apt-get install python3-pip
sudo pip3 install pymongo==3.4
sudo pip3 install requests==2.13
sudo pip3 install numpy==1.11
sudo pip3 install tqdm==4.14
```

## Install collector module

The collector module uses the system user **collector** and group **opmon**. To create them, execute:

```bash
sudo groupadd --force opmon
sudo useradd --base-dir /opt -M --system --shell /bin/false --gid opmon collector
```

The module files should be installed in the APPDIR directory, within a sub-folder named after the desired X-Road instance. 
In this manual, `/srv/app` is used as APPDIR and the `ee-dev` is used as INSTANCE (please change `ee-dev` to map your desired instance, example: `ee-test`, `EE`).

```bash
export APPDIR="/srv/app"
export INSTANCE="ee-dev"
# make necessary directories
sudo mkdir --parents ${APPDIR}/${INSTANCE}
sudo mkdir --parents ${APPDIR}/${INSTANCE}/logs
sudo mkdir --parents ${APPDIR}/${INSTANCE}/heartbeat
# correct necessary permissions
sudo chown root:opmon ${APPDIR}/${INSTANCE}/logs
sudo chmod g+w ${APPDIR}/${INSTANCE}/logs
sudo chown root:opmon ${APPDIR}/${INSTANCE}/heartbeat
sudo chmod g+w ${APPDIR}/${INSTANCE}/heartbeat
```

Copy the **collector** code to the install folder and fix the file permissions:

```bash
# export TMPDIR="/tmp"; export APPDIR="/srv/app"; export INSTANCE="ee-dev"
sudo rsync --recursive --update --times ${TMPDIR}/monitor/collector_module ${APPDIR}/${INSTANCE}
# or 
# sudo cp --recursive --update ${TMPDIR}/monitor/collector_module ${APPDIR}/${INSTANCE}
```

Settings for different X-Road instances have been prepared and can be used:

```bash
# export APPDIR="/srv/app"; export INSTANCE="ee-dev"
sudo rm ${APPDIR}/${INSTANCE}/collector_module/settings.py
sudo ln --symbolic ${APPDIR}/${INSTANCE}/collector_module/settings_${INSTANCE}.py ${APPDIR}/${INSTANCE}/collector_module/settings.py
```

If needed, edit necessary modifications to the settings file using your favorite text editor (here, **vi** is used):

```bash
# export APPDIR="/srv/app"; export INSTANCE="ee-dev"
sudo vi ${APPDIR}/${INSTANCE}/collector_module/settings.py
```

Correct necessary permissions

```bash
# export APPDIR="/srv/app"; export INSTANCE="ee-dev"
sudo chown --recursive collector:opmon ${APPDIR}/${INSTANCE}/collector_module
sudo chmod --recursive -x+X ${APPDIR}/${INSTANCE}/collector_module
sudo chmod +x ${APPDIR}/${INSTANCE}/collector_module/*.sh
```

## Manual usage

To check collector manually as collector user, execute:

```bash
# export APPDIR="/srv/app"; export INSTANCE="ee-dev"
cd ${APPDIR}/${INSTANCE}
sudo --user collector ./collector_module/cron_collector.sh update
```

## CRON usage

Add **collector module** as a **cron job** to the **collector** user.

```bash
sudo crontab -e -u collector
```

The **cron job** entry (execute every 3 hours, note that a different value might be needed in production)

```
0 */3 * * * export APPDIR="/srv/app"; export INSTANCE="ee-dev"; cd ${APPDIR}/${INSTANCE}; ./collector_module/cron_collector.sh update
```

To check if the collector module is properly installed in the collector user, execute:

```bash
sudo crontab -l -u collector
```

## Monitoring and Status

### Logging 

The **collector module** produces log files that, by default, is stored at `${APPDIR}/${INSTANCE}/logs`.

The time format for durations in the log files is the following: "HH:MM:SS".
For example:

```
"Finished process. Processing time: 00:02:56"
```

### Heartbeat

The heartbeat files are written to `${APPDIR}/${INSTANCE}/heartbeat`.

## Appendix

NB! Mentioned appendixes below do not log their work and do not keep heartbeat.

### Collecting JSON queries and store into HDD

Collecting JSON queries and store into HDD was not part of the project scope. Nevertheless, sample script can be found from [getSecurityServerOperationalData](https://github.com/ToomasMolder/X-road-scripts/tree/master/getSecurityServerOperationalData).

### Collecting JSON queries from HDD

It is possible to collect JSON queries from HDD and send it to MongoDB using the command "collector_from_file", as in:

```bash
# export TMPDIR="/tmp"; export APPDIR="/srv/app"; export INSTANCE="ee-dev"
sudo mkdir --parents ${APPDIR}/${INSTANCE}/mongodb_scripts
sudo rsync --recursive --update --times ${TMPDIR}/monitor/mongodb_scripts/collector_from_file.py \
    ${APPDIR}/${INSTANCE}/mongodb_scripts
# correct necessary permissions
sudo chown --recursive collector:opmon ${APPDIR}/${INSTANCE}/mongodb_scripts
sudo chmod --recursive -x+X ${APPDIR}/${INSTANCE}/mongodb_scripts
#
# collector_from_file.py parameters:
#   query_db_${INSTANCE} - MongoDB database of logs
#   collector_${INSTANCE} - MongoDB user with write access to database
#   "${TMPDIR}/${INSTANCE}.*.*.log" - temporary files with logs, Collecting JSON queries and store into HDD
#   --auth auth_db - MongoDB authentication database for user
#   --host opmon:27017 - MongoDB host and access port
#
# NB! total number of lines in files "${TMPDIR}/${INSTANCE}.*.*.log" is suggested to be limited with 
#   100 000 lines per 1Gb RAM available
# 
sudo --user collector /usr/bin/python3 \
    ${APPDIR}/${INSTANCE}/mongodb_scripts/collector_from_file.py \
    query_db_${INSTANCE} collector_${INSTANCE} "${TMPDIR}/${INSTANCE}.*.*.log" --auth auth_db --host opmon:27017
```

---

![](img/eu_regional_development_fund_horizontal_div_15.png "European Union | European Regional Development Fund | Investing in your future")

