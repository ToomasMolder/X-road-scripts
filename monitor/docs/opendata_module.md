# X-Road v6 monitor project - Open Data Module

## About

Open Data Module (**ODM**) provides

Anonymizer
: A pipeline for making RIA logs suitable for public use. It is achieved by fetching still unprocessed - but corrected data - from the Corrector Module's output, applying the defined anonymization procedures, and outputting the already anonymized data.

Interface
: An API and a GUI to access the already anonymized data.

## Open Data Module's architecture

![system diagram](img/opendata/opendata_overview.png "System overview")

**Open Data Module resides on 2 machines.**

Anonymizer is on a machine without publicly accessible interface.

Open Data Module's Interface (API and GUI) and PostgreSQL reside on a machine with public access.

## Installation and configuration

The installation and configuration procedures along with test runs are described on the following pages:

[**Node 1: Anonymizer**](opendata/anonymizer.md)

[**Node 2: Interface and PostgreSQL**](opendata/interface_postgresql.md)

**Note:** Node 2 should be set up before, as Anonymizer depends on  a running PostgreSQL instance.

## Scaling over X-Road instances

Each X-Road instance will have it's own set of Anonymizer, PostgreSQL tables, and Interface. X-Road instance INSTANCE will have its data anonymized by its dedicated Anonymizer, anonymized data is stored in a specific PostgreSQL table, and Interface --- configured to serve INSTANCE data --- serves the anonymized data.

If there are 3 X-Road instances, there should also be 3 Anonymizers, 3 PostgreSQL tables storing the logs, and 3 Interface applications running.

### API documentation

TBA
