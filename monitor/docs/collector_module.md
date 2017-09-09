# X-Road project - Collector Module


## About

The collector module is responsible to retrieve data from servers and insert into the database module. The execution of the collector module is performed automatically via a **cron job** task.


## Installation (Linux)

This sections describes the necessary steps to install the **collector module** in a Linux Ubuntu 14.04. To a complete overview of different modules and machines, please refer to the [System Architecture](system_architecture.md) documentation.

#### Install required packages

To install the necessary packages, execute the following commands:

```bash
sudo apt-get update
sudo apt-get install python3-pip
sudo pip3 install pymongo==3.4
sudo pip3 install requests==2.13
sudo pip3 install numpy==1.11
```


#### Install collector module

Create the collector user. With the root user, execute:

```
adduser collector 
```

Create the **app** directory, and copy the collector code to it:

```bash
mkdir /app
mkdir /app/logs
cp -r collector_module /app
```

Configure folder permissions to **collector** user:

```bash
chown -R collector:collector /app
```

Add **collector module** as a **cron job** to the **collector** user.

```bash
sudo su collector
crontab -e
```

The **cron job** entry (execute every 3 hours, note that a different value might be needed in production)

```
0 */3 * * * /app/collector_module/cron_collector.sh update
```

Make sure the collector script has execution rights as the **collector** user:

```bash
chmod +x /app/collector_module/cron_collector.sh
```


## Configuration

The collector module can be configured via the settings file at:

```
/app/collector_module/settings.py
```


## Networking

#### Outgoing:

The collector module needs access to the servers the data is collected (via CENTRALSERVER) and the Database Module (see [Database_Module](database_module.md)).

#### Incoming: 

No **incoming** connection is needed in the collector module.


## Monitoring and Status

To check if the **collector module** is properly installed in the **collector** user, execute:

```bash
sudo su collector
crontab -l
```

This will list all entries in the crontab from **collector** user. You can execute the entries manually to check if all configuration and paths are set correctly.

#### Logging 

The **collector module** produces log files that, by default, is stored at:

```
/app/logs
```
