#!/usr/bin/expect -f
spawn lava-server manage createsuperuser
expect "Username (leave blank to use 'root'):"
send "kernel-ci\r"
expect "Email address:"
send "kernel-ci@localhost\r"
expect "Password:"
send "shazbot\r"
expect "Password (again):"
send "shazbot\r"
expect "Superuser created successfully."
