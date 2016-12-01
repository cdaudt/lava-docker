#!/bin/bash
#Create a qemu devices and add them to lava-server

lava-server manage pipeline-worker --hostname $(hostname)

curdir="$(dirname "$(readlink -f "$0")")"
if [ -f "${curdir}/lava-credentials.txt" ]; then
  . "${curdir}"/lava-credentials.txt
fi

lavaurl=http://localhost
tools_path="${tools_path:-/home/lava/bin}"
hostn=$(hostname)

#obtain the csrf token
data=$(curl -s -c ${tools_path}/cookies.txt $lavaurl/accounts/login/); tail ${tools_path}/cookies.txt

#login
csrf="csrfmiddlewaretoken="$(grep csrftoken ${tools_path}/cookies.txt | cut -d$'\t' -f 7); echo "$csrf"
login=$csrf\&username=$adminuser\&password=$adminpass; echo $login
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $login -X POST $lavaurl/admin/login/

#create workers
${tools_path}/setup_server.py --url ${lavaurl} /fileshare/cfg/server.json

mkdir -p /etc/dispatcher-config/devices

devicename=943907AEVAL1F-1
devicetype=943907AEVAL1F
## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&is_pipeline="on"\&worker_host=${WORKER}
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/
lava-server manage device-dictionary --hostname $devicename --import /etc/dispatcher-config/devices/$devicename.jinja2
