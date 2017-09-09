# X-Road project - System Architecture

The system is distributed over 7 servers, organized as follows:

* Database Module (MongoDB)
* Collector Module
* Corrector Module
* Reports Module
* Analyzer Module
* Open Data Module (on 2 servers)

![system diagram](img/system_overview.png "System overview")


The following sections describes each of these modules.

#### Operational specifications

* MongoDB shall retain 1 year data in disk memory
* MongoDB shall retain 1 week data in RAM memory for efficient query
* MongoDB shall run in a replication set for availability
* PostgreSQL shall retain 1 year of public available data.

* Corrector: runs every 6h, use recent data in MongoDB
* Analyzer: runs every day, uses MongoDB and local cache in disk
* Report creator: runs every day, uses MongoDB, stores reports in disk
* Open Data Module: runs every day, uses MongoDB recent data, uses PostgreSQL as main database.


#### Database Module

The Database Module is responsible to store queries data using MongoDB. 
It uses the following configuration:

######## Description

```
Host: opmon.ci.kit
Code snapshot: /app/x_road_project
System User: opmon
```

######## Hardware Specification

```
* 64 GB RAM per Node
* 3 TB storage (RAID-0 or RAID-10)
* Minimum 1 Node, Recommended 3 Nodes for redundancy
* Scalability: Addition of Nodes (8 nodes to support 1 week data in RAM in 2021)
```

######## Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
* MongoDB 3.4
```


#### Collector Module

The Collector Module is responsible for querying servers and storing the data into MongoDB database.
It uses the following configuration: 

######## Description

```
Host: opmon-collector.ci.kit
Path: /app/collector_module
System User: collector
```

######## Hardware Specification

```
* 16 GB RAM
* 512 GB storage
```

######## Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```


#### Corrector Module

The Corrector Module is responsible for transforming the raw data in MongoDB to cleaning data.
It uses the following configuration: 

```
Host: opmon-corrector.ci.kit
Path: /app/corrector_module
System User: corrector
```

######## Hardware Specification

```
* 32 GB RAM
* 512 GB storage ( ~ 2TB in 2021)
```

######## Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```


#### Reports Module

The Reports Module is responsible to generate periodical reports, accordingly to user configuration.
It uses the following configuration: 

```
Host: opmon-reports.ci.kit
Path: /app/reports_module
System User: reports
```

######## Hardware Specification

```
* 16 GB RAM
* 512 GB storage
```

######## Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```


#### Opendata Module

```
Host: opmon-opendata.ci.kit
Components: Opendata, PostgreSQL
```

##### Server 1 - Anonymizer and PostgreSQL 

######## Hardware Specification

```
* 32 GB RAM
* 5 TB storage ( ~ 30 TB in 2021)
```

######## Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
* PostgreSQL
```

##### Server 2 - Open Data Interface (GUI/API)

######## Hardware Specification

```
* 16 GB RAM
* 128 GB storage (just for server-side caching)
```

######## Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```


#### Analyzer Module

```
Host: opmon-analyzer.ci.kit
Components: Analyzer, Analyzer UI
```

######## Hardware Specification

```
* 128 GB RAM
* 5 TB storage
```

######## Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```
