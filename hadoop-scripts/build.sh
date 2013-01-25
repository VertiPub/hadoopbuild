#!/bin/sh
cd ${WORKSPACE}
git submodule init
git submodule update
cd ${WORKSPACE}/hadoop-common
git checkout -b tobebuilt remotes/origin/branch-2.0.2-alpha-vcc
mvn versions:set -DnewVersion=2.0.2-${BUILD_NUMBER}-alpha-vcc
mvn -Pdist,docs,src,native -Dtar -DskipTests -Dbundle.snappy  -Dsnappy.lib=/usr/lib64 -Drequire.fuse=true -Drequire.snappy clean package
#s3cmd put ./hadoop-dist/target/hadoop-*.tar.gz s3://eng.verticloud.com/
tar -C hadoop-hdfs-project/hadoop-hdfs/target/native/main/native/fuse-dfs -cvzf hadoop-dist/target/fuse-2.0.2-${BUILD_NUMBER}-alpha-vcc.tar.gz fuse_dfs #&& s3cmd put ./hadoop-dist/target/fuse-2.0.2-${BUILD_NUMBER}-alpha-vcc.tar.gz s3://eng.verticloud.com/

cd ${WORKSPACE}
git submodule update
