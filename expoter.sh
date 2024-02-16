#!/bin/bash

# this is
# ex) export.sh <CloudWatch-Logs-GroupName> <StartDate> <EndDate> <S3-BucketName>

# check exist command aws.
if ! type "aws" > /dev/null 2>&1; then
  echo "aws command not installed."
  exit 1;
fi

# check argument count
if [ $# != 4 ]; then
  echo "invalid argument count. ex) export.sh <CloudWatch-Logs-GroupName> <StartDate> <EndDate> <S3-BucketName>"
  exit 1;
fi

# check exist export task running
if [ $(aws logs describe-export-tasks --status-code "RUNNING" --query 'length(exportTasks[*].taskId)') != 0 ]; then
  echo "Now running create-export-task exist. Please try again in a few minutes."
  exit 1;
fi

export AWS_MAX_ATTEMPTS=10

LOG_GROUP_NAME=$1
# end date. ex) 2022/11/14
DATE_BEGIN=$2
# end date. ex) 2023/03/04
DATE_END=$3
# S3 Bucket Name. ex) log-archive-7c08f157
BUCKET_NAME=$4

DESTINATION_PREFIX=$(echo $LOG_GROUP_NAME | sed 's/^\///' | sed 's/\//-/g' | sed 's/\./--/g')

# check bucket exist
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1; then
  exit 1
fi

echo "target log group = $LOG_GROUP_NAME"
echo "date from $DATE_BEGIN to $DATE_END"
echo "archive bucket = $BUCKET_NAME"
echo "archive destination prefix = $DESTINATION_PREFIX"

dt=$DATE_BEGIN
while [[ $(( ${dt//\/} )) -le $(( ${DATE_END//\/} )) ]] ; do
  echo "start export task date = $dt"

  taskId=$(aws logs create-export-task \
      --log-group-name "${LOG_GROUP_NAME}" \
      --from $((`date -u +%s -d "${dt} 00:00:00"` * 1000)) \
      --to $(((`date -u +%s -d "${dt} 23:59:59"` * 1000) + 999)) \
      --destination "${BUCKET_NAME}" \
      --destination-prefix "${DESTINATION_PREFIX}/`date -d ${dt} '+%Y'`/`date -d ${dt} '+%Y-%m'`/`date -d ${dt} '+%m-%d'`" \
      --query 'taskId' \
      --output text)

  sleep 2

  while true; do

    status=$(aws logs describe-export-tasks \
        --task-id $taskId \
        --query "exportTasks[0].status.code" \
        --output text)

    if [ "$status" == "COMPLETED" ]; then
      echo "completed export task date=$dt"
      break
    elif [ "$status" == "FAILED" ]; then
      echo "failed export task date=$dt"
      break
    fi

    sleep 5
  done

  dt=`date -d "$dt 1 day" '+%Y/%m/%d'`

done

echo "finish export log group '$LOG_GROUP_NAME'"
