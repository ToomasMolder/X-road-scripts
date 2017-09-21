# X-Road v6 monitor project


## Introduction

The project maintains X-Road v6 log of service calls (queries). 
Logs are collected and corrected. 
Further analysis about anomalies (possible incidents) is made. 
Usage reports are created and published. 
Logs are anonymized and published as opendata.

Instructions to install all components, as well as all modules source code, can be found at (ACL-protected):

```
https://stash.ria.ee/projects/XTEE6/repos/monitor/browse 
```


## Installation instructions:

The system architecture is described ==> [here](./docs/system_architecture.md) <==.

## Installing/setting up the Mongo Database (MongoDB)

The first thing that should be done is setting up the MongoDB. Elasticsearch is not currently used. 

Instructions on setting up the MongoDB can be found ==> [here](./docs/database_module.md) <==

## Module installation precedence

The modules should be set up in the following order:
 
1. [Collector](./docs/collector_module.md)
2. [Corrector](./docs/corrector_module.md)
3. [Reports](./docs/reports_module.md)
4. [Opendata + PostgreSQL](./docs/opendata_module.md)
5. [Analyzer](./docs/analysis_module.md) (in progress)

## Programming language

All modules are written in **Python** and tested with version 3.5.2. Other 3.x versions are likely to be compatible, give or take some 3rd party library interfaces.

---

![](img/eu_regional_development_fund_horizontal_div_15.png "European Union | European Regional Development Fund | Investing in your future")
