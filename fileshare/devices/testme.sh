NOW=`date  +%Y%m%d%H%M`
(sudo lava-dispatch --target ./devices/ifc6410plus.yaml job1.yaml --output-dir=/tmp/test/) 2>&1 | tee result.$NOW
