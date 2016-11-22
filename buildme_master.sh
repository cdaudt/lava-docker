VER="nosql0"
ATTEMPT=0
while :
do
	docker build $* -t lava/master:${VER} .
	if [ $? -eq 0 ]
	then 
		break
	fi
	ATTEMPT=`expr $ATTEMPT + 1`
	echo "Finished attempt ${ATTEMPT} unsuccessfully. Retrying"
	date
	echo =======================================================================================
	sleep 10m
done
