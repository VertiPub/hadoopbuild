#!/bin/sh -ex
# deal with the fuse artifacts to create a tarball
ALTISCALE_RELEASE=${ALTISCALE_RELEASE:-0.1.0}

tar -C ${WORKSPACE}/hadoop-common/hadoop-hdfs-project/hadoop-hdfs/target/native/main/native/fuse-dfs -cvzf ${WORKSPACE}/hadoop-common/hadoop-dist/target/fuse-${ARTIFACT_VERSION}.tar.gz fuse_dfs

# convert each tarball into an RPM
DEST_ROOT=${INSTALL_DIR}/opt/fuse-${ARTIFACT_VERSION}
mkdir --mode=0755 -p ${DEST_ROOT}
cd ${DEST_ROOT}
tar -xvzpf ${WORKSPACE}/hadoop-common/hadoop-dist/target/fuse-${ARTIFACT_VERSION}.tar.gz
chmod 500 ${DEST_ROOT}/fuse_dfs

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
-v ${ALTISCALE_RELEASE} \
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
chmod 755 ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}
# https://verticloud.atlassian.net/browse/OPS-731
# create /etc/hadoop, in a future version of the build we may move the config there directly
ETC_DIR=${INSTALL_DIR}/etc/hadoop-${ARTIFACT_VERSION}
mkdir --mode=0755 -p ${ETC_DIR}
# move the config directory to /etc
cp -rp ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/etc/hadoop/* $ETC_DIR
mv ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/etc/hadoop ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/etc/hadoop-templates
cd ${INSTALL_DIR}
find etc -type f -print | awk '{print "/" $1}' > /tmp/$$.files
export CONFIG_FILES=""
for i in `cat /tmp/$$.files`; do CONFIG_FILES="--config-files $i $CONFIG_FILES "; done
export CONFIG_FILES
rm -f /tmp/$$.files


#interleave lzo jars
for i in share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib share/hadoop/mapreduce/lib share/hadoop/yarn/lib share/hadoop/common/lib; do
  cp -rp ${WORKSPACE}/hadoop-lzo/target/hadoop-lzo-[0-9]*.[0-9]*.[0-9]*-[0-9]*[0-9].jar ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/$i
done
cp ${WORKSPACE}/hadoop-lzo/target/native/Linux-amd64-64/lib/libgplcompression.* ${OPT_DIR}/hadoop-${ARTIFACT_VERSION}/lib/native/

cd ${RPM_DIR}

export RPM_NAME=`echo vcc-hadoop-${ARTIFACT_VERSION}`
fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides ${RPM_NAME} \
--provides "libhdfs.so.0.0.0()(64bit)" \
--provides "libhdfs(x86-64)" \
--provides libhdfs \
--replaces vcc-hadoop \
--depends 'lzo > 2.0' \
-s dir \
-t rpm \
-n ${RPM_NAME}  \
-v ${ALTISCALE_RELEASE} \
--iteration ${DATE_STRING} \
--description "${DESCRIPTION}" \
${CONFIG_FILES} \
--rpm-user root \
--rpm-group root \
-C ${INSTALL_DIR} \
opt etc
