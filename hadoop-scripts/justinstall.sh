#!/bin/sh
# deal with the fuse artifacts to create a tarball
            a.  The build script will be passed an "ARTIFACT_VERSION" environment variable
            b.  The build script will be passed the "DATE_STRING" environment variable should it need it
            c.  The build script will be passed the "INSTALL_DIR" into which to unpack the artifacts created by the build script
            d.  The build script will be passed the "RPM_DIR" into which to place the built RPM
            e.  The build script will inherit the "WORKSPACE"  environment variable
            f.  The build will pass in a description in a single quoted string in the "DESCRIPTION" env variable

RPM_VERSION=0.1.0
tar -C ${WORKSPACE}/hadoop/hadoop-hdfs-project/hadoop-hdfs/target/native/main/native/fuse-dfs -cvzf ${WORKSPACE}/hadoop/hadoop-dist/target/fuse-${ARTIFACT_VERSION}.tar.gz fuse_dfs 

# convert each tarball into an RPM
DEST_ROOT=${INSTALL_DIR}/opt/fuse-${ARTIFACT_VERSION}
mkdir --mode=0755 -p ${DEST_ROOT}
cd ${DEST_ROOT}
tar -xvzpf ${WORKSPACE}/hadoop-common/hadoop-dist/target/fuse-${ARTIFACT_VERSION}.tar.gz

cd ${RPM_DIR}

export RPM_NAME=vcc-fuse-${ARTIFACT_VERSION}
fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides ${RPM_NAME} \
--description "${DESCRIPTION}" \
--replaces vcc-fuse \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${RPM_VERSION} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
-C ${INSTALL_DIR} \
opt

#clear the install dir and re-use
rm -rf ${INSTALL_DIR}
mkdir -p --mode 0755 ${INSTALL_DIR}

OPT_DIR=${INSTALL_DIR}/opt
mkdir --mode=0755 -p ${OPT_DIR}
cd ${OPT_DIR}

tar -xvzpf ${WORKSPACE}/hadoop-common/hadoop-dist/target/hadoop-${ARTIFACT_VERSION}.tar.gz
# https://verticloud.atlassian.net/browse/OPS-731
# create /etc/hadoop, in a future version of the build we may move the config there directly
ETC_DIR=${INSTALL_DIR}/etc/hadoop-${ARTIFACT_VERSION}
mkdir --mode=0755 -p ${ETC_DIR}
# move the config directory to /etc
cp -rp ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/etc/hadoop/* $ETC_DIR
mv ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/etc/hadoop ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/etc/hadoop-templates
cd $DEST_ROOT
find etc -type f -print | awk '{print "/" $1}' > /tmp/$$.files
export CONFIG_FILES=""
for i in `cat /tmp/$$.files`; do CONFIG_FILES="--config-files $i $CONFIG_FILES "; done
export CONFIG_FILES
rm -f /tmp/$$.files

cd ${RPM_DIR}

export RPM_NAME=`echo vcc-hadoop-${ARTIFACT_VERSION}`
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
--description "${DESCRIPTION}" \
${CONFIG_FILES} \
--rpm-user root \
--rpm-group root \
-C ${WORKSPACE}/hadoop_install-${BUILD_NUMBER} \
opt etc
