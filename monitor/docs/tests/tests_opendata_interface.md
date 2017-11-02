
| [![Republic of Estonia Information System Authority](../img/ria_100_en.png)](https://www.ria.ee/en/) [![X-ROAD](../img/xroad_100_en.png)](https://www.ria.ee/en/x-road.html) | ![European Union / European Regional Development Fund / Investing in your future](../img/eu_rdf_100_en.png "Documents that are tagged with EU/SF logos must keep the logos until 1.11.2022. If it has not stated otherwise in the documentation. If new documentation is created  using EU/SF resources the logos must be tagged appropriately so that the deadline for logos could be found.") |
| :-------------------------------------------------- | -------------------------: |

# X-Road v6 monitor project - Open Data Interface Test

## Setup

Once the Interface is set up as instructed in Open Data Node 2 installation instructions [here](../opendata/interface_postgresql.md), let's temporarily modify the `settings.py` and populate the dynamically created `logs` table in the `opendata_ci_test` database, which was created in [Node 2's PostgreSQL section](../opendata/interface_postgresql.md#postgresql).

### Modify _settings.py_

**Note:** Since `interface_${INSTANCE}` user has no write permissions in `opendata_${INSTANCE}` database, the populating script has to use the `opendata_ci_test` database. To do that, the _POSTGRES_CONFIG_ `database_name`, `user`, and `password` parameters have to be temporarily changed in `settings.py`.

```bash
sudo echo "POSTGRES_CONFIG['database_name'] = 'opendata_ci_test'" >> ${WEBDIR}/${INSTANCE}/opendata_module/interface/interface/settings.py
sudo echo "POSTGRES_CONFIG['user'] = 'ci_test'" >> ${WEBDIR}/${INSTANCE}/opendata_module/interface/interface/settings.py
sudo echo "POSTGRES_CONFIG['password'] = 'ci_test'" >> ${WEBDIR}/${INSTANCE}/opendata_module/interface/interface/settings.py
```

Reload Django with new settings:

```bash
sudo service apache2 reload
```

### Populate _opendata_ci_test_ database

```python
python3 ${WEBDIR}/${INSTANCE}/opendata_module/interface/tests/manual/create_example_table.py
```

This script loads 100 predefined development logs into the `logs` table.

### Validation

#### Initial page

After navigating to `http://server_address/{ee-dev,ee-test,EE}/gui`, we should see the following page:

![Initial Interface page](../img/opendata/1_interface_initial_screen.png "Initial Interface page")

#### Date constraint

Click on the **Date** section and it should show 

![Interface datetimepicker](../img/opendata/2_interface_datetimepicker.png "Interface datetimepicker")

The dataset has data only from September 19, 2017 to September 25, 2017. Those should be the only selectable dates.

After selecting September 19 and clicking on the green "Preview" button, we should see both of the entries from the day:

![Interface datetimepicker](../img/opendata/3_interface_sept_19_preview.png
 "Interface datetimepicker")

#### Column constraints

When we change the date to September 20, 2017 and select "id", "messageid", and "totalDuration"

![Interface datetimepicker](../img/opendata/4_interface_20_sept_col_subset_1.png
 "Interface datetimepicker")
 
after clicking "Preview" again, we should see
 
![Interface datetimepicker](../img/opendata/4_interface_20_sept_col_subset_2.png
 "Interface datetimepicker")

#### Value and order constraints

When ignoring entries with "None" value and requesting only entries with "id" greater than 10 and ordering by ascending "totalDuration"

![Interface datetimepicker](../img/opendata/5_interface_20_sept_constraints_1.png
 "Interface datetimepicker")

we should see:

![Interface datetimepicker](../img/opendata/5_interface_20_sept_constraints_2.png
 "Interface datetimepicker")

#### Downloading

When clicking on "Download" instead of "Preview", the browser should initiate a "2017-09-20@download_timestamp.tar.gz" file download. The contents should look similar to

![Interface datetimepicker](../img/opendata/6_interface_download_content.png
 "Interface datetimepicker")

### Finally

Drop the example `logs` table.

```python
python3 ${WEBDIR}/${INSTANCE}/opendata_module/interface/tests/manual/drop_example_table.py
```

Undo the changes to the `settings.py`.

**Note:** Redirecting `tee` output to dev null to prevent displaying the whole `settings.py` content in the terminal.

```bash
sudo head --lines -3 ${WEBDIR}/${INSTANCE}/opendata_module/interface/interface/settings.py | sudo tee ${WEBDIR}/${INSTANCE}/opendata_module/interface/interface/settings.py > /dev/null
```

Reload Django with old settings:

```bash
sudo service apache2 reload
```