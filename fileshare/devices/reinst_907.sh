cp device-types/943907AEVAL1F.jinja2 /etc/lava-server/dispatcher-config/device-types/
lava-server manage device-dictionary --hostname 943907AEVAL1F-1 --import 943907AEVAL1F-1.jinja2
echo "Review:"
lava-server manage device-dictionary --hostname 943907AEVAL1F-1 --review
