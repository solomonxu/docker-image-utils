#!/usr/bin/bash

## define variable
APP_HOME=/data/docker-image-utils
APP_BIN=$APP_HOME/bin
APP_CONF=$APP_HOME/conf
APP_DATA=$APP_HOME/data
APP_LOG=$APP_HOME/log
APP_LOG_FILE=$APP_LOG/push_image.log
IMAGE_LIST_TXT=$APP_CONF/image-list.txt
IMAGE_UTILS_CONF=$APP_CONF/image-utils.conf

## make dir
mkdir -p $APP_CONF
mkdir -p $APP_DATA
mkdir -p $APP_LOG

## use arguments
if [ $# -ge 1 ]; then
    IMAGE_LIST_TXT=$APP_CONF/$1
fi
if [ $# -ge 2 ]; then
    IMAGE_UTILS_CONF=$APP_CONF/$2
fi
echo IMAGE_LIST_TXT=$IMAGE_LIST_TXT
echo IMAGE_UTILS_CONF=$IMAGE_UTILS_CONF

## check if file existed
if [ ! -f $IMAGE_LIST_TXT ]; then
    echo "`date` File ${IMAGE_LIST_TXT} not existed, Exit." 2>&1 >> $APP_LOG_FILE
    exit 1
fi
if [ ! -f $IMAGE_UTILS_CONF ]; then
    echo "`date` File ${IMAGE_UTILS_CONF} not existed, Exit." 2>&1 >> $APP_LOG_FILE
    exit 2
fi

## read config
chmod a+x $IMAGE_UTILS_CONF
. $IMAGE_UTILS_CONF

## echo config
echo "" 2>&1 >> $APP_LOG_FILE
echo "`date` Start job of loading and pushing docker images..." 2>&1 >> $APP_LOG_FILE
echo "APP_HOME: ${APP_HOME}" 2>&1 >> $APP_LOG_FILE
echo "APP_CONF: ${APP_CONF}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_SOURCE_HOST: ${IMAGE_SOURCE_HOST}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_SOURCE_PROJECT: ${IMAGE_SOURCE_PROJECT}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_SOURCE_VERSION: ${IMAGE_SOURCE_VERSION}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_SOURCE_USER: ${IMAGE_SOURCE_USER}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_SOURCE_PASSWORD: ${IMAGE_SOURCE_PASSWORD}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_DEST_HOST: ${IMAGE_DEST_HOST}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_DEST_PROJECT: ${IMAGE_DEST_PROJECT}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_DEST_HOST: ${IMAGE_DEST_HOST}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_DEST_VERSION: ${IMAGE_DEST_VERSION}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_DEST_USER: ${IMAGE_DEST_USER}" 2>&1 >> $APP_LOG_FILE
echo "IMAGE_DEST_PASSWORD: ${IMAGE_DEST_PASSWORD}" 2>&1 >> $APP_LOG_FILE
echo "HOST_PULL: ${HOST_PULL}" 2>&1 >> $APP_LOG_FILE
echo "HOST_PUSH: ${HOST_PUSH}" 2>&1 >> $APP_LOG_FILE

## docker login
if [ -n "${IMAGE_DEST_PASSWORD}" ]; then
    echo "`date` Using password in config." 2>&1 >> $APP_LOG_FILE
    arg_password="--password ${IMAGE_DEST_PASSWORD}"
fi
echo "`date` Login to docker repository..." 2>&1 >> $APP_LOG_FILE
docker login --username "${IMAGE_DEST_USER}" ${arg_password} ${IMAGE_DEST_HOST}

## read image list
images_list=`cat ${IMAGE_LIST_TXT}`

## loop for images in list
COUNT=0
echo "`date` Start to load and push docker images..." 2>&1 >> $APP_LOG_FILE
for image in $images_list; do
    ## define variable
	image_dest_version=${image}:${IMAGE_DEST_VERSION}
	if [ -n `echo ${image} | awk -F: '{print $2}'` ]; then
		image_dest_version=${image}
	fi
	image_dest=${IMAGE_DEST_HOST}/${IMAGE_DEST_PROJECT}/${image_dest_version}
	image_tar=${APP_DATA}/${image_dest_version}.tar
	echo image_dest=$image_dest
	
	## docker push/retag/save
    echo "`date` Docker load image [${image}: ${image_tar}]." 2>&1 >> $APP_LOG_FILE
	docker load -i ${image_tar}
    echo "`date` Docker pull image [${image}: ${image_dest}]." 2>&1 >> $APP_LOG_FILE
	docker push ${image_dest}

    echo "`date` Process image [${image}] OK." 2>&1 >> $APP_LOG_FILE
	COUNT=`expr $COUNT + 1`
done;
echo "`date` All done, ${COUNT} images processed." 2>&1 >> $APP_LOG_FILE