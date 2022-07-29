#/bin/bash

# start postgresql
service postgresql start

SCRIPT_PATH=/bucardo/scripts/

# run scrips
ls $SCRIPT_PATH/*.sh &> /dev/null || {
  echo "No scripts found in /bucardo/scripts. Stopping"
  exit 1
}

for s in $SCRIPT_PATH/*.sh; do
source $s
done
