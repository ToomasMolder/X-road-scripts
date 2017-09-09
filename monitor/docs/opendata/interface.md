# Open Data Module
# Interface Node

## Installation (Linux/Debian)

ODM is written in Python with 3.5.2 in mind. Although not tested, it should work with any modern Python 3.x version.

Modern Debian based distributions come with _python3_ preinstalled. Let's first get/update _pip_ tool for downloading dependencies.

```bash
sudo apt-get -y upgrade
sudo apt-get install -y python3-pip
```

Install dependencies:
```bash
sudo pip3 install -r monitor/opendata_module/interface/requirements.txt
```

##### Setting up Django databases for Interface

Interface (API and GUI) runs on Django.

In order for Django application to work, the internal SQLite database must be set up. For that, run

```bash
cd monitor/opendata_module/interface
# Create the schemas
python manage.py makemigrations
# Create the tables
python manage.py migrate
```

## Scaling

Upscaling (more services): more RAM to handle larger log files.
Upscaling (more end users): more CPUs and RAM for more simultaneous queries.

Benefits from: disk space for ~Apache caching.

## Networking

Port 80 must be open for web server and accessible from public network.

```bash
sudo apt-get install ufw
sudo ufw enable
sudo ufw allow 80
```

## Logging and heartbeats

API and GUI daily logs are stored for a week at **monitor/opendata_module/interface/logs** using TimedRotatingLogHandler.

API and GUI output heartbeats to **monitor/opendata_module/interface/{api,gui}-heartbeat.json** with the following formats:

```python
{"timestamp": "01-09-2017 15-31-13", "name": "Opendata API", "version": "0.0.1", "postgres": true}

{"timestamp": "01-09-2017 15-30-58", "name": "Opendata GUI", "version": "0.0.1", "api": true}
```

Heartbeats are output on a regular basis, depending on the [**opendata_config.py**](../../opendata_module/anonymizer/opendata_config.py) `heartbeat_interval` value.

## Configuration

Interface is using Django framework and much of its configuration is defined in Django's [settings.py](../../opendata_module/interface/interface/settings.py) file.

#### Django settings<a name="django-conf"></a>

Django has two relevant parameters, when setting up a new application.

##### Allowed hosts

Allowed hosts defines the valid host headers to [prevent Cross Site Scripting attacks](https://docs.djangoproject.com/en/1.11/topics/security/#host-headers-virtual-hosting). _ALLOWED__HOSTS_ must include the domain name of the hosted application (or IP address, if missing) or Django will automatically respond with "Bad Request (400)".

```python
ALLOWED_HOSTS = ['opmon-opendata.ci.kit', 'localhost', '127.0.0.1']
```

##### Static root

Static root is necessary only for GUI and holds the CSS and JS files to serve through ~Apache after `python manage.py collectstatic` has been issued. The most sensible path would direct to the Interface instance root directory.

If serving only a single X-Road instance:

```python
STATIC_ROOT = '/var/www/monitor/opendata_module/interface/static/'
```

Otherwise:

```python
STATIC_ROOT = '/var/www/instance_A/monitor/opendata_module/interface/static/'
```
