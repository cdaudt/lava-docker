docker run -it \
  -v /boot:/boot \
  -v /lib/modules:/lib/modules \
  -v $PWD/fileshare:/fileshare \
  -v /dev/bus/usb:/dev/bus/usb \
  -v /home/csd/.ssh/id_rsa.pub:/home/lava.ssh/authorized_keys:ro \
  --device=/dev/ttyUSB0 \
  -p 8000:80 \
  -p 5555:5555 \
  -p 5556:5556 \
  -p 2022:22 \
  -h lava-docker \
  --privileged \
  lava-master $*
