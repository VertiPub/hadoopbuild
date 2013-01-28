#!/bin/sh
# clean up any previous artifacts
rm -rf ${WORKSPACE}/fuse_install-${BUILD_NUMBER} ${WORKSPACE}/hadoop_install-${BUILD_NUMBER} ${WORKSPACE}/*.rpm

# set up env variables
export DATE_STRING=`date +"%Y%m%d%H%M"`
export HADOOP_MAJOR=2.0.2
export HADOOP_VERSION=${HADOOP_MAJOR}-alpha-vcc

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
DEST_DIR=${WORKSPACE}/fuse_install-${BUILD_NUMBER}/opt
mkdir --mode=0755 -p ${DEST_DIR}
cd ${DEST_DIR}
tar -xvzpf ${WORKSPACE}/hadoop-common/hadoop-dist/target/fuse-${HADOOP_VERSION}.tar.gz

fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides vcc-fuse \
-s dir \
-t rpm \
-n vcc-fuse  \
-v ${HADOOP_MAJOR} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
-C ${WORKSPACE}/fuse_install-${BUILD_NUMBER} \
opt

DEST_DIR=${WORKSPACE}/hadoop_install-${BUILD_NUMBER}/opt
mkdir --mode=0755 -p ${DEST_DIR}
cd ${DEST_DIR}

tar -xvzpf ${WORKSPACE}/hadoop-common/hadoop-dist/target/hadoop-${HADOOP_VERSION}.tar.gz
mv hadoop-${HADOOP_VERSION} hadoop
cd ${WORKSPACE}

fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides vcc-hadoop \
-s dir \
-t rpm \
-n vcc-hadoop  \
-v ${HADOOP_VERSION} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
-C ${WORKSPACE}/hadoop_install-${BUILD_NUMBER} \
opt

