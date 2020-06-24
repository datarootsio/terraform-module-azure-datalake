#!/bin/bash
echo "Executing on Driver: $DB_IS_DRIVER"
if [[ $DB_IS_DRIVER = "TRUE" ]]; then
LOG4J_PATH="/home/ubuntu/databricks/spark/dbconf/log4j/driver/log4j.properties"
else
LOG4J_PATH="/home/ubuntu/databricks/spark/dbconf/log4j/executor/log4j.properties"
fi
echo "Adjusting log4j.properties here: ${LOG4J_PATH}"
sed -i 's/rootCategory=INFO/rootCategory=WARN/g' $LOG4J_PATH