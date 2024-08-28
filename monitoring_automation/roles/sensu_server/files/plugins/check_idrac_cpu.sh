#!/bin/bash

CHECK="$(/etc/sensu/plugins/idrac_2.2rc4 -H $1 -v2c -c public -w SENSOR | awk '/CPU/ {print $5}')"

for i in $CHECK; do
  if [ "$i" != "ENABLED/OK" ]; then
    echo "WARNING! Idrac CPU Health state is degraded"
    exit 1
  else
    echo "Idrac CPU state is OK!"
    exit 0
fi

done

echo "IDRAC CPU is in Unknown Error State"
exit 3
