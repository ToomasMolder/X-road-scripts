# X-Road v6 monitor project - System Architecture

The system is distributed over 7 servers, organized as follows:

* [Database Module (MongoDB)](#database-module)
* [Collector Module](#collector-module)
* [Corrector Module](#corrector-module)
* [Reports Module](#reports-module)
* [Analyzer Module](#analyzer-module)
* [Opendata Module (on 2 nodes)](#opendata-module)

![System overview](img/system_overview.png "System overview")

## Operational specifications

### Data flow expectation

* It is expected to have maximum 1 billion (1 000 000 000) X-Road v6 **service calls (queries)** in production environment in 1 year period
* Each query log might collected from both query partners (Client and Producer), id est maximum 2 billion (2 000 000 000) X-Road v6 service call **logs** in production environment in 1 year period:
  * 165 000 000 logs per month
  * 40 000 000 logs per week
  * 5 500 000 logs per day
  * 230 000 logs per hour 
  * 60 000 logs per 15 minute
* Each of log records in JSON-format takes approximately 1 KB (one kilobyte).
* Each query log is uploaded into MongoDB as 'raw_messages' and after correction kept there as 'clean_data'. Raw messages are purged periodically. Alternatively, log might kept in Collector HDD as disk file and loaded into system from there.
* Each query log is published in PostgreSQL as open-data after anonymization.

### Database operational specifications

* MongoDB shall retain 1 year data in disk memory.
* MongoDB shall retain 1 week data in RAM memory for efficient query.
* MongoDB shall run in a replication set for availability.
* PostgreSQL shall retain 1 year of public available data.

### Modules operational specifications

* Collector: runs every 15 min, collect recent data from security servers.
* Corrector: runs every 15m, use recent data in MongoDB.
* Analyzer: runs every hour, uses MongoDB and local cache in disk.
* Report creator: runs every day, uses MongoDB, stores reports in disk.
* Open Data Module: runs every day, uses MongoDB recent data, uses PostgreSQL as main database.

## Database Module

The Database Module is responsible to store queries data using MongoDB. 
It uses the following configuration:

```
Host: opmon.ci.kit
```

### Hardware Specification

```
* 64 GB RAM per Node
* 3 TB storage (RAID-0 or RAID-10)
* Minimum 1 Node, Recommended 3 Nodes for redundancy
* Scalability: Addition of Nodes (8 nodes to support 1 week data in RAM in 2021)
```

### Software Specification

```
* Ubuntu LTS 16.04 with EXT4 or XFS
* Python 3.5 (TODO: check this requirement, probably Python not required here)
* MongoDB 3.4
```

### Network Specification

```
* port 27017 (default)
* allow access from: collector IP, corrector IP, analyzer IP, reports IP, opendata anonymizer IP
```

## Collector Module

The Collector Module is responsible for querying servers and storing the data into MongoDB database.
It uses the following configuration: 

```
Host: opmon-collector.ci.kit
Path: /srv/app/collector_module
System User: collector
```

### Hardware Specification

```
* 16 GB RAM
* 512 GB storage
```

### Software Specification

```
* Ubuntu LTS 16.04 with EXT4 or XFS
* Python 3.5
```

### Network Specification

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

### Hardware Specification

```
* 32 GB RAM
* 512 GB storage ( ~ 2TB in 2021)
```

### Software Specification

```
* Ubuntu LTS 16.04 with EXT4 or XFS
* Python 3.5
```

### Network Specification

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

### Hardware Specification

```
* 16 GB RAM
* 512 GB storage
```

### Software Specification

```
* Ubuntu LTS 16.04 with EXT4 or XFS
* Python 3.5
```

### Network Specification

```
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
* allow access to: public web:22 (scp, rsync)
* allow access to: smtp:25 (email)
```

## Opendata Module

### Node 1 - Anonymizer

```
Host: opmon-anonymizer.ci.kit
Path: /srv/app/opendata_module/anonymizer
System User: anonymizer
```

#### Hardware Specification

```
* 4 GB RAM
* 4 GB storage
```

#### Software Specification

```
* Ubuntu LTS 16.04 with EXT4 or XFS
* Python 3.5
```

#### Network Specification

```
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
* allow access to: opmon-opendata:5432 (default, PostgreSQL)
```

### Node 2 - Interface and PostgreSQL 

```
Host: opmon-opendata.ci.kit
Path: /srv/app/opendata_module/interface
System User: opendata
```

#### Hardware Specification

```
* 32 GB RAM
* 5 TB storage ( ~ 30 TB in 2021)
```

#### Software Specification

```
* Ubuntu LTS 16.04 with EXT4 or XFS
* Python 3.5
* PostgreSQL
```

#### Network Specification

```
* allow access from: 0.0.0.0/0:80 (public, http)
* allow access from: 0.0.0.0/0:443 (public, https)
```

## Analyzer Module

```
Host: opmon-analyzer.ci.kit
Path: /srv/app/analyzer_module
Components: Analyzer, Analyzer UI
```

### Hardware Specification

```
* 128 GB RAM
* 5 TB storage - TODO: to be reviewed
```

### Software Specification

```
* Ubuntu LTS 16.04 with EXT4 or XFS
* Python 3.5
```

### Network Specification

```
* allow access to: opmon.ci.kit:27017 (default, MongoDB)
* allow access from: internal administrative network:80 (private, http)
```

---

![](img/eu_regional_development_fund_horizontal_div_15.png "European Union | European Regional Development Fund | Investing in your future")
