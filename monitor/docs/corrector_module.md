# X-Road v6 monitor project - Corrector Module

## About

The corrector module is part of [X-Road v6 monitor project](../readme.md), which includes modules of [Database module](database_module.md), [Collector module](collector_module.md), [Corrector module (this document)](corrector_module.md), [Analysis module](analysis_module.md), [Reports module](reports_module.md) and [Opendata module](opendata_module.md).

Overall system, its users and rights, processes and directories are designed in a way, that all modules can reside in one server and also in separate servers. 

Overall system is also designed in a way, that allows to monitor data from different X-Road v6 instances (ee-dev, ee-test, EE), see also [X-Road v6 environments](https://www.ria.ee/en/x-road-environments.html#v6).

Overall system is also designed in a way, that can be used by X-Road Centre for all X-Road members as well as for Member own monitoring (includes possibilities to monitor also members data exchange partners).

The **corrector module** is responsible to clean the raw data from corrector and derive monitoring metrics in a clean database collection. The execution of the corrector module is performed automatically via a **cron job** task.

The module source code can be found at (ACL-protected):

```
https://stash.ria.ee/projects/XTEE6/repos/monitor/browse
```

and can be downloaded into server (ACL-protected):

```bash
# NB! git clone required only once
cd ~; git clone https://stash.ria.ee/scm/xtee6/monitor.git
mkdir -p ~/monitor; cd ~/monitor; git pull https://stash.ria.ee/scm/xtee6/monitor.git
```

## Networking

### Outgoing

The corrector module needs access to the Database Module (see [Database_Module](database_module.md)).

### Incoming

No **incoming** connection is needed in the corrector module.

## Installation

This sections describes the necessary steps to install the **corrector module** in a Linux Ubuntu 16.04. To a complete overview of different modules and machines, please refer to the [System Architecture](system_architecture.md) documentation.

### Install required packages

To install the necessary packages, execute the following commands:

```bash
sudo apt-get install python3-pip
sudo pip3 install pymongo==3.4.0
```

### Install corrector module

The corrector module uses the system user **corrector** and group **opmon**. To create them, execute:

```bash
sudo groupadd -f opmon
sudo useradd -M -r -s /bin/false -g opmon corrector
```

The module files should be installed in the **/app/srv** directory, within a sub-folder named after the desired X-Road instance. In this manual, the "ee-dev" is used (please change "ee-dev" to map your desired instance, example: "ee-test", "EE")

```bash
# make necessary directories
sudo mkdir -p /srv/app/ee-dev
sudo mkdir -p /srv/app/ee-dev/logs
sudo mkdir -p /srv/app/ee-dev/heartbeat
# correct necessary permissions
sudo chown root:opmon /srv/app/ee-dev/logs
sudo chmod g+w /srv/app/ee-dev/logs
sudo chown root:opmon /srv/app/ee-dev/heartbeat
sudo chmod g+w /srv/app/ee-dev/heartbeat
```

Copy the **corrector** code to the install folder and fix the file permissions:

```bash
sudo rsync -r -t -u ~/monitor/corrector_module /srv/app/ee-dev
# or 
# sudo cp -u -r ~/monitor/corrector_module /srv/app/ee-dev
sudo chown -R corrector:opmon /srv/app/ee-dev/corrector_module
sudo chmod -R -x+X /srv/app/ee-dev/corrector_module
sudo chmod +x /srv/app/ee-dev/corrector_module/*.sh
```

Settings for different X-Road instances have been prepared and can be used:

```bash
sudo rm /srv/app/ee-dev/corrector_module/settings.py
sudo ln -s /srv/app/ee-dev/corrector_module/settings_ee-dev.py /srv/app/ee-dev/corrctor_module/settings.py
```

If needed, edit necessary modifications to the settings file using your favorite text editor (here, **vi** is used):

```bash
sudo vi /srv/app/ee-dev/corrector_module/settings.py
```

## Manual usage

To check commands manually as corrector user, execute:

```bash
cd /srv/app/ee-dev/corrector_module/ ; sudo -u corrector ./cron_corrector.sh
```

## CRON usage

Add **corrector module** as a **cron job** to the **corrector** user.

```bash
sudo crontab -e -u corrector
```

The **cron job** entry (execute every 30 minutes, note that a different value might be needed in production)

```
*/30 * * * * cd /srv/app/ee-dev/corrector_module/ ; ./cron_corrector.sh
```

## TODO

Corrector has current limit in settings `CORRECTOR_DOCUMENTS_LIMIT = 11000` within one run to ensure RAM and CPU is not overloaded during calculations.
At same time, we have to ensure, that all collected documents are processed within given timeframe (please refer to the [System Architecture](system_architecture.md) and [Collector](collector_module.md) documentation for more background). 
To prevent many parallel processes and avoid system locking, it is suggested to implement some locking mechanism or configure corrector as a service.

## Monitoring and Status

### Logging 

The **corrector module** produces log files that, by default, is stored at:

```
/srv/app/ee-dev/logs
```

To change the logging level, it is necessary to change the logger.setLevel parameter in the settings file:
```
# INFO - logs INFO & WARNING & ERROR
# WARNING - logs WARNING & ERROR
# ERROR - logs ERROR
logger.setLevel(logging.INFO)
```

### Heartbeat

The Corrector module has a heartbeat.json file, by default, is stored at:

```
/srv/app/ee-dev/heartbeat
```

The heartbeat file consist of the following fields:

```
timestamp - the timestamp when the heartbeat was updated
module - module name
msg - message
version - version
```

The settings (in the settings file) for the heartbeat file are the following:

```
# --------------------------------------------------------
# Configure heartbeat
# --------------------------------------------------------
HEARTBEAT_NAME = 'heartbeat_corrector_{0}'.format(MONGODB_SUFFIX)
HEARTBEAT_LOGGER_PATH = '/srv/app/ee-dev/heartbeat'
```
So, for each XRoadInstance a separate heartbeat will be generated.
The statuses used for Corrector module in the heartbeat are the following:
```
"Starting Corrector"
"Processing documents"
"Updating orphans"
"Corrector finished"
```

## Appendix

NB! Mentioned appendixes do not log their work and do not keep heartbeat.

### Purge duplicated records from MongoDB raw data collection

TODO. To keep MongoDB size under control.

### Purge records from MongoDB raw data collection after available in clean_data

TODO. To keep MongoDB size under control.


---

![](img/eu_regional_development_fund_horizontal_div_15.png "European Union | European Regional Development Fund | Investing in your future")
