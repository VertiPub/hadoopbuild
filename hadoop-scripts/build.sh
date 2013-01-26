#!/bin/sh
# clean up any previous artifacts
rm -rf ${WORKSPACE}/install-${BUILD_NUMBER} ${WORKSPACE}/*.rpm

# set up env variables
export DATE_STRING=`date +"%Y%m%d%H%M"`
export HADOOP_VERSION=2.0.2-${BUILD_NUMBER}-alpha-vcc

# deal with the submodule

cd ${WORKSPACE}
git submodule init
git submodule update
cd ${WORKSPACE}/hadoop-common
git checkout -b tobebuilt remotes/origin/branch-2.0.2-alpha-vcc

# build the artifacts using the "pure" maven builds


mvn versions:set -DnewVersion=${HADOOP_VERSION}
mvn -Pdist,docs,src,native -Dtar -DskipTests -Dbundle.snappy  -Dsnappy.lib=/usr/lib64 -Drequire.fuse=true -Drequire.snappy clean package

# deal with the fuse artifacts to create a tarball

tar -C hadoop-hdfs-project/hadoop-hdfs/target/native/main/native/fuse-dfs -cvzf hadoop-dist/target/fuse-${HADOOP_VERSION}.tar.gz fuse_dfs 

# convert each tarball into an RPM
DEST_DIR=${WORKSPACE}/install-${BUILD_NUMBER}/opt
mkdir --mode=0755 -p ${DEST_DIR}
cd ${DEST_DIR}
tar -xvzpf ../../../hadoop-common/hadoop-dist/target/fuse-${HADOOP_VERSION}.tar.gz
tar -xvzpf ../../../hadoop-common/hadoop-dist/target/hadoop-${HADOOP_VERSION}.tar.gz
cd ${WORKSPACE}

#this should really go in the hudson job as config
#s3cmd put ./hadoop-dist/target/hadoop-*.tar.gz s3://eng.verticloud.com/
# this should really go in the hudson job as config
#&& s3cmd put ./hadoop-dist/target/fuse-2.0.2-${BUILD_NUMBER}-alpha-vcc.tar.gz s3://eng.verticloud.com/

