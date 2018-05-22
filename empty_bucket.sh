#!/bin/bash

bucket=$1

set -e

echo "Removing all versions from $bucket"

function urldecode {
    echo $(python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])" $1);
}

versions=`aws s3api list-object-versions --encoding-type url --bucket $bucket | jq '.Versions'`
markers=`aws s3api list-object-versions --encoding-type url --bucket $bucket | jq '.DeleteMarkers'`

echo "removing files"
for version in $(echo "${versions}" | jq -r '.[] | @base64'); do
    version=$(echo ${version} | base64 --decode)

    key=`echo $version | jq -r .Key`
    versionId=`echo $version | jq -r .VersionId`
    decodedVersionId=$(urldecode "$key")
    cmd="aws s3api delete-object --bucket $bucket --key $decodedVersionId --version-id $versionId"
    echo $cmd
    $cmd
done

echo "removing delete markers"
for marker in $(echo "${markers}" | jq -r '.[] | @base64'); do
    marker=$(echo ${marker} | base64 --decode)

    key=`echo $marker | jq -r .Key`
    versionId=`echo $marker | jq -r .VersionId`
    decodedVersionId=$(urldecode "$key")
    cmd="aws s3api delete-object --bucket $bucket --key $decodedVersionId --version-id $versionId"
    echo $cmd
    $cmd
done
