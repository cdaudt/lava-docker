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

install_database()
{
    # check postgres is not just installed but actually ready.
    pg=1
    limit=3
    while [ $pg -le $limit ]; do
        if ! pg_isready -d '$LAVA_DB_NAME' -p $LAVA_DB_PORT -q; then
            echo "[$pg] Postgres not ready for connection to $LAVA_DB_NAME on port $LAVA_DB_PORT."
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
    if ! su postgres -c "psql \"-c SELECT usename FROM pg_user WHERE usename='$LAVA_DB_USER'\"" | grep "$LAVA_DB_USER"; then
        su postgres -c "createuser --no-createdb --encrypted --login --no-superuser --no-createrole --no-password --port $LAVA_DB_PORT $LAVA_DB_USER"|| "Failed to create database user"
        # Set a password for our new user
        su postgres -c "psql --port $LAVA_DB_PORT --quiet --command=\"ALTER USER \"$LAVA_DB_USER\" WITH PASSWORD '$LAVA_DB_PASSWORD'\"" || die "Failed to set database password"
    fi
    # Create a database for our new user, if it doesn't exist
    if ! su postgres -c "psql -c \"SELECT datname FROM pg_database WHERE datname='$LAVA_DB_NAME'\"" | grep "$LAVA_DB_NAME"; then
        su postgres -c "createdb --port $LAVA_DB_PORT --locale=C.UTF-8 --encoding=UTF-8 --owner=$LAVA_DB_USER --template=template0 --no-password $LAVA_DB_NAME" || die "Failed to create a database"
    fi
    # Create devel user, if it doesn't exist, for unit test support
    if ! su postgres -c "psql \"-c SELECT usename FROM pg_user WHERE usename='devel'\"" | grep "devel"; then
        su postgres -c "createuser --createdb --login --no-superuser --no-createrole --no-password --port $LAVA_DB_PORT devel"|| "Failed to create test case user"
        # Set a password for the devel user
        su postgres -c "psql --port $LAVA_DB_PORT --quiet --command=\"ALTER USER \"devel\" WITH PASSWORD 'devel'\"" || die "Failed to set test case password"
    fi
    # create the devel database, if it doesn't exist
    if ! su postgres -c "psql -c \"SELECT datname FROM pg_database WHERE datname='devel'\"" | grep "devel"; then
        su postgres -c "createdb devel --owner devel"
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
    if ! su postgres -c "psql \"-c SELECT usename FROM pg_user WHERE usename='$LAVA_SYS_USER'\"" | grep "$LAVA_SYS_USER"; then
        if ! su postgres -c "psql $LAVA_DB_NAME \"-c SELECT username FROM auth_user WHERE username='$LAVA_SYS_USER'\"" | grep "$LAVA_SYS_USER"; then
            lava-server manage createsuperuser --noinput --username=$LAVA_SYS_USER --email=$LAVA_SYS_USER@lava.invalid || true
        fi
    fi
}

install_database

exit 0
