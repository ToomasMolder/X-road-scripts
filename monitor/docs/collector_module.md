# X-Road v6 monitor project - Collector Module

## About

The collector module is part of [X-Road v6 monitor project](../readme.md), which includes modules of [Database module](database_module.md), [Collector module (this document)](collector_module.md), [Corrector module](corrector_module.md), [Analysis module](analysis_module.md), [Reports module](reports_module.md) and [Opendata module](opendata_module.md).

Overall system, its users and rights, processes and directories are designed in a way, that all modules can reside in one server and also in separate servers. 

Overall system is also designed in a way, that allows to monitor data from different X-Road v6 instances (ee-dev, ee-test, EE), see also [X-Road v6 environments](https://www.ria.ee/en/x-road-environments.html#v6).

Overall system is also designed in a way, that can be used by X-Road Centre for all X-Road members as well as for Member own monitoring (includes possibilities to monitor also members data exchange partners).

The **collector module** is responsible to retrieve data from X-Road v6 security servers and insert into the database module. The execution of the collector module is performed automatically via a **cron job** task.

The module source code can be found at:

```
https://stash.ria.ee/projects/XTEE6/repos/monitor/browse
```

and can be downloaded into server:

```bash
# NB! git clone required only once
cd ~; git clone https://stash.ria.ee/scm/xtee6/monitor.git
mkdir -p ~/monitor; cd ~/monitor; git pull https://stash.ria.ee/scm/xtee6/monitor.git
```

## Installation

This sections describes the necessary steps to install the **collector module** in a Linux Ubuntu 16.04. To a complete overview of different modules and machines, please refer to the [System Architecture](system_architecture.md) documentation.

## Networking

### Outgoing:

- The collector module needs http-access to the X-Road CENTRALSERVER to get from global configuration list of members security servers.
- The collector module needs http-access to the current member SECURITY SERVER to get the data is collected.
- The collector module needs access to the Database Module (see [Database_Module](database_module.md)).

### Incoming: 

No incoming connection is needed in the collector module.

### Install required packages

To install the necessary packages, execute the following commands:

```bash
sudo apt-get update
sudo apt-get install python3-pip
sudo pip3 install pymongo==3.4
sudo pip3 install requests==2.13
sudo pip3 install numpy==1.11
sudo pip3 install tqdm==4.14
```

### Install collector module

The collector module uses the system user **collector** and group **opmon**. To create them, execute:

```bash
sudo groupadd -f opmon
sudo useradd -M -r -s /bin/false -g opmon collector
```

The module files should be installed in the **/srv/app** directory, within a sub-folder named after the desired X-Road instance. In this manual, the "ee-dev" is used (please change "ee-dev" to map your desired instance, example: "ee-test", "EE").

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

Copy the **collector** code to the install folder and fix the file permissions:

```bash
sudo rsync -r -t -u ~/monitor/collector_module /srv/app/ee-dev
# or 
# sudo cp -u -r ~/monitor/collector_module /srv/app/ee-dev
sudo chown -R collector:opmon /srv/app/ee-dev/collector_module
sudo chmod -R -x+X /srv/app/ee-dev/collector_module
sudo chmod +x /srv/app/ee-dev/collector_module/*.sh
```

Settings for different X-Road instances have been prepared and can be used:

```bash
sudo rm /srv/app/ee-dev/collector_module/settings.py
sudo ln -s /srv/app/ee-dev/collector_module/settings_ee-dev.py /srv/app/ee-dev/collector_module/settings.py
```

If needed, edit necessary modifications to the settings file using your favorite text editor (here, **vi** is used):

```bash
sudo vi /srv/app/ee-dev/collector_module/settings.py
```

To check collector manually as collector user, execute:

```bash
cd /srv/app/ee-dev/; sudo -u collector ./collector_module/cron_collector.sh update
```

Add **collector module** as a **cron job** to the **collector** user.

```bash
sudo crontab -e -u collector
```

The **cron job** entry (execute every 3 hours, note that a different value might be needed in production)

```
0 */3 * * * cd /srv/app/ee-dev/; ./collector_module/cron_collector.sh update
```

To check if the collector module is properly installed in the collector user, execute:

```bash
sudo crontab -l -u collector
```

### Logging 

The **collector module** produces log files that, by default, is stored at:

```
/srv/app/ee-dev/logs
```

The heartbeat files are written to:

```
/srv/app/ee-dev/heartbeat
```

## Appendix

NB! Mentioned appendixes do not log their work and do not keep heartbeat.

### Collecting JSON queries and store into HDD

Collecting JSON queries and store into HDD was not part of the project scope. Nevertheless, sample script can be found from [getSecurityServerOperationalData](https://github.com/ToomasMolder/X-road-scripts/tree/master/getSecurityServerOperationalData).

### Collecting JSON queries from HDD

It is possible to collect JSON queries from HDD and send it to MongoDB using the command "collector_from_file", as in:

```bash
cd /srv/app/ee-dev/collector_module/; 
sudo -u collector /usr/bin/python3 collector_from_file.py 'temp_files/ee-dev.COM.*'
```

---

![](img/eu_regional_development_fund_horizontal_div_15.png "European Union | European Regional Development Fund | Investing in your future")
