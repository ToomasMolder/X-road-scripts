# X-Road v6 monitor project - Database Module


## About

The database module provides storage and synchronization between the other modules, namely: Collector, Corrector, Reports, OpenData, Analyzer. 
The database is implemented with the MongoDB technology: a non-SQL database with replication and sharding capabilities.

## Installation (Linux)

This document describes the installation steps for Ubuntu 16.04. For other Linux distribution, please refer to: [MongoDB 3.4 documentation](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/)

Add the MongoDB repository key and location:

```bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
```

Install MongoDB server and client tools

```bash
sudo apt-get update
sudo apt-get install -y mongodb-org
```

## Configuration

This section describes the necessary MongoDB configuration. It assumes that MongoDB is installed and running.

To check if the MongoDB daemon is active, run:

```bash
sudo service mongod status
```

To start MongoDB daemon, run:

```bash
sudo service mongod start
```

To ensure that MongoDB daemon start is enabled after system start, run and check, that `/lib/systemd/system/mongod.service; enabled` is present:

```bash
sudo service mongod status
# Loaded: loaded (/lib/systemd/system/mongod.service; disabled; ...)
```

If not, then enable and restart MongoDB daemon:

```bash
sudo systemctl enable mongod.service
# Created symlink from /etc/systemd/system/multi-user.target.wants/mongod.service to /lib/systemd/system/mongod.service.
sudo service mongod restart
sudo service mongod status
# Loaded: loaded (/lib/systemd/system/mongod.service; enabled; ...)
```

### User Configuration

The database module requires the creation of the following users: 

* A **root** user to controls the configuration of the database.
* A backup specific user to backup data collections.
* Module specific users, to provide access and limit permissions.

The instructions below describes the creation of module users for **collector**, **corrector**, **reports**, **analyzer**, and **anonymizer** modules.

* Note 1: The instructions assume "ee-dev" instances. For other instances replace the "ee-dev" suffix appropriately (example: "xtee-ci-xm", "ee-test", "EE"). 

* Note 2: Please refer to the specific configuration file of every module and set the MongoDB access to match the user and passwords created here, where:

- INSTANCE: is the X-Road v6 instance
- MONGODB_USER: is the instance-specific module user
- MONGODB_PWD: is the MONGODB_USER password 
- MONGODB_SERVER: is the database host (example: "opmon.ci.kit")
- MONGODB_SUFFIX: is the database suffix, same as INSTANCE (example: 'ee-dev')

#### Configure **root** user:

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **root** user in the **admin** database. 
Replace **ROOT_PWD** with the desired root password (keep ROOT_PWD in your password safe).

```
use admin
db.createUser( { user: "root", pwd: "ROOT_PWD", roles: ["root"] })
```

#### Configure **backup** user:

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **db_backup** user in the **admin** database. 
Replace **BACKUP_PWD** with the desired password.

```
use admin
db.createUser( { user: "db_backup", pwd: "BACKUP_PWD", roles: ["backup"] })
```

#### Configure **collector** module user:

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **collector_ee-dev** user in the **auth_db** database. 
Replace **MODULE_PWD** with the desired module password. 
The collector user has "readWrite" permissions to "query_db" and "collector_state" databases (here, **query_db_ee-dev** and **collector_state_ee-dev**)

```
use auth_db
db.createUser( { user: "collector_ee-dev", pwd: "MODULE_PWD", roles: []})
db.grantRolesToUser( "collector_ee-dev", [{ role: "readWrite", db: "query_db_ee-dev"}])
db.grantRolesToUser( "collector_ee-dev", [{ role: "readWrite", db: "collector_state_ee-dev"}])
```

#### Configure **corrector** module user:

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **corrector_ee-dev** user in the **auth_db** database. 
Replace **MODULE_PWD** with the desired module password.
The corrector user has "readWrite" permissions to "query_db" and "corrector_state" databases (here, **query_db_ee-dev** and **corrector_state_ee-dev**)

```
use auth_db
db.createUser( { user: "corrector_ee-dev", pwd: "MODULE_PWD", roles: []})
db.grantRolesToUser( "corrector_ee-dev", [{ role: "readWrite", db: "query_db_ee-dev"}])
db.grantRolesToUser( "corrector_ee-dev", [{ role: "readWrite", db: "corrector_state_ee-dev"}])
```

#### Configure **reports** module user:

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **reports_ee-dev** user in the **auth_db** database. 
Replace **MODULE_PWD** with the desired module password.
The reports user has "read" permissions to "query_db" database and "readWrite" permission to "reports_state" database (here, **query_db_ee-dev** and **reports_state_ee-dev**)

```
use auth_db
db.createUser({ user: "reports_ee-dev", pwd: "MODULE_PWD", roles: [] })
db.grantRolesToUser( "reports_ee-dev", [{ role: "read", db: "query_db_ee-dev" }])
db.grantRolesToUser( "reports_ee-dev", [{ role: "readWrite", db: "reports_state_ee-dev" }])
```

#### Configure **analyzer** module user:

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **analyzer_ee-dev** user in the **auth_db** database. 
Replace **MODULE_PWD** with the desired module password.
The analyzer user has "read" permissions to "query_db" database and "readWrite" permission to "analyzer_database" database (here, **query_db_ee-dev** and **analyzer_database_ee-dev**)


```
use auth_db
db.createUser({ user: "analyzer_ee-dev", pwd: "MODULE_PWD", roles: [] })
db.grantRolesToUser( "analyzer_ee-dev", [{ role: "read", db: "query_db_ee-dev" }])
db.grantRolesToUser( "analyzer_ee-dev", [{ role: "readWrite", db: "analyzer_database_ee-dev" }])
```

#### Configure **anonymizer** module user:

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **anonymizer_ee-dev** user in the **auth_db** database. 
Replace **MODULE_PWD** with the desired module password.
The anonymizer user has "read" permissions to "query_db" database (here, **query_db_ee-dev**)

```
use auth_db
db.createUser({ user: "anonymizer_ee-dev", pwd: "MODULE_PWD", roles: [] })
db.grantRolesToUser( "anonymizer_ee-dev", [{ role: "read", db: "query_db_ee-dev" }])
```

#### Check user configuration and permissions

To check if all users and configurations were properly created, list all users and verify their roles using the following commands:

##### Check **root** and **db_backup**

From mongo client tools:

```
use admin
db.getUsers()
```

##### Check **collector**, **corrector**, **reports**, **analyzer**, **anonymizer**

From mongo client tools:

```
use auth_db
db.getUsers()
```

### MongoDB Configuration

#### Enable Rotate Log Files

Enter MongoDB client tool:

```bash
mongo
```

Inside mongo client tools, execute the following command to enable log rotation.

```
use admin
db.runCommand( { logRotate : 1 } )
```

#### Enable MongoDB authentication

MongoDB default install does not enable authentication. The following steps are used to configure MongoDB security authorization.

**NOTE:** The **root** user (database **admin**) needs to exist already. See section 'Configure **root** user'.

To enable MongoDB security authorization, edit the **mongod.conf** configuration file using your favorite text editor (here, **vim** is used).

```bash
sudo vim /etc/mongod.conf
```

Change the following line in the configuration file:

```
security:
    authorization: enabled
```

After saving the alterations, the MongoDB service needs to be restarted. This can can be performed with the following command:

```bash
sudo service mongod restart
```

* NOTE: After enabling authentication it will be needed to specify database, user and password when connecting to mongo client tools. For example:

```bash
mongo admin -u root -p
# or
mongo auth_db -u collector_ee_dev -p
```

#### Enable access from other machines

To make MongoDB services available in the modules network (see System Architecture)[system_architecture.md], the following configuration is necessary:

Open MongoDB configuration file in your favorite text editor (here, **vim** is used)

```bash
sudo vim /etc/mongod.conf
```

Add the external IP (the IP seen by other modules in the network) to enable the IP biding. In this example, the machine running MongoDB (opmon.ci.kit) has the Ethernet IP 10.0.24.35, and therefore, the following line is edited in the configuration file:

```
bindIp: 127.0.0.1,10.0.24.35
```

After saving the alterations, the MongoDB service needs to be restarted. This can can be performed with the following command:

```bash
sudo service mongod restart
```

### Network Configuration

The MongoDB interface is exposed by default in the port **27017**
Make sure the port is allowed in the firewall configuration.

### Log Configuration

The default MongoDB install uses the following folders to store data and logs:

Data folder:

```
/var/lib/mongodb
```

Log files:

```
/var/log/mongodb
```

## Database Structure

#### MongoDB Structure: databases, collections

#### Index Creation

The example here uses the database "query_db_ee-dev", and the same procedure should be used to additional databases (example: query_db_ee-test and query_db_xtee-ci-xm) 

Enter MongoDB client as root:

```bash
mongo admin -u root -p 
```

Inside MongoDB client shell, execute the following commands:

```
use query_db_ee-dev

db.clean_data.createIndex({'client.clientMemberCode': 1})
db.clean_data.createIndex({'client.clientSubsystemCode': 1})
db.clean_data.createIndex({'client.monitoringDataTs': 1})
db.clean_data.createIndex({'client.requestInTs': 1})
db.clean_data.createIndex({'client.serviceMemberCode': 1})
db.clean_data.createIndex({'client.serviceSubsystemCode': 1})
db.clean_data.createIndex({'clientHash': 1})
db.clean_data.createIndex({'correctorStatus': 1})
db.clean_data.createIndex({'correctorTime': 1})
db.clean_data.createIndex({'messageId': 1})
db.clean_data.createIndex({'producer.clientMemberCode': 1})
db.clean_data.createIndex({'producer.clientSubsystemCode': 1})
db.clean_data.createIndex({'producer.monitoringDataTs': 1})
db.clean_data.createIndex({'producer.requestInTs': 1})
db.clean_data.createIndex({'producer.serviceMemberCode': 1})
db.clean_data.createIndex({'producer.serviceSubsystemCode': 1})
db.clean_data.createIndex({'producerHash': 1})
db.clean_data.createIndex({'matchingType': 1})

db.raw_messages.createIndex({'insertTime': 1})
db.raw_messages.createIndex({'messageId': 1})
```

## Monitoring and Status

MongoDB runs as a daemon process. It is possible to stop, start and restart the database with the following commands:

* Check stop
```bash
sudo service mongod stop
```

* Check start
```bash
sudo service mongod start
```

* Check restart
```bash
sudo service mongod restart
```

* Check status
```bash
sudo service mongod status
```

It is also possible to monitor MongoDB with a GUI interface using the MongoDB Compass. For specific instructions, please refer to:

```
https://www.mongodb.com/products/compass
```

and for a complete list of MongoDB monitoring tools, please refer to:

```
https://docs.mongodb.com/master/administration/monitoring/
```

## Database backup

To perform backup of database, it is recommended to use the mongodb tools **mongodump** and **mongorestore** 

For example, to perform a complete database backup, execute:

```
mongodump -u db_backup -p BACKUP_PWD --gzip --authenticationDatabase admin --out=MDB_BKPFILE
```

where BACKUP_PWD is password for backup user set in paragraph 'Configure **backup** user' and 
MDB_BKPFILE is output directory for backup.

For additional details and recommendations, please check:

```
https://docs.mongodb.com/manual/tutorial/backup-and-restore-tools/
```

---

![](img/eu_regional_development_fund_horizontal_div_15.png "European Union | European Regional Development Fund | Investing in your future")
