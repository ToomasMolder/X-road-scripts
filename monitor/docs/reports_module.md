# X-Road project - Reports Module

## About
```
The reports module is responsible for creating daily, weekly, monthly or manual reports.
The execution of the reports module can be either performed automatically (via cron job) or manually.
Reports module also includes the FactSheet creation process (see below), which takes care of reports about monthly usages.
```

#### Relevant Folder
```
> reports_module
```

#### Diagram describing the reports_module work can be found at the docs folder

![reports module diagram](img/Reports_module_diagram_v4.png "Reports module diagram")

## Installation (Linux)

This sections describes the necessary steps to install the **reports module** in a Linux Ubuntu 14.04. 
To a complete overview of different modules and machines, please refer to the [System Architecture](system_architecture.md) documentation.

#### Install required packages

To install the necessary packages, execute the following commands in the terminal:

```
sudo apt-get update
sudo apt-get install python3-pip
sudo pip3 install pymongo==3.4.0
sudo apt-get install libfreetype6-dev
sudo pip3 install matplotlib==2.0.2
sudo pip3 install pandas==0.20.3
sudo pip3 install Jinja2==2.9.6
sudo apt-get install python-dev python-pip python-lxml python-cffi libcairo2 libpango1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info
sudo pip3 install WeasyPrint==0.39
sudo apt-get install libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
sudo pip3 install Pillow==4.2.1
sudo pip3 install tinycss==0.4

```

#### Install reports module

Create the reports user. With the root user, execute:

```
adduser reports 
```

Create the **app** directory, and copy the reports module code to it:

```bash
mkdir /app
mkdir /app/logs
cp -r reports_module /app
```

Configure folder permissions to **reports** user:

```bash
chown -R reports:reports /app
```

Add **reports module** as a **cron job** to the **reports** user.

```bash
sudo su reports
crontab -e
```

The **cron job** entry (executes every day at 11:00)

```
0 11 * * * /app/reports_module/cron_reports.sh
```

Make sure the reports script has execution rights as the **reports** user:

```bash
chmod +x /app/reports_module/cron_reports.sh
```

## Configuration

The reports module can be configured via the settings file at:

```
/app/reports_module/settings.py
```
These are the settings that must be definately set:
```
MONGODB_USER = "dev_user"
MONGODB_PWD = "jdu21docxce"
MONGODB_SERVER = "opmon.ci.kit"
MONGODB_SUFFIX = "ee-dev"
```

These are the settings that will work with default values set but can be changed while needed:
```
# day / week / month. The interval of how often and for what period the reports should be created
GENERATION_TIME_FRAME = "month"
# The latest report will be created with an ending date calculated like this: Today - REPORT_BUFFER (in days)
REPORT_BUFFER = 10
# Reports language en / et
REPORT_LANGUAGE = "et"
# Reports output directory
REPORTS_PATH = "/app/{0}/reports/".format(MONGODB_SUFFIX)
# Number of hours to keep pending jobs (report generation)
KEEP_PENDING_JOBS = 24
```

## Manually creating a report
1. Change the location to reports_module:
```
cd /app/ee-dev/reports_module
```
2. Run the fact_sheet_worker.py with member_code, subsystem_code (optional), member_class, x_road_instance, start_date and end_date parameters:
```
python -m reports_module.report_worker 70000310 optional GOV ee-dev 2017-1-1 2018-1-1
```
or without the subystem_code:
```
python -m reports_module.report_worker 70000310 GOV ee-dev 2017-1-1 2018-1-1
```
3. Check the Report at the reports folder:
```
cd /app/ee-dev/reports
```

## Monitoring and Status

To check if the **reports module** is properly installed in the **reports** user, execute:

```bash
sudo su reports
crontab -l
```

This will list all entries in the crontab for **reports** user. You can execute the entries manually to check if all configuration and paths are set correctly.
The **reports module** produces log files that, by default, are stored at:

```
/app/logs
```

## Open reports/FactSheet
* FactSheet is generated based on the previous calendar month's usage statistics. The FactSheet is generated and extraced into a text file, which is in a JSON format.
* The FactSheet uses some of the reports module's logic/functionality (code), then it it is located inside the reports module folder as well. 
* The FactSheet doesn't have it's own Logger so the logging is done into the same file as for the reports (reports_module.settings -> LOGGER_PATH).
* The FactSheet naming convention is the following: "start_date_end_date_creation_time.txt" (Ex: 2017-6-1_2017-6-30_2017-8-4_15-14-56-311873.txt)
* The FactSheet can be used in 2 languages: Estonian (et) and English (en). The relevant translation files are in the reports_module/lang folder.
#### FactSheet settings
The following settings (reports_module/settings.py) are relevant for FactSheet generation:
```
# This username is used for keeping a pointer in the database to make sure duplicated reports are not generated.
fact_sheet_username = "fact_sheet_{0}".format(MDB_SUFFIX)
# The day of month on which the previous FactSheet will be generated.
# For example July 2017 FactSheet will be generated on the 10th of August.
fact_sheet_buffer = 10
# The number of top producers to have in the output file.
number_of_top_producers = 5
# The number of top consumers to have in the output file.
number_of_top_consumers = 5
# These member_code's will be excluded from the top_producers and top_consumers.
excluded_client_member_code = ["70005938", "70000591"]
# The path where the FactSheets will be generated.
fact_sheet_path = "/app/{0}/fact_sheets/".format(MDB_SUFFIX)
```
#### Cron Configuration (Development Server ee-dev)

Set cron to run FactSheet every day at 11 am:
```
crontab -e

0 11 * * * cd /app/ee-dev/reports_module; ./cron_fact_sheet.sh
```
#### Manually generating a FactSheet
1. Change the location to reports_module:
```
cd /app/ee-dev/reports_module
```
2. Run the fact_sheet_worker.py with start_date and end_date parameters:
```
python3 fact_sheet_worker.py "YYYY-MM-DD" "YYYY-MM-DD"
```
3. Check the FactSheet at the fact_sheets folder:
```
cd /app/ee-dev/fact_sheets
```

#### Using the subsystem_list_generator
It is possible to print out the whole list of memberCode & subsystemCode combinations.
In order to do so subsystem_list_generator skript can be used.
1. Change the location to project folder:
```
cd /app/ee-dev
```
2. Run the subsystem_list_generator.py as a module:
```
python3 -m reports_module.subsystem_list_generator
```
