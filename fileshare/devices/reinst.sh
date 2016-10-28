sudo cp device-types/ifc6410plus.jinja2 /etc/lava-server/dispatcher-config/device-types/  
sudo lava-server manage device-dictionary --hostname ifc6410plus-1323 --import ifc6410plus-1323.jinja2                                      
echo "Review:"
sudo lava-server manage device-dictionary --hostname ifc6410plus-1323 --review
