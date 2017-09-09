# X-Road monitoring project - System Architecture

The system is distributed over 7 servers, organized as follows:

* [Database Module (MongoDB)](#database-module)
* [Collector Module](#collector-module)
* [Corrector Module](#corrector-module)
* [Reports Module](#reports-module)
* [Analyzer Module](#analyzer-module)
* [Opendata Module (on 2 nodes)](#opendata-module)

![System overview](img/system_overview.png "System overview")


The following sections describes each of these modules.

## Operational specifications

* MongoDB shall retain 1 year data in disk memory
* MongoDB shall retain 1 week data in RAM memory for efficient query
* MongoDB shall run in a replication set for availability
* PostgreSQL shall retain 1 year of public available data.

* Collector: runs every 15m, creates list of security servers according to global configuration, collects data from security servers, stores raw data into MongoDB or into HDD
* Corrector: runs every 15m, removes possible duplicates from raw data in MongoDB, does simple calculations about durations and stores clean data into MongoDB
* Analyzer: runs every day, finds errors and possible anomalies (incidents) from clean data in MongoDB, uses MongoDB and local cache in HDD
* Reports creator: runs every day, creates usage reports based on clean data in MongoDB, uses MongoDB, stores reports in HDD, syncs them remotely into public site and sends emails to customers about them
* Opendata: runs every day, uses MongoDB recent clean data, uses PostgreSQL as main database.

## Database Module

The Database Module is responsible to store queries data using MongoDB. 
It uses the following configuration:

#### Description

```
Host: opmon.ci.kit
System User: opmon
```

#### Hardware Specification

```
* 64 GB RAM per Node
* 3 TB storage (RAID-0 or RAID-10)
* Minimum 1 Node, Recommended 3 Nodes for redundancy
* Scalability: Addition of Nodes (8 nodes to support 1 week data in RAM in 2021)
```

#### Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5 (TODO: check this requirement, probably Python not required here)
* MongoDB 3.4
```

#### Network Specification

```
* port 27017 (default)
* allow access from: collector IP, corrector IP, analyzer IP, reports IP, opendata anonymizer IP
```

## Collector Module

The Collector Module is responsible for querying servers and storing the data into MongoDB database.
It uses the following configuration: 

#### Description

```
Host: opmon-collector.ci.kit
Path: /srv/app/collector_module
System User: collector
```

#### Hardware Specification

```
* 16 GB RAM
* 512 GB storage
```

#### Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```

#### Network Specification

```
* allow access to: X-Road central server port 80, monitoring security server port 80
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
```

## Corrector Module

The Corrector Module is responsible for transforming the raw data in MongoDB to cleaning data.
It uses the following configuration: 

```
Host: opmon-corrector.ci.kit
Path: /srv/app/corrector_module
System User: corrector
```

#### Hardware Specification

```
* 32 GB RAM
* 512 GB storage ( ~ 2TB in 2021)
```

#### Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```

#### Network Specification

```
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
```


## Reports Module

The Reports Module is responsible to generate periodical reports, accordingly to user configuration.
It uses the following configuration: 

```
Host: opmon-reports.ci.kit
Path: /srv/app/reports_module
System User: reports
```

#### Hardware Specification

```
* 16 GB RAM
* 512 GB storage
```

#### Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```

#### Network Specification

```
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
* allow access to: public web:22 (scp, rsync)
```

## Opendata Module

### Server 1 - Anonymizer and PostgreSQL 

**TODO: consider PostgreSQL to be moved from Server 1 into Server 2. If yes, then review all requirements/specifications**

```
Host: opmon-anonymizer.ci.kit
Path: /srv/app/opendata_module/anonymizer
System User: anonymizer
```

#### Hardware Specification

```
* 32 GB RAM
* 5 TB storage ( ~ 30 TB in 2021)
```

#### Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
* PostgreSQL
```

#### Network Specification

```
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
* allow access to: opmon-opendata:5432 (default, PostgreSQL)
```

### Server 2 - Open Data Interface (GUI/API)

**TODO: consider PostgreSQL to be moved from Server 1 into Server 2. If yes, then review all requirements/specifications**

```
Host: opmon-opendata.ci.kit
Path: /srv/app/opendata_module/interface
System User: opendata
```

#### Hardware Specification

```
* 16 GB RAM
* 128 GB storage (just for server-side caching)
```

#### Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```

#### Network Specification

```
* allow access to: opmon-opendata:5432 (default, PostgreSQL)
* allow access from: 0.0.0.0/0:80 (public, www)
```

## Analyzer Module

```
Host: opmon-analyzer.ci.kit
Path: /srv/app/analyzer_module
Components: Analyzer, Analyzer UI
```

#### Hardware Specification

```
* 128 GB RAM
* 5 TB storage
```

#### Software Specification

```
* Ubuntu LTS 14.04 with EXT4 or XFS
* Python 3.5
```

#### Network Specification

```
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
* allow access from: internal administrative network:80 (private, www)
```
