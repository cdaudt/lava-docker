FROM debian:jessie-backports

# Add linaro staging repo
RUN apt-get clean && \
 apt-get update && \
 apt-get install -y wget

RUN cd /tmp && \
 wget http://images.validation.linaro.org/production-repo/production-repo.key.asc &&  \
 apt-key add production-repo.key.asc  && \
 echo "deb http://images.validation.linaro.org/production-repo sid main"  >>/etc/apt/sources.list.d/linaro.list

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name
RUN \
 echo 'lava-server   lava-server/instance-name string lava-docker-instance' | debconf-set-selections \
 && echo 'lava-server   lava-server/db-server string lavadb' | debconf-set-selections \
 && echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections \
 && echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections \
 && apt-get update

RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 cu \
 expect \
 locales \
 openssh-server \
 screen \
 sudo \
 gunicorn \
 vim
RUN  \
 DEBIAN_FRONTEND=noninteractive apt-get install -y -t jessie-backports \
 python-django \
 python-django-tables2
RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 qemu-system
RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 mdadm mtools nfs-common \
 nfs-kernel-server ntfs-3g \
 ntp openbsd-inetd
RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 python-xdg python-yaml python-zmq \
 python-zope.interface reiserfsprogs \
 rsync scrub ser2net sshfs supermin \
 syslinux syslinux-common telnet \
 tftpd-hpa u-boot-tools unzip \
 xfsprogs xkb-data xz-utils zerofree
RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 apache2 binutils \
 bridge-utils busybox bzip2 \
 console-setup cryptsetup docutils-common

RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 lava-server-doc \
 lava-tool \
 lava-coordinator
RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 lava-dispatcher
RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 gdebi
RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 curl \
 python-sphinx-bootstrap-theme \
 node-uglify \
 docbook-xsl \
 xsltproc \
 python-mock

COPY lava-server_*deb /root

RUN \
 cd /root && \
 dpkg-deb --extract lava-server_*deb lava-server && \
 dpkg-deb --control lava-server_*deb lava-server/DEBIAN && \
 dpkg-deb --build lava-server && \
 mv lava-server.deb lava-server-nopostgres.deb && \
 echo 'y'|DEBIAN_FRONTEND=noninteractive gdebi --option=APT::Get::force-yes=1,APT::Get::Assume-Yes=1  lava-server-nopostgres.deb && \
 echo "LAVA_DB_ROOTUSER=\"postgres\"" >>/etc/lava-server/instance.conf && \
 echo "LAVA_DB_ROOTPASSWORD=\"lava123\"" >>/etc/lava-server/instance.conf
 
RUN \
 a2dissite 000-default \
 && a2enmod proxy \
 && a2enmod proxy_http

RUN service gunicorn restart \
 && service apache2 restart

# Add services helper utilities to start and stop LAVA
COPY stop.sh .
COPY start.sh .
COPY cfg_postgres.sh .

RUN a2ensite lava-server \
 && /stop.sh \
 && rm -rf /var/lib/apt/lists/*

# Add lava user with super-user privilege
RUN useradd -m -G plugdev lava \
 && echo 'lava ALL = NOPASSWD: ALL' > /etc/sudoers.d/lava \
 && chmod 0440 /etc/sudoers.d/lava \
 && mkdir -p /var/run/sshd /home/lava/bin /home/lava/.ssh \
 && chmod 0700 /home/lava/.ssh \
 && chown -R lava:lava /home/lava/bin /home/lava/.ssh

# Add misc utilities
COPY createsuperuser.sh add-devices-to-lava.sh getAPItoken.sh lava-credentials.txt /home/lava/bin/

#WICED devices
COPY 943907AEVAL1F-1.jinja2 /etc/dispatcher-config/devices/
COPY 943907AEVAL1F.jinja2   /etc/lava-server/dispatcher-config/device-types/

# CORTEX-M3: apply patches to enable cortex-m3 support
#RUN /start.sh \
# && git clone -b proj/add_wiced git://10.136.64.138/git/lava-dispatcher /home/lava/lava-dispatcher \
# && cd /home/lava/lava-dispatcher \
# && git checkout -b wip 250e29bdef3ae30954f57f852d251fe776d6b180 \
# && git clone -b proj/add_wiced git://10.136.64.138/git/lava-server /home/lava/lava-server \
# && cd /home/lava/lava-server \
# && git checkout -b wip e1866b72f32ad9e61ae11bad25519a1b9b70d9d7 \
# && echo "CORTEX-M3: add build then install capability to debian-dev-build.sh" \
# && echo "cd \${DIR} && dpkg -i *.deb" >> /home/lava/lava-server/share/debian-dev-build.sh \
# && echo "CORTEX-M3: Installing patched versions of dispatcher & server" \
# && cd /home/lava/lava-dispatcher && /home/lava/lava-server/share/debian-dev-build.sh -p lava-dispatcher \
# && cd /home/lava/lava-server && /home/lava/lava-server/share/debian-dev-build.sh -p lava-server \
# && /stop.sh

COPY fileshare/ /root/fileshare-base/
EXPOSE 22 80 5555 5556
# Create a admin user (Insecure note, this creates a default user, username: admin/admin)
# Add devices
CMD /start.sh && \
  /home/lava/bin/createsuperuser.sh && \
  /home/lava/bin/getAPItoken.sh && \
  /home/lava/bin/add-devices-to-lava.sh 41 && \
  bash
