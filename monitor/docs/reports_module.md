# X-Road v6 monitor project - Reports Module

## About

The reports module is responsible for creating different reports about X-Road v6 members subsystems (datasets usage).
The execution of the reports module can be either performed automatically (via cron job) or manually.
Reports module also includes the Factsheet creation process (see below), which takes care of reports about monthly usages.

The module source code can be found at:

```
https://stash.ria.ee/projects/XTEE6/repos/monitor/browse
```

and can be downloaded into server:

```bash
# NB! git clone required only once
cd ~; git clone https://stash.ria.ee/scm/xtee6/monitor.git
mkdir -p ~/monitor; cd ~/monitor; git pull https://stash.ria.ee/scm/xtee6/monitor.git
```

## Diagram

![reports module diagram](img/Reports_module_diagram_v4.png "Reports module diagram")

## Networking

### Outgoing:

The reports module needs access to the Database Module (see [Database_Module](database_module.md)).
The reports module needs access to the reports publish server (via rsync / scp, port 22).
The reports module needs access to the SMTP to announce member/subsystem contacts about reports created and published (port 25).

#### Incoming: 

No **incoming** connection is needed in the reports module.

## Installation

This sections describes the necessary steps to install the **reports module** in a Linux Ubuntu 16.04. 
To a complete overview of different modules and machines, please refer to the [System Architecture](system_architecture.md) documentation.

### Install required packages

To install the necessary packages, execute the following commands in the terminal:

```
sudo apt-get update
sudo apt-get install python3-pip
sudo pip3 install pymongo==3.4.0
sudo apt-get install libfreetype6-dev
sudo pip3 install matplotlib==2.0.2
sudo pip3 install pandas==0.20.3
sudo pip3 install Jinja2==2.9.6
sudo apt-get install python3-dev python-lxml python-cffi libcairo2 libpango1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info
sudo pip3 install WeasyPrint==0.39
sudo apt-get install libtiff5-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk
sudo pip3 install Pillow==4.2.1
sudo pip3 install tinycss==0.4
```

xmlstarlet also needs to be installed on the operating system:

```
Quick installation of xmlstarlet:
Step 1: Update system:
        sudo apt-get update
Step 2: Install: xmlstarlet
Ater updaing the OS run following command to install the packae:
        sudo apt-get install xmlstarlet
```

### Install reports module

The reports module uses the system user **reports** and group **opmon**. To create them, execute:

```bash
sudo groupadd -f opmon
sudo useradd -M -r -s /bin/false -g opmon reports
```

The module files should be installed in the **/app/srv** directory, within a sub-folder named after the desired X-Road instance. In this manual, the "ee-dev" is used (please change "ee-dev" to map your desired instance, example: "xtee-ci-xm", "ee-test", "EE")

```bash
# make necessary directories
sudo mkdir -p /srv/app/ee-dev
sudo mkdir -p /srv/app/ee-dev/logs
sudo mkdir -p /srv/app/ee-dev/heartbeat
sudo mkdir -p /srv/app/ee-dev/reports
sudo mkdir -p /srv/app/ee-dev/factsheets
# correct necessary permissions
sudo chown root:opmon /srv/app/ee-dev/logs
sudo chmod g+w /srv/app/ee-dev/logs
sudo chown root:opmon /srv/app/ee-dev/heartbeat
sudo chmod g+w /srv/app/ee-dev/heartbeat
sudo chown root:opmon /srv/app/ee-dev/reports
sudo chmod g+w /srv/app/ee-dev/reports
sudo chown root:opmon /srv/app/ee-dev/factsheets
sudo chmod g+w /srv/app/ee-dev/factsheets
```

Copy the **reports module** code to the install folder and fix the file permissions:

```bash
sudo rsync -r -t -u monitor/reports_module /srv/app/ee-dev
sudo chown -R reports:opmon /srv/app/ee-dev/reports_module
sudo chmod -R -x+X /srv/app/ee-dev/reports_module
sudo chmod +x /srv/app/ee-dev/reports_module/*.sh
```

Add **reports module** as a **cron job** to the **reports** user.

```bash
sudo crontab -e -u reports
```

The **cron job** entry (executes every day at 11:00, note that a different value might be needed in production)

```
0 11 * * * cd /srv/app/ee-dev; ./reports_module/cron_reports.sh
```

To check if the reports module is properly installed in the reports user, execute:

```bash
sudo crontab -l -u reports
```

Finally, to check commands manually as reports user, execute:

```bash
sudo -u reports $CMD
```

## Configuration

The reports module can be configured via the settings file at:

```
/srv/app/ee-dev/reports_module/settings.py
```

These are the settings that **must** be definately set:

```
MONGODB_USER = "dev_user"
MONGODB_PWD = "jdu21docxce"
MONGODB_SERVER = "opmon.ci.kit"
MONGODB_SUFFIX = "ee-dev"

# --------------------------------------------------------
# Configure notifications
# --------------------------------------------------------
# e-mail from where the reports will be sent
SENDER_EMAIL = "reports@ria.ee"
# the smtp host used for sending reports
SMTP_HOST = 'smtp.aso.ee'
# the smtp port used for sending reports
SMTP_PORT = 25
```

These are the settings that will work with default values set but can be changed while needed:
```
# Reports output directory
REPORTS_PATH = "/srv/app/{0}/reports/".format(MONGODB_SUFFIX)
```
* The Reports module can be used in 2 languages: Estonian (et) and English (en). The relevant translation files are in the reports_module/lang folder.


## Manually creating a report

1. Change the location to reports_module:

```bash
cd /srv/app/ee-dev/reports_module
```

2. Run the report_worker.py with member_code, subsystem_code (optional), member_class, x_road_instance, start_date, end_date and language parameters.
Here's an example of the script call WITH the subsystem_code:

```bash
python3 -m reports_module.report_worker 70006317 monitoring GOV ee-dev 2017-1-1 2018-1-1 et
```

Here's an exa,ple of the script call WITHOUT the subystem_code:

```bash
python3 -m reports_module.report_worker 70006317 GOV ee-dev 2017-1-1 2018-1-1 et
```

3. Check the Report at the reports folder:

```bash
cd /srv/app/ee-dev/reports
```

Available languages for the reports are:

```
en - english
et - estonian
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
/srv/app/ee-dev/logs
```

## The external files required for reports module
These are the files that are updated by the RIA side.

NB: RIA system management personell is asked monthly to review and update mentioned files. The format is described within the examples below.

* contacts_dict.txt

```
# "x_road_instance/member_class/member_code/subsystem_code": ["receiver_email", "receiver_name"],

[
[{"ee-dev/COM/10011039/ehma": ["toomas.molder@ria.ee", "Arvi Alamaa"]}],
[{"ee-dev/COM/10011039/hampi": ["toomas.molder@ria.ee", "Arvi Alamaa"]}],
[{"ee-dev/COM/10015238/alexelaenergia": ["toomas.molder@ria.ee", "Riina Karm"]}],
[{"ee-dev/COM/10017059/hampi": ["toomas.molder@ria.ee", "Andrus Luht"]}],
[{"ee-dev/COM/10030278/csap": ["toomas.molder@ria.ee", "Martin Mägi"]}]
]
```

* member_name_dict.txt

```
# "x_road_instance/member_class/member_code": ["estonian_name"],

{
"ee-dev/GOV/70006317": ["Riigi Infosüsteemi Amet"],
"ee-dev/COM/10140133": ["Cybernetica AS"],
"ee-dev/COM/11045744": ["ASA QUALITY SERVICES OÜ"],
"ee-dev/COM/11333578": ["Aktors OÜ"],
"ee-dev/COM/10006966": ["AS CGI Eesti"]
}

```
* subsystem_name_dict.txt
```

# "x_road_instance/member_class/member_code/subsystem_code": ["estonian_name", "english_name"],

{
"ee-dev/COM/10011039/ehma": ["Olympic Casino Eesti AS EHMA X-tee alamsüsteem", ""],
"ee-dev/COM/10011039/hampi": ["Olympic Casino Eesti AS HAMPI X-tee alamsüsteem", ""],
"ee-dev/COM/10015238/alexelaenergia": ["10015238-alexelaenergia", ""],
"ee-dev/COM/10017059/hampi": ["Aktsiaselts Pafer HAMPI X-tee alamsüsteem", ""],
"ee-dev/COM/10030278/csap": ["CarlsbergSAP", "CarlsbergSAP"]
}
```

* get_dates.sh

NB! Make sure to create different files for reports module and the FactSheet.
Because currently they are using the same file. 
And also make sure to change the **REPORT_DATES_PATH** and **FACTSHEET_DATES_PATH**
in the settings file(s) accordingly.

```
# This file needs to output the following:
start_date(YYYY-MM-DD) end_date(YYYY-MM-DD)
# For example:
2017-05-01 2017-05-31
```

* list_subsystems.sh

```
# This file needs to output the following:
x_road_instance/member_class/member_code/subsystemcode
# NB: One combination per line
```

PS: X-Road v6 Security Server IP/Name has to be set up, setting SERVER.

## Open reports/FactSheet

* FactSheet is generated based on the previous calendar month's usage statistics. The FactSheet is generated and extraced into a text file, which is in a JSON format.
* The FactSheet uses some of the reports module's logic/functionality (code), then it it is located inside the reports module folder as well. 
* The FactSheet doesn't have it's own Logger so the logging is done into the same file as for the reports (reports_module.settings -> LOGGER_PATH).
* The FactSheet naming convention is the following: "start_date_end_date_creation_time.txt" (Ex: 2017-6-1_2017-6-30_2017-8-4_15-14-56-311873.txt)

#### FactSheet settings
The following settings (reports_module/settings.py) are relevant for FactSheet generation:

```
# This username is used for keeping a pointer in the database to make sure duplicated reports are not generated.
factsheet_username = "factsheet_{0}".format(MDB_SUFFIX)
# The number of top producers to have in the output file.
number_of_top_producers = 5
# The number of top consumers to have in the output file.
number_of_top_consumers = 5
# These member_code's will be excluded from the top_producers and top_consumers.
excluded_client_member_code = ["70005938", "70000591"]
# The path where the FactSheets will be generated.
factsheet_path = "/srv/app/{0}/factsheets/".format(MDB_SUFFIX)
# The path where the dates will be taken for the FactSheet.
FACTSHEET_DATES_PATH = "reports_module/get_dates.sh"
```

#### Cron Configuration (Development Server ee-dev)

Set cron to run FactSheet every day at 11 am:

```
crontab -e

0 11 * * * cd /srv/app/ee-dev; ./reports_module/cron_factsheet.sh
```

#### Manually generating a FactSheet

1. Change the location to reports_module:

```bash
cd /srv/app/ee-dev
```

2. Run the factsheet_worker.py with start_date("YYYY-MM-DD") and end_date("YYYY-MM-DD") parameters:

```bash
python3 -m reports_module.factsheet_worker "2017-01-01" "2018-01-01"
```

3. Check the FactSheet at the factsheets folder:

```bash
cd /srv/app/ee-dev/factsheets
```

#### Using the subsystem_list_generator

It is possible to print out the whole list of memberCode & subsystemCode combinations.
In order to do so subsystem_list_generator script can be used.
1. Change the location to project folder:

```bash
cd /srv/app/ee-dev
```

2. Run the subsystem_list_generator.py as a module:

```bash
python3 -m reports_module.subsystem_list_generator
```

## Logging 

The **reports module** produces log files that, by default, are stored at:

```
/srv/app/ee-dev/logs
```

To change the logging level, it is necessary to change the logger.setLevel parameter in the settings file:

```
# INFO - logs INFO & WARNING & ERROR
# WARNING - logs WARNING & ERROR
# ERROR - logs ERROR
logger.setLevel(logging.INFO)
```

###Heartbeat.json

The FactSheet & Report module both have a heartbeat.json file. The heartbeat files consist of the following fields:

```
timestamp - the timestamp when the heartbeat was updated
module - module name
msg - message
version - version
```
The settings (in the settings file) for the heartbeat files are the following:

```
# --------------------------------------------------------
# Configure heartbeats
# --------------------------------------------------------
FACTSHEET_HEARTBEAT_NAME = 'heartbeat_factsheet_{0}'.format(MONGODB_SUFFIX)
REPORT_HEARTBEAT_NAME = 'heartbeat_report_{0}'.format(MONGODB_SUFFIX)
HEARTBEAT_LOGGER_PATH = '/srv/app/{0}/heartbeat/'.format(MONGODB_SUFFIX)
```
So, for each XRoadInstance a separate heartbeat will be generated.
The statuses used for FactSheet generation in the heartbeat are the following:

```
"start"
"in_progress"
"success"
"error"
```

The statuses used in the Reports generation in the heartbeat are the following:

```
"start"
"in_progress"
"success"
"error"
```

---

![](img/eu_regional_development_fund_horizontal_div_15.png "European Union | European Regional Development Fund | Investing in your future")
