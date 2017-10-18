# Opendata template

## Eesti keeles

<!DOCTYPE html>
<html>
    <head>
        <title>RIA OpenData</title>

        {% load static %}
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.9.0/moment.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datetimepicker/4.7.14/js/bootstrap-datetimepicker.min.js"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js"></script>
        <script src="https://cdn.datatables.net/1.10.15/js/jquery.dataTables.min.js"></script>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datetimepicker/4.7.14/css/bootstrap-datetimepicker.min.css" rel="stylesheet"/>
        <link rel="stylesheet" href="https://cdn.datatables.net/1.10.15/css/jquery.dataTables.min.css">
        <link href="{% static 'gui/index.css' %}" rel="stylesheet"/>

    </head>
    <body>
        <div class="container">

            <div class="page-header">
                <h3>RIA OpenData Module</h3>
            
<table width="100%" border="0">
<tr>
<th align="left" valign="top"><img src="x-road.png" alt="X-tee" width="196" height="78"></th>
<th align="right" valign="top"><img src="eu.jpg" alt="Euroopa Liit Euroopa Regionaalarengu Fond | Eesti tuleviku heaks" width="356" height="206"></th>
</tr>
</table>

            </div>

            <form method="get" id="download-form">
                <div class="panel panel-info">
                    <div class="panel-heading">
                        <b>Date</b>
                    </div>
                    <div class="panel-body">
                        <div class="row">
                            <div class="col-md-2">
                                <div class="form-group">
                                    <input type="text" name="date" class="form-control" id="date"/>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="panel panel-info">
                    <div class="panel-heading">
                        <b>Columns</b>
                    </div>
                    <div class="panel-body">
                        <div class="form-group">
                            <label class="radio-inline">
                                <input type="radio" name="column-selection-type" value="all" checked="checked"> Select all columns
                            </label>
                            <label class="radio-inline">
                                <input type="radio" name="column-selection-type" value="subset"> Subset of columns
                            </label>
                        </div>

                        <hr />

                        <div class="form-group">
                            <select class="form-control" size={{column_count}} id="selected-columns" multiple>
                            {% for column_datum in column_data %}
                                <option value="{{column_datum.name}}">{{column_datum.name}}</option>
                            {% endfor %}
                            </select>
                        </div>
                    </div>
                </div>

                <div class="panel panel-info">
                    <div class="panel-heading">
                        <b>Constraints</b>
                    </div>
                    <div class="panel-body">
                        <div>
                            <div class="form-inline">
                                <select class="form-control" id="new-constraint-column">
                                {% for column_datum in column_data %}
                                    <option value="{{column_datum.name}}" data-type="{{column_datum.type}}">{{column_datum.name}}</option>
                                {% endfor %}
                                </select>

                                <select class="form-control" id="new-constraint-operator"></select>

                                <input type="text" class="form-control" id="new-constraint-value" placeholder="Value">

                                <button class="btn btn-warning" id="add-constraint-btn">Add constraint</button>
                            </div>

                            <hr />

                            <div id="constraints"></div>
                        </div>
                    </div>
                </div>

                <div class="panel panel-info">
                    <div class="panel-heading">
                        <b>Order clauses</b>
                    </div>
                    <div class="panel-body">
                        <div class="form-inline">
                            <div class="form-group">
                                <select class="form-control" id="new-order-clause">
                                {% for column_datum in column_data %}
                                    <option value="{{column_datum.name}}">{{column_datum.name}}</option>
                                {% endfor %}
                                </select>
                            </div>

                            <div class="form-group">
                                <select class="form-control" id="new-order-direction">
                                    <option value="asc">ascending</option>
                                    <option value="desc">descending</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <button class="btn btn-warning" id="add-order-clause-btn">Add order clause</button>
                            </div>
                        </div>

                        <hr />

                        <div id="order-clauses"></div>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary pull-right" id="download-btn">Download</button>
                <button class="btn btn-success pull-right" id="preview-btn">Preview</button>
            </form>

            <div class="clearfix"></div>

            <div id="datatable"></div>

            <hr />

            <!-- div>{{disclaimer | safe}}</div -->
<div><p><small>X-tee monitooring avaandmetena on valminud EL struktuuritoetuse toetusskeemi "EL SF toetusskeem "Infoühiskonna teadlikkuse tõstmine" meetme "Nutika teenuse taristu arendamine" raames Euroopa Regionaalarengu Fondi rahastusel.</small></p>
</div>

        </div>


        <script>$("#date").datetimepicker({format : "YYYY-MM-DD",
                minDate: moment("{{min_date}}", "MMM DD, YYYY"), maxDate: moment("{{max_date}}", "MMM DD, YYYY")});
        </script>
        <script src="{% static 'gui/index.js' %}"></script>
    </body>
</html>

## Inglise keeles

<div class="page-header">
<table width="100%" border="0">
<tr>
<th align="left" valign="top"><img src="x-road.png" alt="X-Road" width="196" height="78"></th>
<th align="right" valign="top"><img src="eu.jpg" alt="European Union European Regional Development Fund | Investing in your future" width="356" height="206"></th>
</tr>
</table>
</div>
<hr size="1">

Content

<hr size="1">
<div class="page-footer">
<p><small>The X-Road monitoring materials have been compiled with funding from the structural funds support scheme “Raising Public Awareness about the Information Society” of the European Regional Development Fund.</small></p>
</div>
