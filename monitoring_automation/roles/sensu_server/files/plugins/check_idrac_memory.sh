#!/bin/bash

CHECK="$(/etc/sensu/plugins/idrac_2.2rc4 -H $1 -v2c -c public -w MEM | awk '/Memory/ {print $9}')"

for i in $CHECK; do
  if [ "$i" != "ENABLED/OK" ]; then
    echo "WARNING! Idrac Health Memory state is degraded"
    exit 1
  else
    echo "Idrac Memory state is OK!"
    exit 0
fi

done

echo "IDRAC Memory is in Unknown Error State"
exit 3
