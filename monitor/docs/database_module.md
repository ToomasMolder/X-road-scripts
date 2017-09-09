# X-Road project - Database Module


## About

The database module provides storage and synchronization between the other modules, namely: Collector, Corrector, Reports, OpenData, Analyzer. 
The database is implemented with the MongoDB technology: a non-SQL database with replication and sharding capabilities.


## Installation (Linux)

This document describes the installation steps for Ubuntu 14.04. For other Linux distribution, please refer to: [MongoDB 3.4 documentation](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/)


Add the MongoDB repository key and location:

```bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
```

Install MongoDB server and client tools

```bash
sudo apt-get update
sudo apt-get install -y mongodb-org
```


## Configuration

This section describes the necessary MongoDB configuration. It assumes that MongoDB is installed and running.


#### User Configuration

The database module requires the creation of the following users: 

The **root** user controls the configuration of the database.
The **dev_user** is used by other modules to access the database.


######## Configure **root** user

Enter MongoDB client and create a admin user, where ROOT_PWD should be changed with the desired database admin password.

Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **root** user in the **admin** database. Replace **ROOT_PWD** with the desired root password.

```
use admin
db.createUser( { user: "root", pwd: "ROOT_PWD", roles: ["root"] })
```

######## Enable Rotate Log Files

Enter MongoDB client tool:

```bash
mongo
```

Inside mongo client tools, execute the following command to enable log rotation.

```
use admin
db.runCommand( { logRotate : 1 } )
```


######## Configure **dev_user** user


Enter MongoDB client tool:

```bash
mongo
```

Inside the MongoDB client tool, create the **dev_user** user in the **auth_db** database. Replace **DEV_USER_PWD** with the desired root password.

```
use auth_db
db.createUser( { user: "dev_user", pwd: "DEV_USER_PWD", roles: [{ role: "dbOwner", db: "query_database" }, { role: "dbOwner", db: "collector_state" }, { role: "dbOwner", db: "analyzer_database" }, { role: "dbOwner", db: "corrector_state"}, { role: "dbOwner", db: "query_db_ee-dev"}, { role: "dbOwner", db: "query_db_ee-test"}, { role: "dbOwner", db: "query_db_xtee-ci-xm"}, { role: "readAnyDatabase", db: "admin"}, { role: "dbOwner", db: "reports_state"}]})
```


#### MongoDB Configuration


######## Enable MongoDB authentication

MongoDB default install does not enable authentication. The following steps are used to configure MongoDB security authorization.

**NOTE:** The **root** user (database **admin**) needs to exist already. See previous section.

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


######## Enable access from other machines

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


#### Network Configuration

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

To enable rotate log, please refer to the section **Enable Rotate Log Files** in this document.


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
db.clean_data.createIndex({'correctorStatus': 1})
db.clean_data.createIndex({'matchingType': 1})

db.raw_messages.createIndex({'insertTime': 1})
db.raw_messages.createIndex({'messageId': 1})
```


## Monitoring and Status

To check the database status, use the command:

```bash
sudo service mongod status
```

    
