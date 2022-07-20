#/bin/bash

# start postgresql
service postgresql start

echo "check bucardo.sh file"
[ -e /media/bucardo/bucardo.sh ] || {
  echo "Missing bucardo.sh file"
  exit 1
}

# run bucardo commands from file
chmod +x /media/bucardo/bucardo.sh
su -c '/media/bucardo/bucardo.sh' postgres