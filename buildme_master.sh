VER="cypress-0"
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

docker tag lava/master:${VER} rodan.ric.broadcom.com:5000/lava/master:${VER}
docker push rodan.ric.broadcom.com:5000/lava/master:${VER}
