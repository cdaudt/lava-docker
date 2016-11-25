#!/bin/sh
# postinst script for lava-server
#
# see: dh_installdeb(1)

set -e

# summary of how this script can be called:
#        * <postinst> `configure' <most-recently-configured-version>
#        * <old-postinst> `abort-upgrade' <new version>
#        * <conflictor's-postinst> `abort-remove' `in-favour' <package>
#          <new-version>
#        * <postinst> `abort-remove'
#        * <deconfigured's-postinst> `abort-deconfigure' `in-favour'
#          <failed-install-package> <version> `removing'
#          <conflicting-package> <version>
# for details, see http://www.debian.org/doc/debian-policy/ or
# the debian-policy package

. /etc/lava-server/instance.conf
export PGHOST=$LAVA_DB_SERVER
export PGPASSWORD=$LAVA_DB_ROOTPASSWORD
export PGUSER=$LAVA_DB_ROOTUSER
export PGPORT=$LAVA_DB_PORT

install_database()
{
    # check postgres is not just installed but actually ready.
    pg=1
    limit=3
    while [ $pg -le $limit ]; do
        if ! pg_isready -q; then
            echo "[$pg] Postgres not ready for connection to $LAVA_DB_NAME on port $LAVA_DB_PORT.PGHOST=${PGHOST}"
            sleep 1
        else
            break
        fi
        pg=$(( $pg + 1 ))
    done
    if [ $pg -ge $limit ]; then
        echo "Failed to connect to postgres."
        exit $pg
    fi
    # Create database user, if it doesn't exist
    if ! psql -c "SELECT usename FROM pg_user WHERE usename='$LAVA_DB_USER'" | grep "$LAVA_DB_USER"; then
        echo "Creating user:${LAVA_DB_USER}"
        psql --command="CREATE USER $LAVA_DB_USER WITH NOSUPERUSER NOCREATEDB LOGIN NOCREATEROLE ENCRYPTED PASSWORD '$LAVA_DB_PASSWORD'" || "Failed to create database user"
    fi
    # Create a database for our new user, if it doesn't exist
    if ! psql -c "SELECT datname FROM pg_database WHERE datname='$LAVA_DB_NAME'" | grep "$LAVA_DB_NAME"; then
        echo "Creating DB:${LAVA_DB_NAME}"
        psql --command="CREATE DATABASE $LAVA_DB_NAME WITH ENCODING=UTF8 OWNER=$LAVA_DB_USER TEMPLATE=template0" || "Failed to create a database"
    fi
    # Create devel user, if it doesn't exist, for unit test support
    if ! psql --command="SELECT usename FROM pg_user WHERE usename='devel'" | grep "devel"; then
        echo "Creating user:devel"
        psql --command="CREATE USER devel WITH NOSUPERUSER CREATEDB LOGIN NOCREATEROLE PASSWORD 'devel'" || "Failed to create test user"
    fi
    # create the devel database, if it doesn't exist
    if ! psql --command="SELECT datname FROM pg_database WHERE datname='devel'" | grep "devel"; then
        echo "Creating DB:devel"
        psql --command="CREATE DATABASE devel WITH OWNER=devel" || die "Failed to create a database"
    fi
    # syncdb
    # fake-initial only in django 1.8 but needed for upgrades from 1.7 using 1.9
    if [ "`dpkg --compare-versions $(django-admin --version) gt '1.8' && echo $?`" = '0' ]; then
        lava-server manage migrate --noinput --fake-initial
    else
        lava-server manage migrate --noinput
    fi
    lava-server manage refresh_queries --all
    # superuser - password must be changed
    if ! psql --command="SELECT usename FROM pg_user WHERE usename='$LAVA_SYS_USER'" | grep "$LAVA_SYS_USER"; then
        if ! psql --command="SELECT username FROM auth_user WHERE username='$LAVA_SYS_USER'" | grep "$LAVA_SYS_USER"; then
            lava-server manage createsuperuser --noinput --username=$LAVA_SYS_USER --email=$LAVA_SYS_USER@lava.invalid || true
        fi
    fi
}

install_database

exit 0
