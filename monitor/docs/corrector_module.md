# X-Road project - Corrector Module

## About

The corrector module is responsible to clean the raw data from corrector and derive monitoring metrics in a clean database collection. The execution of the corrector module is performed automatically via a **cron job** task.


## Installation (Linux)

This sections describes the necessary steps to install the **corrector module** in a Linux Ubuntu 14.04. To a complete overview of different modules and machines, please refer to the [System Architecture](system_architecture.md) documentation.

#### Install required packages

To install the necessary packages, execute the following commands:

```bash
sudo apt-get install python3-pip
sudo pip3 install pymongo==3.4.0
```


#### Install corrector module

Create the corrector user. With the root user, execute:

```
adduser corrector 
```

Create the **app** directory, and copy the corrector code to it:

```bash
mkdir /app
mkdir /app/logs
cp -r corrector_module /app
```

Configure folder permissions to **corrector** user:

```bash
chown -R corrector:corrector /app
```

Add **corrector module** as a **cron job** to the **corrector** user.

```bash
sudo su corrector
crontab -e
```

The **cron job** entry (execute every 30 minutes, note that a different value might be needed in production)

```
*/30 * * * * /app/corrector_module/cron_corrector.sh
```

Make sure the corrector script has execution rights as the **corrector** user:

```bash
chmod +x /app/corrector_module/cron_corrector.sh
```


## Configuration

The corrector module can be configured via the settings file at:

```
/app/corrector_module/settings.py
```


## Networking

#### Outgoing:

The corrector module needs access to the Database Module (see [Database_Module](database_module.md)).

#### Incoming: 

No **incoming** connection is needed in the corrector module.


## Monitoring and Status

To check if the **corrector module** is properly installed in the **corrector** user, execute:

```bash
sudo su corrector
crontab -l
```

This will list all entries in the crontab from **corrector** user. You can execute the entries manually to check if all configuration and paths are set correctly.

#### Logging 

The **corrector module** produces log files that, by default, is stored at:

```
/app/logs
```
