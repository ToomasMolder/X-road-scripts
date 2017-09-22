# Open Data Module
# Interface and PostgreSQL Node

## Installation (Linux/Debian)

Interface and PostgreSQL node has 3 main components:

1. PostgreSQL for storing data which will be served by Django application;
2. Django web application serving a single X-Road instance's daily logs from PostgreSQL;
3. Apache serving the Django applications, each of which serves a specific X-Road instance.


### 1. PostgreSQL

#### Setting up the ODM database

Open Data Module depends on a running PostgreSQL instance. Opmon-opendata.ci.kit development server has an existing database `opendata` with user `opendata` and password `12345`.

ODM uses [PostgreSQL](https://www.postgresql.org/ "PostgreSQL") to store the anonymized data ready for public use. Current instructions are for PostgreSQL 9.3.

A database with remote connection capabilities must be set up beforehand. Relations and relevant indices will be created dyncamically during the first Anonymizer's run, according to the supplied configuration.

##### Downloading PostgreSQL 9.5

Ubuntu 16.04.3 has PostgreSQL 9.5 in its default apt repository.

```bash
sudo apt-get -y update 
sudo apt-get install postgresql
```

##### Creating users and a database

 
Add Linux users for remote access.

```bash
sudo adduser --no-create-home anonymizer
sudo adduser --no-create-home opendata
```

Switch to *postgres* user to create a database and corresponding PostgreSQL users.

```bash
sudo su -l postgres
```

Enter PostgreSQL interactive terminal.

```bash
psql
```

Create *anonymizer* and *opendata* PostgreSQL users, *opendata* database and grant the privileges. We also have to define default privileges for *opendata*, as tables are created dynamically by *anonymizer*.

**Note:** database name can differ but must match Anonymizer's and Django application's `mongodb['database_name']`. Same with username, but for `mongodb['user']`.

```
postgres=# CREATE USER anonymizer WITH PASSWORD '12345';
postgres=# CREATE USER opendata WITH PASSWORD '12345';
postgres=# CREATE DATABASE opendata WITH TEMPLATE template1 ENCODING 'utf8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
postgres=# GRANT CREATE, CONNECT ON DATABASE opendata TO anonymizer;
postgres=# GRANT CONNECT ON DATABASE opendata TO opendata;
postgres=# ALTER DEFAULT PRIVILEGES FOR USER anonymizer IN SCHEMA public GRANT SELECT ON TABLES to opendata;
postgres=# \q
```

##### Allowing remote access

PostgreSQL needs remote access, since API resides on another machine (hopefully).

To allow remote access, permissions must be granted from both PostgreSQL and Linux sides.

The following configuration allows password authentication for all clients. 

To allow remote access to PostgreSQL, add the following lines to `/etc/postgresql/9.5/main/pg_hba.conf` in order to enable password authentication (md5 hash comparison) for Anonymizer node:

```bash
sudo cp /etc/postgresql/9.5/main/pg_hba.conf /etc/postgresql/9.5/main/pg_hba.conf.backup
echo "host     opendata   anonymizer   <anonymizer_node_IP>   md5" | sudo tee --append /etc/postgresql/9.5/main/pg_hba.conf
echo "hostssl     opendata   anonymizer   <anonymizer_node_IP>   md5" | sudo tee --append /etc/postgresql/9.5/main/pg_hba.conf
```

**Note:** `host` type access can be revoked if using SSL-encrypted connections.
**Note:** For stricter localhost security, existing `host all all 127.0.0.1/32 md5` can be substituted with
```bash
host    all         postgres    127.0.0.1/32    md5
host    opendata    opendata    127.0.0.1/32    md5
```

Then allow remote clients by changing or adding the following line in `/etc/postgresql/9.5/main/postgresql.conf`:

```
listen_addresses = '*'
```

This says that PostgreSQL should listen on its defined port on all its network interfaces, including localhost.

##### Setting up rotational logging

To set up daily logging which stores logs for a week at a default location `/var/lib/postgresql/9.5/main/pg_log`, add the following lines to `/etc/postgresql/9.5/main/postgresql.conf` 

```bash
logging_collector = on
log_filename = 'postgresql-opendata-%A.log'
log_truncate_on_rotation = on
log_rotation_age = 1d
```

This stores this Monday's logs in `/var/lib/postgresql/9.5/main/pg_log/postgresql-opendata-Monday.log`

It might also be relevant to log connections and modifying queries.

```bash
log_connections = on
log_disconnections = on
log_statement = 'mod'
```

Also, the default log directory `/var/lib/postgresql/9.5/main/pg_log` can be changed by setting an absolute path.

```bash
log_directory = '/srv/app/ee-dev/logs'
```

**Note:** changing log directory may make sense only when changing Apache served Django application default location as well.

##### Finally

Log out from `postgres` user and restart PostgreSQL.

```bash
logout
sudo service postgresql restart
```

Let's open PostgreSQL's default port 5432, so that Anonymizer could connect.

```bash
sudo apt-get install -y ufw
sudo ufw enable
sudo ufw allow 22
sudo ufw allow 5432/tcp
```

**WARNING:** **Although ufw is convenient, enabling it overrules/wipes the iptables, INCLUDING ACCESS TO 22 FOR SSH. Always allow 22 after enabling.** 


## 2. Apache

First let's install Apache and relevant libraries in order to be able to serve Open Data Interface instances.

```bash
sudo apt-get -y update
sudo apt-get install -y apache2 apache2-utils libexpat1 ssl-cert apache2-dev
```

Let's open both 80 and 443 for Apache. Enabling `ufw` and port 22 in case PostgreSQL section isn't completed.

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


To test whether Apache works

```bash
sudo apt-get install curl
curl localhost
```

The previous command should output a web page source.

## 3. Open Data Django web applications

Each X-Road instance needs its own instance of Open Data Interface.

### Setting up X-Road instances

Let's first download the Interface's code from the repository.

```bash
sudo apt-get -y upgrade
sudo apt-get install git -y
git clone https://stash.ria.ee/scm/xtee6/monitor.git
```

**Note:** We don't need to create a dedicated user, as Interface will be served by Apache under `www-data` system user.

### Create relevant X-Road instances

##### ee-dev

```bash
sudo mkdir -p /var/www/ee-dev/opendata_module
sudo mkdir -p /srv/app/ee-dev/heartbeat
sudo mkdir -p /srv/app/ee-dev/logs

# Copy the code from repository to the default Apache directory
sudo cp -u -r ~/monitor/opendata_module/interface /var/www/ee-dev/opendata_module

# Copy an X-Road instance settings template
sudo cp /var/www/ee-dev/opendata_module/interface/instance_configurations/settings_ee-dev.py /var/www/ee-dev/opendata_module/interface/interface/settings.py
```

##### ee-test

```bash
sudo mkdir -p /var/www/ee-test/opendata_module
sudo mkdir -p /srv/app/ee-test/heartbeat
sudo mkdir -p /srv/app/ee-test/logs

# Copy the code from repository to the default Apache directory
sudo cp -u -r ~/monitor/opendata_module/interface /var/www/ee-test/opendata_module

# Copy an X-Road instance settings template
sudo cp /var/www/ee-test/opendata_module/interface/instance_configurations/settings_ee-test.py /var/www/ee-test/opendata_module/interface/interface/settings.py
```

##### xtee-ci-xm

```bash
sudo mkdir -p /var/www/xtee-ci-xm/opendata_module
sudo mkdir -p /srv/app/xtee-ci-xm/heartbeat
sudo mkdir -p /srv/app/xtee-ci-xm/logs

# Copy the code from repository to the default Apache directory
sudo cp -u -r ~/monitor/opendata_module/interface /var/www/xtee-ci-xm/opendata_module

# Copy an X-Road instance settings template
sudo cp /var/www/xtee-ci-xm/opendata_module/interface/instance_configurations/settings_xtee-ci-xm.py /var/www/xtee-ci-xm/opendata_module/interface/interface/settings.py
```

### Installing Python libraries

Open Data Interface has been written with Python 3.5.2 in mind, which is the default preinstalled _python3_ version for Ubuntu 16.04.3 LTS.

Let's first get _pip3_ tool for downloading 3rd party Python libraries for _python3_ along with system dependencies.

```bash
sudo apt-get -y upgrade
sudo apt-get install -y python3-pip libpq-dev libyaml-dev
```

Install dependencies:
```bash
sudo pip3 install -r ~/monitor/opendata_module/anonymizer/requirements.txt
```

We also need our Python version specific *mod_wsgi* build to serve Python applications through WSGI and Apache.

```bash
sudo pip3 install mod_wsgi
```

This builds us a *mod_wsgi* for our *python3* version.

Now we need to install it, running

```bash
sudo mod_wsgi-express install-module
```

This outputs something similar to

```bash
LoadModule wsgi_module "/usr/lib/apache2/modules/mod_wsgi-py35.cpython-35m-x86_64-linux-gnu.so"
WSGIPythonHome "/usr"
```

### Setting up Django databases for Interface

Interface (API and GUI) runs on Django.

In order for Django application to work, the internal SQLite database must be set up. For that, run

```bash
# Create schemas and then create corresponding tables
sudo python3 /var/www/ee-dev/opendata_module/interface/manage.py makemigrations && sudo python3 /var/www/ee-dev/opendata_module/interface/manage.py migrate
sudo python3 /var/www/ee-test/opendata_module/interface/manage.py makemigrations && sudo python3 /var/www/ee-test/opendata_module/interface/manage.py migrate
sudo python3 /var/www/xtee-ci-xm/opendata_module/interface/manage.py makemigrations && sudo python3 /var/www/xtee-ci-xm/opendata_module/interface/manage.py migrate
```

### Collecting static files for Apache

Static files are scattered during the development in Django. To allow Apache to serve the static files from one location, they have to be collected (copied to a single directory). Let's collect static files for all relevant instances.

```bash
sudo python3 /var/www/ee-dev/opendata_module/interface/manage.py collectstatic
sudo python3 /var/www/ee-test/opendata_module/interface/manage.py collectstatic
sudo python3 /var/www/xtee-ci-xm/opendata_module/interface/manage.py collectstatic
```


## 4. Configuring Apache

Let's create an Apache configuration file at **/etc/apache2/sites-available/opendata.conf** for port 80. 443 needs public domain address to order certs and we don't have that.

**Note:** The correct Python interpreter is derived from the loaded *wsgi_module*.

```bash
sudo nano /etc/apache2/sites-available/opendata.conf
```

```bash
<VirtualHost <machine IP>:80>
        ServerName <machine IP>
        ServerAdmin administrator@ci.kit

        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/opendata-error.log
        CustomLog ${APACHE_LOG_DIR}/opendata-access.log combined

        LoadModule wsgi_module "/usr/lib/apache2/modules/mod_wsgi-py35.cpython-35m-x86_64-linux-gnu.so"

        WSGIApplicationGroup %{GLOBAL}

        #### Open Data instances ####

        ## EE-DEV ##

        WSGIDaemonProcess ee_dev python-path=/var/www/html/ee-dev/monitor/opendata_module/interface:/var/www/html/ee-dev/monitor/opendata_module/interface/interface
        WSGIScriptAlias /ee-dev /var/www/html/ee-dev/monitor/opendata_module/interface/interface/wsgi.py process-group=ee_dev

        Alias /ee-dev/static /var/www/html/ee-dev/monitor/opendata_module/interface/static

        <Directory /var/www/html/ee-dev/monitor/opendata_module/interface/static>
                Require all granted
        </Directory>
        
        ## EE-TEST ##

        WSGIDaemonProcess ee_test python-path=/var/www/html/ee-test/monitor/opendata_module/interface:/var/www/html/ee-test/monitor/opendata_module/interface/interface
        WSGIScriptAlias /ee-test /var/www/html/ee-test/monitor/opendata_module/interface/interface/wsgi.py process-group=ee_test

        Alias /ee-test/static /var/www/html/ee-test/monitor/opendata_module/interface/static

        <Directory /var/www/html/ee-test/monitor/opendata_module/interface/static>
                Require all granted
        </Directory>
        
        ## XTEE-CI-XM ##

        WSGIDaemonProcess ee_xtee_ci_xm python-path=/var/www/html/xtee-ci-xm/monitor/opendata_module/interface:/var/www/html/xtee-ci-xm/monitor/opendata_module/interface/interface
        WSGIScriptAlias /xtee-ci-xm /var/www/html/xtee-ci-xm/monitor/opendata_module/interface/interface/wsgi.py process-group=xtee_ci_xm

        Alias /xtee-ci-xm/static /var/www/html/xtee-ci-xm/monitor/opendata_module/interface/static

        <Directory /var/www/html/xtee-ci-xm/monitor/opendata_module/interface/static>
                Require all granted
        </Directory>
</VirtualHost>
```

**Note:** `LoadModule wsgi_module '<path>'` must match the first line of `sudo mod_wsgi-express install-module` output from the previous section. It's safe to run it again.

**Note:** `hostname -I` is probably the easiest way to get machine's IP address for `<machine IP>`

**Note:** `<machine IP>` can be substituted with public domain name, once it's acquired.

After we have defined our *VirtualHost* configuration, we must enable the new *site* --- *opendata.conf* --- so that Apache could start serving it..

```bash
sudo a2ensite opendata.conf
```

Finally, we need to reload Apache in order for the site update to apply.

```bash
sudo service apache2 reload
```

## Extra security measures


#### Enforcing security upon users

Restrict ssh connections for users *anonymizer* and *opendata* by adding contstraints to `/etc/ssh/sshd_config`.

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo echo "AllowUsers anonymizer@<anonymizer_IP/domain_name>" >> `/etc/ssh/sshd_config`
sudo echo "AllowUsers opendata@localhost" >> `/etc/ssh/sshd_config`
sudo echo "AllowUsers your_user" >> `/etc/ssh/sshd_config`
```

#### Limit ssh connections to RIA network

```bash
sudo ufw allow from 10.0.24.42/24 to any port 22
``` 

#### Allow only SSH key based login

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo nano /etc/ssh/sshd_config
```

Disable the following features:

```bash
PasswordAuthentication no
ChallengeResponseAuthentication no
```

```bash
service ssh restart
```

## Scaling

* **Interface**
	Upscaling (more services): more RAM to handle larger log files.
	Upscaling (more end users): more CPUs and RAM for more simultaneous queries.

	Benefits from: disk space for ~Apache caching.

* **PostgreSQL**
	Main attribute: disk space.
	
	Upscaling (more X-Road instances): additional disk space.
	Upscaling (more services): additional disk space and RAM to handle more daily logs
	Upscaling (more end users): additional RAM and CPUs for more simultaneous queries.
	Upscaling (over time): additional disk space to store more logs.
	
	Benefits from: decent disk I/O speed (fast HDD or SSD, preferably), fast connection to Anonymizer and Interface components.

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

Static root is necessary only for GUI and holds the CSS and JS files to serve through Apache after `python manage.py collectstatic` has been issued. The most sensible path would direct to the Interface instance root directory.

If serving only a single X-Road instance:

```python
STATIC_ROOT = '/var/www/monitor/opendata_module/interface/static/'
```

Otherwise:

```python
STATIC_ROOT = '/var/www/instance_A/monitor/opendata_module/interface/static/'
```

## Test run


To test GUI and API, run

```bash
sudo python3 manage.py opendata_module/interface/runserver 0.0.0.0:80
```

By default the web interface will be served at http://localhost/gui.

**Note:** keeping it running with `nohup` and the aforementioned command is not scalable. Serve Interface using Apache.
