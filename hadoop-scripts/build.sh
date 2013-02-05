#!/bin/sh
# clean up any previous artifacts
rm -rf ${WORKSPACE}/fuse_install-* ${WORKSPACE}/hadoop_install-* ${WORKSPACE}/*.rpm

# set up env variables
export DATE_STRING=`date +"%Y%m%d%H%M"`
export RPM_VERSION=0.1.0
export HADOOP_VERSION=2.0.2

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
DEST_DIR=${WORKSPACE}/fuse_install-${BUILD_NUMBER}/opt/fuse-${HADOOP_VERSION}
mkdir --mode=0755 -p ${DEST_DIR}
cd ${DEST_DIR}
tar -xvzpf ${WORKSPACE}/hadoop-common/hadoop-dist/target/fuse-${HADOOP_VERSION}.tar.gz

export RPM_NAME=`echo vcc-fuse-${HADOOP_VERSION}`
fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides ${RPM_NAME} \
--replaces vcc-fuse \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${RPM_VERSION} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
-C ${WORKSPACE}/fuse_install-${BUILD_NUMBER} \
opt

DEST_ROOT=${WORKSPACE}/hadoop_install-${BUILD_NUMBER}
OPT_DIR=${DEST_ROOT}/opt
mkdir --mode=0755 -p ${OPT_DIR}
cd ${OPT_DIR}

tar -xvzpf ${WORKSPACE}/hadoop-common/hadoop-dist/target/hadoop-${HADOOP_VERSION}.tar.gz
# https://verticloud.atlassian.net/browse/OPS-731
# create /etc/hadoop, in a future version of the build we may move the config there directly
ETC_DIR=${DEST_ROOT}/etc/hadoop-${HADOOP_VERSION}
mkdir --mode=0755 -p ${ETC_DIR}
# move the config directory to /etc
cp -rp $OPT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop/* $ETC_DIR
mv $OPT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop $OPT_DIR/hadoop-${HADOOP_VERSION}/etc/hadoop-templates
cd $DEST_ROOT
find etc -type f -print | awk '{print "/" $1}' > /tmp/$$.files
export CONFIG_FILES=""
for i in `cat /tmp/$$.files`; do CONFIG_FILES="--config-files $i $CONFIG_FILES "; done
export CONFIG_FILES
rm -f /tmp/$$.files

cd ${WORKSPACE}

export RPM_NAME=`echo vcc-hadoop-${HADOOP_VERSION}`
fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides ${RPM_NAME} \
--replaces vcc-hadoop \
-s dir \
-t rpm \
-n ${RPM_NAME}  \
-v ${RPM_VERSION} \
--iteration ${DATE_STRING} \
${CONFIG_FILES} \
--rpm-user root \
--rpm-group root \
-C ${WORKSPACE}/hadoop_install-${BUILD_NUMBER} \
opt etc
