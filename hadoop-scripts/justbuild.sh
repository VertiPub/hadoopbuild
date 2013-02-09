#!/bin/sh -ex
# build the artifacts using the "pure" maven builds

mvn versions:set -DnewVersion=${ARTIFACT_VERSION}
mvn -Pdist,docs,src,native -Dtar -DskipTests -Dbundle.snappy  -Dsnappy.lib=/usr/lib64 -Drequire.fuse=true -Drequire.snappy clean package
