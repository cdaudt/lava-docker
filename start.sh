#!/bin/bash

postgres-ready () {
  echo "[ ok ] LAVA server ready"
}

start () {
  echo "Starting $1"
  if (( $(ps -ef | grep -v grep | grep -v add_device | grep -v dispatcher-config | grep "$1" | wc -l) > 0 ))
  then
    echo "$1 appears to be running"
  else
    service "$1" start
  fi
}

# Finish config of lava-server
echo "Configuring Lava user"
/cfg_postgres.sh || (echo "Failed to setup postgres users";exit 1)
echo "Done configuring Lava user"
#remove lava-pid files incase the image is stored without first stopping the services
rm -f /var/run/lava-*.pid 2> /dev/null

start apache2
start gunicorn
start lava-server
start lava-server-gunicorn
start lava-master
start lava-slave

postgres-ready
service apache2 reload #added after the website not running a few times on boot

echo "Waiting for apache to settle"
sleep 30
