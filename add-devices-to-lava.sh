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

mkdir -p /etc/dispatcher-config/devices

# Create kernel-ci bundle stream
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevicetype=$csrf\&name=kernel-ci\&slug=kernel-ci\&user=2\&is_public="on"\&is_anonymous="on\&_save=Save"
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/dashboard_app/bundlestream/add/

devicetype=qemu-i386

# Add device type
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

devicename=qemu-i386-01

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicename=qemu-i386-02

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicetype=qemu-aarch64

# Add device type
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

devicename=qemu-aarch64-01

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicename=qemu-aarch64-02

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicetype=qemu-arm

# Add device type
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

devicename=qemu-arm-01

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicename=qemu-arm-02

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicetype=qemu-arm-cortex-a9

# Add device type
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

devicename=qemu-arm-cortex-a9-01

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicename=qemu-arm-cortex-a9-02

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicetype=qemu-arm-cortex-a15

# Add device type
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

devicename=qemu-arm-cortex-a15-01

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicename=qemu-arm-cortex-a15-02

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicetype=kvm

# Add device type
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevicetype=$csrf\&name=$devicetype\&display=on\&health_frequency=24\&_save=Save\&health_denominator=0
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevicetype -X POST $lavaurl/admin/lava_scheduler_app/devicetype/add/

devicename=kvm-01

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/

devicename=kvm-02

## Add device
csrf="csrfmiddlewaretoken="$(cat  ${tools_path}/cookies.txt | grep csrftoken | cut -d$'\t' -f 7)
createdevice=$csrf\&hostname=$devicename\&device_type=$devicetype\&device_version=1\&status=1\&health_status=0\&worker_host=$hostn
curl -b ${tools_path}/cookies.txt -c ${tools_path}/cookies.txt -d $createdevice -X POST $lavaurl/admin/lava_scheduler_app/device/add/
