#!/bin/bash

### update OS ###
yum -y update

### set limits parameters ###
cat >>  /etc/security/limits.conf << EOF
########### limits for Hadoop #############
*         soft    nproc   131072
*         hard    nproc   131072
*         soft    nofile  655360
*         hard    nofile  655360
########### limits for Hadoop #############
EOF

### disable selinux ###
sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config

### set swap and transparent_hugepage ###
echo vm.swappiness=0 >> /etc/sysctl.conf
cat >>  /etc/rc.d/rc.local << EOF
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
EOF
chmod +x /etc/rc.local

### set chrony ntp ###
yum -y install chrony
echo "server 169.254.169.123 prefer iburst" >> /etc/chrony.conf
timedatectl set-timezone Asia/Shanghai

### Add cdh & epel repo ###
curl -s -o /etc/yum.repos.d/cm-5.11.2.repo https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
curl -s -o /tmp/epel-release-latest-7.noarch.rpm http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh /tmp/epel-release-latest-7.noarch.rpm

### install packages ###
yum install -y wget mysql vim jq oracle-j2sdk1.7 cloudera-manager-server cloudera-manager-agent

### cleanup cloudera packages ###
systemctl stop cloudera-scm-server
systemctl stop cloudera-scm-agent
systemctl disable cloudera-scm-server
systemctl disable cloudera-scm-agent
sleep 30
rm -f /var/lib/cloudera-scm-agent/uuid
rm -f /var/lib/cloudera-scm-agent/cm_guid

## install & configure aws-cli ###
curl -s -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
python /tmp/get-pip.py
pip install cm_api awscli
Region=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r`
aws configure set default.region ${Region}

### install mysql-connector ###
yum -y install mysql-connector-java
mkdir -p /usr/lib/hive/lib/
ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar

## install & distribue CDH parcel ###
mkdir -p /opt/cloudera/parcel-repo/
curl -s -o /opt/cloudera/parcel-repo/CDH-5.11.2-1.cdh5.11.2.p0.4-el7.parcel https://archive.cloudera.com/cdh5/parcels/5.11/CDH-5.11.2-1.cdh5.11.2.p0.4-el7.parcel
curl -s -o /opt/cloudera/parcel-repo/CDH-5.11.2-1.cdh5.11.2.p0.4-el7.parcel.sha https://archive.cloudera.com/cdh5/parcels/5.11/CDH-5.11.2-1.cdh5.11.2.p0.4-el7.parcel.sha1
curl -s -o /opt/cloudera/parcel-repo/manifest.json https://archive.cloudera.com/cdh5/parcels/5.11/manifest.json
chown -R cloudera-scm:cloudera-scm /opt/cloudera