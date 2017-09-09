# Elasticsearch Setup and Configuration

## Setup

### Install Elasticsearch

Get java from Oracle (8 or newer)

```
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java8-installer
java -version
```

Get Elasticsearch

```
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.4.0.deb 

sudo dpkg -i elasticsearch-5.4.0.deb

sudo apt-get install -f

sudo update-rc.d elasticsearch defaults
```



## Configuration

### Data and Log files

* configuration files in /etc/elasticsearch
* log files in /var/log/elasticsearch


### Limit Elasticsearch to run localhost

sudo vim /etc/elasticsearch/elasticsearch.yml

```
network.host: localhost
```


## Install Kibana


```
wget https://artifacts.elastic.co/downloads/kibana/kibana-5.4.0-amd64.deb

sudo dpkg -i kibana-5.4.0-amd64.deb

sudo apt-get install -f
```
