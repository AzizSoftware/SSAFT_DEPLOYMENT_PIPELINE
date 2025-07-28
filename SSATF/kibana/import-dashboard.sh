#!/bin/sh

echo "$(date)  Kibana is healthy! Importing dashboard..."

curl -X POST "http://kibana:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  --form file=@/dashboards/export.ndjson

echo "$(date)  Dashboard imported successfully!"
