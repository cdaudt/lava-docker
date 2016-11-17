ATTEMPT=0
while :
do
	docker build $* -t lava/master:2016-11.1 .
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

docker tag lava/master:2016-11.1 rodan.ric.broadcom.com:5000/lava/master:2016-11.1
docker push  rodan.ric.broadcom.com:5000/lava/master:2016-11.1
