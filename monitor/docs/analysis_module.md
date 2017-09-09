# X-Road project - Analysis Module


## About

The Analysis module is responsible for detecting and presenting anomalies in the usage of X-road instruments. The Analysis module consists of two parts:

**Analyzer: ** the back-end of the analysis module, responsible for detecting anomalies based on requests made via the X-road platform.
**Interface: ** the front-end of the analysis module, responsible for presenting the found anomalies to the user and recording user feedback.

## Installation (Linux)

The Analysis module is implemented in Python 3.5.2. Although not tested, it should work with any modern Python 3.x version.

#### Dependencies

**Analyzer: ** pandas, numpy, scipy, pymongo, dill
**Interface: ** django, pymongo, numpy

In order to install the dependencies with pip:
```bash
pip install -r analysis_module/analyzer/requirements.txt
pip install -r analysis_module/analyzer_ui/requirements.txt
```

## Networking

Port 80 must be open for web server.

```bash
sudo apt-get install ufw
sudo ufw enable
sudo ufw allow 22
sudo ufw allow 80
```

## Models

In the core of the Analyzer are *models* that are responsible for detecting different types of anomalies. The model classes are located in the folder **analysis_module/analyzer/models**.

** 1. FailedRequestRatioModel.py** (anomaly type 4.3.1): aggregates requests for a given service call by a given time interval (e.g. 1 hour) and checks if the ratio of failed requests (```succeeded=False```) with respect to all requests in this time interval is larger than a given threshold. The type of found anomalies (```anomalous_metric```) will be failed_request_ratio.

** 2. DuplicateMessageIdModel.py** (anomaly type 4.3.2):  aggregates requests for a given service call by a given time interval (e.g. 1 day) and checks if there are any duplicated ```messageId``` in that time interval. The type of found anomalies (```anomalous_metric```) will be duplicate_message_id.

** 3. TimeSyncModel.py** (anomaly type 4.3.3): for each request, checks if the time of data exchange between client and producer is a positive value. Namely, an incident is created if ```requestNwSpeed < 0``` or ```responseNwSpeed < 0```. In each incident, the number of requests not satisfying these conditions are aggregated for a given service call and a given time interval (e.g. 1 hour). The type of found anomalies (```anomalous_metric```) will be one of [responseNwDuration, requestNwDuration].

** 4. AveragesByTimeperiodModel.py** (anomaly types 4.3.5-4.3.9) :  aggregates requests for a given service call by a given time interval, calculating:
1) the number or requests in this time interval,
2) mean request size (if exists --- ```clientRequestSize```, otherwise ```producerRequestSize```) in this time interval,
3) mean response size (if exists --- ```clientResponseSize```, otherwise ```producerResponseSize```) in this time interval,
4) mean request duration (```totalDuration```) in this time interval,
5) mean response duration (```producerDurationProducerView```) in this time interval.
Each of these metrics are compared to historical values for the same service call during a similar time interval (e.g. on the same weekday and the same hour). In particular, the model considers the mean and the standard deviation (std) of historical values and calculates the *z-score* for the current value: ```z_score = abs(current_value - historic_mean) / historic_std```.
Based on this score, the model estimates the confidence that the current value comes from a different distribution than the historic values. If the confidence is higher than a specified confidence threshold, the current value is reported as a potential incident. The type of found anomalies (```anomalous_metric```) will be one of [request_count, mean_request_size, mean_response_size, mean_request_duration, mean_response_duration].
 

## Scripts

Before finding anomalies using the AveragesByTimeperiodModel, the model needs to be trained. Namely, it needs to calculate the historic means and standard deviations for each relevant time interval. The data used for training should be as "normal" (anomaly-free) as possible. Therefore, it is recommended that the two phases, training and finding anomalies, use data from different time periods. 
Therefore, the following approach is suggested:
1) For recent requests, the model is used to *find* anomalies, which will be recorded as potential incidents.
2) The found anomalies are shown in the Analyzer UI for a specified time period (e.g. 1 week), after which they are considered "expired" and will not be shown anymore.
3) Anomalies/incidents that have expired are used to update (or retrain) the model. Requests that are part of a "true incident" (an anomaly that was marked as "incident" before the expiration date) are not used to update the model. This way, the the historic averages remain to describe the "normal" behaviour.
Also, as the model aggregates requests for certain time intervals (e.g. hour), it is recommended to use data only from time intervals that have already completed. This is to avoid cases where, for example, the number of requests within 10 minutes is compared to the (historic) number of requests within 1 hour, as such comparison would almost certainly yield an anomaly. 

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




## Configuration

### Back-end

The Analyzer back-end can be configured from **analysis_module/analyzer/analyzer_conf.py**.

| Parameter   |      Description      |  Example |
|:----------:|:-------------:|:------:|
| timestamp_field | Database field to use as the primary timestamp in the analysis. | timestamp_field = 'requestInTs' |
| service_call_fields |    Database fields that (together) define a service call.   |   service_call_fields = ["clientMemberClass", "clientMemberCode", "clientXRoadInstance", "clientSubsystemCode", "serviceCode", "serviceVersion", "serviceMemberClass", "serviceMemberCode", "serviceXRoadInstance", "serviceSubsystemCode"] |
| relevant_cols_general | Database fields from the clean_data collection that are relevant for the analyzer and appear at the top level of the request. | relevant_cols_general = ["_id", 'totalDuration', 'producerDurationProducerView', 'requestNwDuration', 'responseNwDuration'] |
| relevant_cols_nested | Database fields from the clean_data collection that are relevant for the analyzer and are nested inside 'client' and 'producer'. | relevant_cols_nested = ["succeeded", "messageId", timestamp_field] + service_call_fields |
| relevant_cols_general_alternative |  Database fields from the clean_data collection that are relevant for the analyzer and appear at the top level of the request, but are analogous for 'client' and 'producer' side. <br> For the Analyzer, only one field from each pair is necessary. In other words, if the field exists for the client side, then this value is used, otherwise the value from the producer side is used. <br> In configuration, these fields are presented as triplets, where the first element refers to the general name used in the Analyzer, the second and third value are the alternative fields in the database. | relevant_cols_general_alternative = [('requestSize', 'clientRequestSize', 'producerRequestSize')] | 
<timeunit\>_aggregation_time_window | Settings for a given aggregation time window. The following attributes should be speficied:  <br> 1) 'agg_window_name' - a name (can be chosen arbitrarily) that will be used to refer to the aggregation window,  <br>2) 'agg_minutes' - number of minutes to use for aggregation, <br> 3) 'pd_timeunit' - used in the pandas.to_timedelta method to refer to the same time period, should be one of (D,h,m,s,ms,us,ns). (https://pandas.pydata.org/pandas-docs/stable/generated/pandas.to_timedelta.html). | hour_aggregation_time_window = \{'agg_window_name': 'hour', 'agg_minutes': 60, 'pd_timeunit': 'h'}| 
| <timeunits\>_similarity_time_window | Settings for a given similarity time window. For example, if the aggregation time window is hour, the similarity time window can be hour+weekday, meaning that the aggregated values from a given hour are compared to historic values collected from the same hour on the same weekday. The following attributes should be speficied:  <br> 1)  'timeunit_name' - a name (can be chosen arbitrarily) that will be used to refer to the similarity window, <br> 2) 'agg_window' - one of <timeunit\>_aggregation_time_window, <br> 3) 'similar_periods' - a list of time periods. A given set of aggregated requests will be compared to the combination of these periods. Each value in the list is used to extract the necessary time component from a pandas.DatetimeIndex object, so each value should be one of (year, month, day, hour, minute, second, microsecond, nanosecond, dayofyear, weekofyear, week, dayofweek, weekday, quarter). (http://pandas.pydata.org/pandas-docs/version/0.17.0/api.html#time-date-components) | hour_weekday_similarity_time_window = {'timeunit_name': 'hour_weekday', 'agg_window': hour_aggregation_time_window, 'similar_periods': ['hour', 'weekday']\} | 
| time_windows | A dictionary of pairs (anomaly_type, previously defined <timeunit\>_aggregation_time_window) for anomaly types that do not require comparison with historic values. The specified time window will be used to aggregate requests for the given anomaly type. | time_windows = \{ <br> "failed_request_ratio": hour_aggregation_time_window, <br> "duplicate_message_ids": day_aggregation_time_window, <br> "time_sync_errors": hour_aggregation_time_window} |
| historic_averages_time_windows | A list of previously defined <timeunits\>_similarity_time_windows for anomaly types that require comparison with historic averages. A separate AveragesByTimeperiodModel is constructed for each such similarity time window. | historic_averages_time_windows = [hour_weekday_similarity_time_window, weekday_similarity_time_window] |
| historic_averages_thresholds | A dictionary of confidence thresholds used in the AveragesByTimeperiodModel(s). An observation (an aggregation of requests within a given time window) is considered an anomaly if the confidence (estimated by the model) of being an anomaly is larger than this threshold. | historic_averages_thresholds = \{ <br> 'request_count': 0.997, <br> 'mean_request_size': 0.95, <br> 'mean_response_size': 0.95, <br> 'mean_client_duration': 0.95, <br> 'mean_producer_duration': 0.95} ] |
| time_sync_monitored_lower_thresholds | A dictionary of minimum value thresholds used in the TimeSyncModel. If the observed value is smaller than this threshold, an incident is reported. | time_sync_monitored_lower_thresholds = \{'requestNwDuration': 0, <br> 'responseNwDuration': 0} |
| failed_request_ratio_threshold | Used in the FailedRequestRatioModel. If the ratio of failed requests in a given aggregation window is larger than this threshold, an incident is reported. | failed_request_ratio_threshold = 0.9 |
| SAVED_MODELS_DIR | A directory where the trained AveragesByTimeperiodModel(s) are saved. | SAVED_MODELS_DIR = "saved_models" |
| incident_expiration_time | After this time has passed since the creation of an anomaly (potential incident), the requests involved in these anomalies can be used to update the historic averages models. The time is specified in minutes. It is recommended to keep this parameter the same as the respective parameter in the front-end configuration. | incident_expiration_time = 10080 <br> (anomalies will expire after 1 week) |


### Front-end

The user interface can be configured from **analysis_module/analyzer_ui/gui/gui_conf.py**.

| Parameter   |      Description      |  Example |
|:----------:|:-------------:|:------:|
| service_call_fields |    Database fields that (together) define a service call.   |   service_call_fields = ["clientMemberClass", "clientMemberCode", "clientXRoadInstance", "clientSubsystemCode", "serviceCode", "serviceVersion", "serviceMemberClass", "serviceMemberCode", "serviceXRoadInstance", "serviceSubsystemCode"] |
| new_incident_columns | List of columns that will be shown in the incident table (where *new* anomalies are presented). Each column is represented by a tuple, containing the following elements: <br> 1) the name of the column (can be chosen arbitrarily) <br> 2) the respective database field in the incident collection, <br> 3) the data type of the column, must be one of (categorical, numeric, date, text), <br> 4) the rounding precision (only relevant if the data type is numeric), <br> 5) the date format to be used (only relevant if the data type is date) | new_incident_columns = [ <br> ("anomalous_metric", "anomalous_metric", "categorical", None, None), <br> ("anomaly<br\>confidence", "anomaly_confidence", "numeric", 2, None), <br> ("period_start_time", "period_start_time", "date", None, "%a, %Y-%m-%d %H:%M"), <br> ("description", "description", "text", None, None), <br> ("request_count", "request_count", "numeric", 0, None)] |
| new_incident_order | A list of conditions to use for ordering the incidents table. Each condition contains two elements: <br> 1) database field name, must be one of the database fields defined in new_incident_columns, <br> 2) order direction, must be one of (asc, desc) | new_incident_order = [["request_count", "desc"]] |
| historical_incident_columns | List of columns that will be shown in the history table (where anomalies whose status has already been marked by the user are presented). Each column is represented by a tuple, containing the following elements: <br> 1) the name of the column (can be chosen arbitrarily) <br> 2) the respective database field in the incident collection, <br> 3) the data type of the column, must be one of (categorical, numeric, date, text), <br> 4) the rounding precision (only relevant if the data type is numeric), <br> 5) the date format to be used (only relevant if the data type is date) | historical_incident_columns = [<br> ("incident_status", "incident_status", "categorical", None, None), <br> ("incident_update_timestamp", "incident_update_timestamp", "date", None, "%a, %Y-%m-%d %H:%M")]|
| historical_incident_order | A list of conditions to use for ordering the history table. Each condition contains two elements: <br> 1) database field name, must be one of the database fields defined in new_incident_columns, <br> 2) order direction, must be one of (asc, desc) | historical_incident_order = [["incident_update_timestamp", "desc"]] |
| relevant_fields_for_example_requests_general | A list of database fields from the clean_data collection, which appear at the top level of the request, to be shown in the *example requests* table. | relevant_fields_for_example_requests_general = ['totalDuration', 'producerDurationProducerView'] |
| relevant_fields_for_example_requests_nested | A list of database fields from the clean_data collection, which are nested inside 'client' and 'producer', to be shown in the *example requests* table. | relevant_fields_for_example_requests_nested = ['messageId', 'requestInTs', 'succeeded'] |
| relevant_fields_for_example_requests_alternative | A list of database fields from the clean_data collection, which appear at the top level of the request but are analogous for 'client' and 'producer' side, to be shown in the *example requests* table. | relevant_fields_for_example_requests_alternative = [<br>('responseSize', 'clientResponseSize', 'producerResponseSize'),<br>('requestSize', 'clientRequestSize', 'producerRequestSize')] |
| example_request_limit | Up to this many "example" requests will be shown for each anomaly. | example_request_limit = 10 |
| accepted_date_formats | When filtering anomalies according to a date field, the user input must be in one of these date formats. | accepted_date_formats = ["%a, %Y-%m-%d %H:%M", "%Y-%m-%d %H:%M", "%Y-%m-%d", "%d/%m/%Y %H:%M", "%d/%m/%Y"] |
| incident_expiration_time | An anomaly will be shown in the user interface only until this time has passed since the creation of the anomaly. The time is specified in minutes. It is recommended to keep this parameter the same as the respective parameter in the back-end configuration. | incident_expiration_time = 10080 <br> (anomalies will expire after 1 week) |

### Database
In order to work properly, both the back-end and front-end of the Analysis module need configurations for accessing the database. These settings are specified separately:

**Analyzer:** analysis_module/analyzer/db_conf.py
**Interface:** analysis_module/analyzer_ui/gui/db_conf.py
  
In general, these settings may remain unchanged.

## Databases

The Analyzer takes as input data from the clean_data database. The results will be written to incident database (a MongoDB instance). Namely, there are two collections in the incident database:

**incident:** All found anomalies will be saved here, as well as the last status of each anomaly/incident (automatic or marked by the user).
**incident_timestamps:** This collection keeps track of the times when the historic averages model was last updated. Also, the last anomaly-finding times for each anomaly type will be saved here.

### Incident collection schema

All found anomalies (potential incidents) are saved in the *incident* collection. Each entry in this collection contains the following fields:

| Field   |      Description      |  Possible values  and data type |
|:----------:|:-------------:|:------:|
| _id | Automatically generated id for the collection entry. | A MongoDB ObjectId value. |
| aggregation_timeunit | The time interval used to aggregate requests for this anomaly. | hour, day (categorical) |
| period_start_time | Start time (included) of the aggregation time interval used for this anomaly. | (date) |
| period_end_time | End time (excluded) of the aggregation time interval used for this anomaly. | (date) |
| request_count | Number of requests in the aggregation time interval. | (numeric) |
| request_ids | List of request id-s included in this anomaly. | List of MongoDB ObjectId-s. |
| anomalous_metric | The anomaly type | failed_request_ratio, duplicate_message_id, responseNwDuration, requestNwDuration, request_count, mean_request_size, mean_response_size, mean_request_duration, mean_response_duration (categorical) |
| monitored_metric_value | The observed value, e.g. the observed mean request size for the mean_request_size anomaly, or the number of duplicated message ids in case of the duplicate_message_id anomaly. | (numeric) |
| difference_from_normal | Difference of the observed value and the "normal" value. The "normal" value is: <br> 1) the historic average in case of historic average anomalies, <br> 2) the failed request ratio threshold (the largest allowed value) in case of failed request ratio anomalies, <br> 3) 1 in case of duplicate message id anomalies, <br> 4) 0 in case of time sync anomalies. | (numeric) |
| anomaly_confidence | Confidence of the anomaly, as estimated by the model. The higher the confidence, the more it deviates from the historical values. Anomaly types that do not require comparison with historic values always have a confidence of 1. | Between 0 and 1. (numeric) |
| description | Textual description of the anomaly. |  (text) |
| incident_creation_timestamp | Time when the incident was created. | (date) | 
| incident_update_timestamp | Time when the incident was last updated. If the status has not yet been marked by the user, this is the same as the incident_creation_timestamp, otherwise the time of the last status update. | (date) |
incident_status | The status of the incident. Can be automatically assigned (new, showed), or marked by the user (incident, viewed, normal). | new, showed, incident, viewed, normal (categorical) | 
| model_params | If relevant, some parameters of the model that was used to find the anomaly. | For example, the model_params for anomaly type mean_request_size is a dictionary: <br> 'model_params': \{'hour': 9, <br>  'metric_mean': 1729.4074074074076, <br>   'metric_std': 42.25904826772402, <br>   'model_timeunit': 'hour_weekday', <br>   'weekday': 1} |
| model_version | Version of the model that was used to find the anomaly. | from 0 to any integer (numeric) |
| clientMemberClass | The clientMemberClass (part of the service call) whom this anomaly belongs to.| |
| clientMemberCode | The clientMemberCode (part of the service call) whom this anomaly belongs to.| |
| clientSubsystemCode | The clientSubsystemCode (part of the service call) whom this anomaly belongs to.| |
| clientXRoadInstance | The clientXRoadInstance (part of the service call) whom this anomaly belongs to.| |
| serviceCode | The serviceCode (part of the service call) whom this anomaly belongs to.| |
| serviceMemberClass | The serviceMemberClass (part of the service call) whom this anomaly belongs to.| |
| serviceMemberCode | The serviceMemberCode (part of the service call) whom this anomaly belongs to.| |
| serviceSubsystemCode | The serviceSubsystemCode (part of the service call) whom this anomaly belongs to.| |
| serviceVersion | The serviceVersion (part of the service call) whom this anomaly belongs to.| |
| serviceXRoadInstance | The serviceXRoadInstance (part of the service call) whom this anomaly belongs to.| |

### Incident timestamps collection schema

This collection is used internally, to ensure that the scripts for finding anomalies and for updating the historic averages model take as input data from the right time period. In particular, each request should only be used once by each model in both the anomaly finding and model updating phase.  Each entry in this collection contains the following fields:

| Field   |      Description      |  Possible values |
|:----------:|:-------------:|:------:|
| _id | Automatically generated id for the collection entry. | A MongoDB ObjectId value. |
| model | The name of the Analyzer model. | hour_weekday, weekday, failed_request_ratio, duplicate_message_ids, time_sync_errors |
| type | Type of the timestamp. | last_fit_timestamp, last_transform_timestamp |
| timestamp | The timestamp. | A datetime value. |
