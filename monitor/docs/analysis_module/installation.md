# Analysis Module

# Installation

The module source code can be found at (ACL-protected):

```
https://stash.ria.ee/projects/XTEE6/repos/monitor/browse
```

and can be downloaded into server (ACL-protected):

```bash
export TMPDIR="/tmp" ; mkdir --parents ${TMPDIR}; cd ${TMPDIR}
# NB! git clone required only once
git clone https://stash.ria.ee/scm/xtee6/monitor.git
# when want just to refresh existing repository, use pull
cd ${TMPDIR}/monitor; git pull https://stash.ria.ee/scm/xtee6/monitor.git
```

The Analysis module is implemented in Python 3.5.2. Although not tested, it should work with any modern Python 3.x version.

**For each X-Road instance we set up its own Analyzer and Interface instances.**

By default, Analyzer component will be installed to **/srv/app/x_road_instance** and Interface to **/var/www/x_road_instance**.

## Networking

### Outgoing

- The anonymizer module needs access to the [Database_Module](../database_module.md).

### Incoming

- The Analysis module's Interface accepts incoming access from the local network on http port 80 (and, if configured, also https port 443).

## 1. Apache

First let's install Apache and relevant libraries in order to  serve Interface instances for different X-Road instances.

```bash
sudo apt-get -y update
sudo apt-get install -y apache2 apache2-utils libexpat1 ssl-cert apache2-dev
```

**Note:** Apache installation creates user **www-data**. Django application, which serves Analyzer's Interface, is run with its _www-data_ permissions.

Open 80 (http) [and 443 (https) for Apache, if using SSL].

**WARNING:** **Although ufw is convenient, enabling it overrules/wipes the iptables, INCLUDING ACCESS TO 22 FOR SSH. 
Always allow 22 after enabling.** 


```bash
sudo apt-get install ufw
sudo ufw enable
sudo ufw allow 22
sudo ufw allow http
sudo ufw allow https
```

**WARNING:** **Although ufw is convenient, enabling it overrules/wipes the iptables, INCLUDING ACCESS TO 22 FOR SSH. Always allow 22 after enabling.** 

To verify that the ports are open, run

```bash
sudo ufw status
```

This should output something similar to

```bash
Status: active

To                         Action      From
--                         ------      ----
22                         ALLOW       Anywhere
80                         ALLOW       Anywhere
443                        ALLOW       Anywhere
22 (v6)                    ALLOW       Anywhere (v6)
80 (v6)                    ALLOW       Anywhere (v6)
443 (v6)                   ALLOW       Anywhere (v6)
```


To test whether Apache works, the next command should output a web page source:

```bash
sudo apt-get install --assume-yes curl
curl localhost
```

## 2. Setting up Python components

The Interface uses the system user **www-data** (apache) and group **opmon**.
The Analyzer uses **analyzer** user.
To create them, execute:

```bash
sudo groupadd --force opmon
sudo usermod --append --groups opmon www-data
sudo useradd -r -s /bin/false -g opmon analyzer
```

### Create relevant X-Road instances

Each X-Road instance needs its own instance of Interface.

In this manual, `ee-dev` is used as INSTANCE. 
To repeat for another instance, please change `ee-dev` to map your desired instance, example: `ee-test`, `EE`.

```bash
export APPDIR="/srv/app"
export WEBDIR="/var/www"
export INSTANCE="ee-dev"
```
Web server content for Interface is stored in `${WEBDIR}`,  logs and heartbeats along with Analyzer in `${APPDIR}`.

Set up codebase for the instance's web application:

```bash
sudo mkdir --parents ${WEBDIR}/${INSTANCE}/analysis_module

# Copy the UI code from repository to the default Apache directory ($WEBDIR)
# export TMPDIR="/tmp" 
sudo rsync --recursive --update --times \
    ${TMPDIR}/monitor/analysis_module/analyzer_ui \
	${WEBDIR}/${INSTANCE}/analysis_module
# or
# sudo cp --recursive --update \
#     ${TMPDIR}/monitor/analysis_module/analyzer_ui \
#     ${WEBDIR}/${INSTANCE}/analysis_module
```

Set up codebase for the instance's scheduled computations:

```bash
# Copy the Analyzer code from repository to the $APPDIR.
sudo rsync --recursive --update --times \
    ${TMPDIR}/monitor/analysis_module/analyzer \
	${APPDIR}/${INSTANCE}/analysis_module
# or
# sudo cp --recursive --update \
#     ${TMPDIR}/monitor/analysis_module/analyzer \
#     ${APPDIR}/${INSTANCE}/analysis_module
```

Set up common log and heartbeat directories.

```bash

# Create log, heartbeat, and SQLite database directories with www-data write permission
sudo mkdir --parents ${APPDIR}/${INSTANCE}/heartbeat
sudo chown root:opmon ${APPDIR}/${INSTANCE}/heartbeat
sudo chmod g+w ${APPDIR}/${INSTANCE}/heartbeat

sudo mkdir --parents ${APPDIR}/${INSTANCE}/logs
sudo chown root:opmon ${APPDIR}/${INSTANCE}/logs
sudo chmod g+w ${APPDIR}/${INSTANCE}/logs

# Database directory to store Django's internal SQLite database for UI.
sudo mkdir --parents ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/database
sudo chown www-data:www-data ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/database
```

Settings for different X-Road instances have been prepared and can be used:

```bash
# Analyzer UI
# export WEBDIR="/var/www"; export INSTANCE="ee-dev"
sudo rm ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/analyizer_ui/settings.py
sudo ln --symbolic \
    ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/instance_configurations/settings_${INSTANCE}.py \
    ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/analyzer_ui/settings.py
```

```bash
# Analyzer computations
# export APPDIR="/srv/app"; export INSTANCE="ee-dev"
sudo rm ${APPDIR}/${INSTANCE}/analysis_module/analyzer/settings.py
sudo ln --symbolic \
    ${APPDIR}/${INSTANCE}/analysis_module/analyzer/instance_configurations/settings_${INSTANCE}.py \
    ${APPDIR}/${INSTANCE}/analysis_module/analyzer/settings.py
```

Correct necessary permissions

```bash
# Analyzer UI
# export WEBDIR="/var/www"; export INSTANCE="ee-dev"
sudo chown --recursive www-data:opmon ${WEBDIR}/${INSTANCE}/analysis_module
sudo chmod --recursive -x+X ${WEBDIR}/${INSTANCE}/analysis_module
# sudo chmod +x ${WEBDIR}/${INSTANCE}/analysis_module/*.sh
```

```bash
# Analyzer
# export APPDIR="/srv/app"; export INSTANCE="ee-dev"
sudo chown --recursive analyzer:opmon ${WEBDIR}/${INSTANCE}/analysis_module
# sudo chmod --recursive -x+X ${WEBDIR}/${INSTANCE}/analysis_module
# sudo chmod +x ${WEBDIR}/${INSTANCE}/analysis_module/*.sh
```

### Installing Python libraries

Analysis module has been written with Python 3.5.2 in mind, which is the default preinstalled _python3_ version for Ubuntu 16.04.3 LTS.

Let's first get _pip3_ tool for downloading 3rd party Python libraries for _python3_ along with system dependencies.

```bash
sudo apt-get -y upgrade
sudo apt-get install -y python3-pip libpq-dev libyaml-dev
pip3 install --upgrade pip
```

Install dependencies:
```bash
sudo pip3 install -r ~/monitor/analysis_module/requirements.txt
```

We also need our Python version specific *mod_wsgi* build to serve Python applications through WSGI and Apache.

```bash
sudo pip3 install mod_wsgi
```

This builds us a *mod_wsgi* for our *python3* version.


### Setting up Django SQLite databases for Interface

Analyzer UI runs on Django.

In order for Django application to work, the internal SQLite database must be set up. For that, run:

```bash
# Create schemas and then create corresponding tables
# export WEBDIR="/var/www"; export INSTANCE="ee-dev"
sudo --user www-data python3 ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/manage.py makemigrations
sudo --user www-data python3 ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/manage.py migrate
```

### Collecting static files for Apache

Static files are scattered during the development in Django. 
To allow Apache to serve the static files from one location, they have to be collected (copied to a single directory). 
Collect static files for relevant instances to `${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/static` by default (`STATIC_ROOT` value in `settings.py`):

```bash
# export WEBDIR="/var/www"; export INSTANCE="ee-dev"
sudo python3 ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/manage.py collectstatic <<<yes
```

Make the _root:root_ static directory explicitly read-only for others (including _www-data_):

```bash
# export WEBDIR="/var/www"; export INSTANCE="ee-dev"
sudo chmod --recursive o-w ${WEBDIR}/${INSTANCE}/analysis_module/analyzer_ui/static
```


## 3. Configuring Apache

Let Apache know of the correct WSGI instance by replacing Apache's default mod_wsgi loader.

```bash
sudo cp --preserve /etc/apache2/mods-available/wsgi.load{,.bak}
sudo mod_wsgi-express install-module | head --lines 1 > /etc/apache2/mods-available/wsgi.load
```

Create an Apache configuration file at **/etc/apache2/sites-available/analyzer.conf** for port 80 (http). 

**Note:** To configure port 443 (https), public domain address and certificates are required.

**Note:** The correct Python interpreter is derived from the loaded *wsgi_module*.

```bash
sudo vi /etc/apache2/sites-available/analyzer.conf
```

**Note:** `hostname -I` is probably the easiest way to get machine's IP address for `<machine IP>`

**Note:** `<machine IP>` can be substituted with public domain name, once it's acquired.

```bash
<VirtualHost <machine IP>:80>
        ServerName <machine IP>
        ServerAdmin administrator@ci.kit
        
        ErrorLog ${APACHE_LOG_DIR}/analysis-error.log
        CustomLog ${APACHE_LOG_DIR}/analysis-access.log combined

        LoadModule wsgi_module "/usr/lib/apache2/modules/mod_wsgi-py35.cpython-35m-x86_64-linux-gnu.so"

        WSGIApplicationGroup %{GLOBAL}

        #### Interface instances ####

        ## EE-DEV ##

        WSGIDaemonProcess ee-dev
        WSGIScriptAlias /ee-dev /var/www/ee-dev/analysis_module/analyzer_ui/analyzer_ui/wsgi.py process-group=ee-dev

        # Suffices to share static files only from one X-Road instance, as instances share the static files.
        Alias /static /var/www/ee-dev/analysis_module/analyzer_ui/static

        <Directory /var/www/ee-dev/analysis_module/analyzer_ui/static>
                Require all granted
        </Directory>

        ## EE-TEST ##

        WSGIDaemonProcess ee-test
        WSGIScriptAlias /ee-test /var/www/ee-test/analysis_module/analyzer_ui/analyzer_ui/wsgi.py process-group=ee-test

        ## EE ##

        WSGIDaemonProcess EE
        WSGIScriptAlias /EE /var/www/EE/analysis_module/analyzer_ui/analyzer_ui/wsgi.py process-group=EE
        
</VirtualHost>
```

After we have defined our *VirtualHost* configuration, we must enable the new *site* --- *analyzer.conf* --- so that Apache could start serving it..

```bash
sudo a2ensite analyzer.conf
```

Finally, we need to reload Apache in order for the site update to apply.

```bash
sudo service apache2 reload
```

## 4. Configuring database parameters
Change `MDB_PWD` and `MDB_SERVER` parameters in settings files:

##### ee-dev

```bash
sudo nano /srv/app/ee-dev/analysis_module/analyzer/settings.py 

sudo nano /var/www/ee-dev/analysis_module/analyzer_ui/analyzer_ui/settings.py 
```

##### ee-test

```bash
sudo nano /srv/app/ee-test/analysis_module/analyzer/settings.py 

sudo nano /var/www/ee-test/analysis_module/analyzer_ui/analyzer_ui/settings.py 
```

##### xtee-ci-xm

```bash
sudo nano /srv/app/xtee-ci-xm/analysis_module/analyzer/settings.py 

sudo nano /var/www/xtee-ci-xm/analysis_module/analyzer_ui/analyzer_ui/settings.py 
```



## 5. Initial calculations
As a first step, the historic averages need to be calculated and the anomalies found. Both of these steps take some time, depending on the amount of data to be analyzed. For instance, given 3000 unique service calls, both steps take approximately 10 minutes.

##### ee-dev

```bash
python3 /srv/app/ee-dev/analysis_module/analyzer/train_or_update_historic_averages_models.py
python3 /srv/app/ee-dev/analysis_module/analyzer/find_anomalies.py
```

##### ee-test

```bash
python3 /srv/app/ee-test/analysis_module/analyzer/train_or_update_historic_averages_models.py
python3 /srv/app/ee-test/analysis_module/analyzer/find_anomalies.py
```

##### xtee-ci-xm

```bash
python3 /srv/app/xtee-ci-xm/analysis_module/analyzer/train_or_update_historic_averages_models.py
python3 /srv/app/xtee-ci-xm/analysis_module/analyzer/find_anomalies.py
```

## 6. Configuring Django

#### Primary

##### Allowed hosts

Allowed hosts defines the valid host headers to [prevent Cross Site Scripting attacks](https://docs.djangoproject.com/en/1.11/topics/security/#host-headers-virtual-hosting). _ALLOWED__HOSTS_ must include the domain name of the hosting server (or IP address, if missing) or Django will automatically respond with "Bad Request (400)".

```python
ALLOWED_HOSTS = ['opmon-analyzer.ci.kit', 'localhost', '127.0.0.1']
```

**Note:** when getting **Bad request (400)** when accessing a page, then `ALLOWED_HOSTS` needs more tuning. 

#### Secondary

##### Static root

Static root is necessary only for GUI and holds the CSS and JS files to serve through Apache after `python manage.py collectstatic` has been issued. By default it directs to the Interface instance's root directory.

```python
STATIC_ROOT = '/var/www/<instance>/analysis_module/analyzer_ui/static/'
```


## 7. Accessing web interface

Navigate to http://server_address/{ee-dev,ee-test,xtee-ci-xm}/gui


# Description and usage of Analyzer (the back-end)

## Models

In the core of the Analyzer are *models* that are responsible for detecting different types of anomalies. The model classes are located in the folder **analysis_module/analyzer/models**.

** 1. FailedRequestRatioModel.py** (anomaly type 4.3.1): aggregates requests for a given service call by a given time interval (e.g. 1 hour) and checks if the ratio of failed requests (```succeeded=False```) with respect to all requests in this time interval is larger than a given threshold. The type of found anomalies (```anomalous_metric```) will be failed_request_ratio.

** 2. DuplicateMessageIdModel.py** (anomaly type 4.3.2):  aggregates requests for a given service call by a given time interval (e.g. 1 day) and checks if there are any duplicated ```messageId``` in that time interval. The type of found anomalies (```anomalous_metric```) will be duplicate_message_id.

** 3. TimeSyncModel.py** (anomaly type 4.3.3): for each request, checks if the time of data exchange between client and producer is a positive value. Namely, an incident is created if ```requestNwSpeed < 0``` or ```responseNwSpeed < 0```. In each incident, the number of requests not satisfying these conditions are aggregated for a given service call and a given time interval (e.g. 1 hour). The type of found anomalies (```anomalous_metric```) will be one of [responseNwDuration, requestNwDuration].

** 4. AveragesByTimeperiodModel.py** (anomaly types 4.3.5-4.3.9) :  aggregates requests for a given service call by a given time interval, calculating:
1) the number or requests in this time interval,
2) mean request size (if exists --- ```clientRequestSize```, otherwise ```producerRequestSize```) in this time interval,
3) mean response size (if exists --- ```clientResponseSize```, otherwise ```producerResponseSize```) in this time interval,
4) mean client duration (```totalDuration```) in this time interval,
5) mean producer duration (```producerDurationProducerView```) in this time interval.
Each of these metrics are compared to historical values for the same service call during a similar time interval (e.g. on the same weekday and the same hour). In particular, the model considers the mean and the standard deviation (std) of historical values and calculates the *z-score* for the current value: ```z_score = abs(current_value - historic_mean) / historic_std```.
Based on this score, the model estimates the confidence that the current value comes from a different distribution than the historic values. If the confidence is higher than a specified confidence threshold, the current value is reported as a potential incident. The type of found anomalies (```anomalous_metric```) will be one of [request_count, mean_request_size, mean_response_size, mean_client_duration, mean_producer_duration].
 

## Scripts

Before finding anomalies using the AveragesByTimeperiodModel, the model needs to be trained. Namely, it needs to calculate the historic means and standard deviations for each relevant time interval. The data used for training should be as "normal" (anomaly-free) as possible. Therefore, it is recommended that the two phases, training and finding anomalies, use data from different time periods. To ensure these goals, the **regular** processes for anomaly finding and model training proceed as follows:

1. For recent requests, the existing model is used to *find* anomalies, which will be recorded as potential incidents. The found anomalies are shown in the Analyzer UI for a specified time period (e.g. 10 days), after which they are considered "expired" and will not be shown anymore.
2. Anomalies/incidents that have expired are used to update (or retrain) the model. Requests that are part of a "true incident" (an anomaly that was marked as "incident" before the expiration date) are not used to update the model. This way, the historic averages remain to describe the "normal" behaviour. Note that updating the model does not change the anomalies that have already been found (the existing anomalies are not recalculated).

Also, as these processes aggregate requests by certain time intervals (e.g. hour), only the data from time intervals that have already completed are used. This is to avoid situations where, for example, the number of requests within 10 minutes is compared to the (historic) number of requests within 1 hour, as such comparison would almost certainly yield an anomaly. 

It is recommended that the model is given some time to learn the behaviour of a particular service call (e.g. 3 months). Therefore, the following approach is implemented for **new** service calls:
1. For the first 3 months since the first request was made by a given service call, no anomalies are reported (this is the training period)
2. After these 3 months have passed, the first anomalies for the service call will be reported. Both the model is trained (i.e. the historic averages are calculated) and anomalies are found using the same data from the first 3 months.
3. The found anomalies are shown in the analyzer user interface for 10 days, during which their status can be marked. During these 10 days, the model version is fixed and incoming data are analyzed (i.e. the anomalies are found) based on the initial model (built on the first 3-months data).
4. After these 10 days (i.e. when the first incidents have expired), the model is retrained, considering the feedback from the first anomalies and the **regular** analyzer process is started (see above).


The approach described above is implemented in two scripts, located in the folder **analysis_module/analyzer**:

** 1) train_or_update_historic_averages_models.py:** takes requests that have appeared (and expired as potential incidents) since the last update to the model, and uses them to update or retrain the model to a new version.
** 2) find_anomalies.py:** takes new requests that have appeared since the last anomaly-finding phase was performed and uses the current version of the model to find anomalies, which will be recorded as potential incidents. 

It is suggested to run these two scripts automatically using cron. For example, to run both scripts at the 5th minute of each hour, open the crontab:

```bash
crontab -e
```

and add the two lines:

```bash
5 * * * * python <path_to_code>/analysis_module/analyzer/train_or_update_historic_averages_models.py
5 * * * * python <path_to_code>/analysis_module/analyzer/find_anomalies.py
```