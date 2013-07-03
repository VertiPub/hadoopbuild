#!/bin/sh -ex
# build the artifacts using the "pure" maven builds

cd ${WORKSPACE}/hadoop-lzo
mvn versions:set -DnewVersion=0.4.18-${DATE_STRING}
mvn clean test package

cd ${WORKSPACE}/hadoop-common
mvn versions:set -DnewVersion=${ARTIFACT_VERSION}
mvn -Pdist,docs,src,native -Dtar -DskipTests -Dbundle.snappy  -Dsnappy.lib=/usr/lib64 -Drequire.fuse=true -Drequire.snappy clean package
