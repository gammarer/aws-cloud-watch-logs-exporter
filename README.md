# AWS CloudWatch Logs Exporter (to S3 Bucket)

This is Creates an export task so that you can efficiently export data from a log group to an Amazon S3 bucket. When you perform a CreateExportTask operation, you must use credentials that have permission to write to the S3 bucket that you specify as the destination.

## Notice

Archive file destination prefix format is {ExtLogGroupName}/{year}/{year}-{month}/{month}-{day}/ \

* {ExtLogGroupName} replace character
  * /(slash) to -(hyphen)
  * .(dot) to -(hyphen)

## Usage

Get script. \

```sh
wget https://raw.githubusercontent.com/gammarer/aws-cloud-watch-logs-exporter/main/expoter.sh
```

Execute this script. \

```sh
sh export.sh <CloudWatch-Logs-GroupName> <StartDate> <EndDate> <S3-BucketName>
```

## Example

```sh
sh export.sh /aws/lambda/example-function 2022/01/01 2022/12/31 example-log-archive-bucket
```
