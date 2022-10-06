#/bin/bash
SCRIPT_PATH=/bucardo/scripts/

# start postgresql
service postgresql start > /dev/null 

# run scrips
ls $SCRIPT_PATH/*.sh &> /dev/null || {
  echo "No scripts found in /bucardo/scripts. Stopping"
  exit 1
}

# source all scripts in SCRIPT_PATH
for s in $SCRIPT_PATH/*.sh; do
source $s
done
