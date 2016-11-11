ATTEMPT=0
while :
do
	docker build $* -t lava/master:2016-11.1 .
	if [ $? -eq 0 ]
	then 
		exit 0
	fi
	ATTEMPT=`expr $ATTEMPT + 1`
	echo "Finished attempt ${ATTEMPT} unsuccessfully. Retrying"
	date
	echo =======================================================================================
	sleep 10m
done


