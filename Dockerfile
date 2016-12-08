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

RUN \
 DEBIAN_FRONTEND=noninteractive apt-get install -y \
 python-pip


COPY lava-server_*deb /root

RUN \
 cd /root && \
 export DEBFILE=lava-server_*deb && \
 echo 'y'|DEBIAN_FRONTEND=noninteractive gdebi --option=APT::Get::force-yes=1,APT::Get::Assume-Yes=1 $DEBFILE && \
 rm ${DEBFILE}
 
RUN \
 a2dissite 000-default \
 && a2enmod proxy \
 && a2enmod proxy_http

# Add services helper utilities to start and stop LAVA
COPY start.sh .
COPY cfg_postgres.sh .

RUN a2ensite lava-server \
 && rm -rf /var/lib/apt/lists/*

# Add lava user with super-user privilege
RUN useradd -m -G plugdev lava \
 && echo 'lava ALL = NOPASSWD: ALL' > /etc/sudoers.d/lava \
 && chmod 0440 /etc/sudoers.d/lava \
 && mkdir -p /var/run/sshd /home/lava/bin /home/lava/.ssh \
 && chmod 0700 /home/lava/.ssh \
 && chown -R lava:lava /home/lava/bin /home/lava/.ssh

# Add misc utilities
COPY setup_server.py \
 /home/lava/bin/

COPY fileshare/ /root/fileshare-base/
EXPOSE 22 80 5555 5556
# Create a admin user (Insecure note, this creates a default user, username: admin/admin)
# Add devices
CMD /start.sh && \
  /home/lava/bin/setup_server.py --url http://localhost /fileshare/cfg/server.json && \
  tail -F /var/log/lava-server/lava*log
