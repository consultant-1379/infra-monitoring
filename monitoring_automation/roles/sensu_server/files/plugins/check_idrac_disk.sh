#!/bin/bash

CHECK="$(/etc/sensu/plugins/idrac_2.2rc4 -H $1 -v2c -c public -w DISK  | awk '/PDisk/ {print $6}')"

for i in $CHECK; do
  if [ "$i" != "ONLINE," ]; then
    echo "WARNING! Idrac Disk Health state is degraded"
    exit 1
  else
    echo "Idrac Disk state is OK!"
    exit 0
fi

done

echo "IDRAC Disk is in Unknown Error State"
exit 3
