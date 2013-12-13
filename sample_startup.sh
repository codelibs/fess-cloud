#!/bin/bash

cd `dirname $0`
BASE_DIR=`pwd`
BUILD_DIR=$BASE_DIR/target

bash $BASE_DIR/build.sh 

chmod +x $BUILD_DIR/*/bin/*.sh

# Create 4 ZK+Solr Servers
$BUILD_DIR/zksolr-server-1/bin/startup.sh
$BUILD_DIR/zksolr-server-2/bin/startup.sh
$BUILD_DIR/zksolr-server-3/bin/startup.sh

# Create 1 Solr Server
$BUILD_DIR/solr-server-1/bin/startup.sh

echo -n "Waiting"
COUNT=0
WAIT_COUNT=30
while [ $COUNT -lt $WAIT_COUNT ] ; do
    sleep 1
    echo -n "."
    COUNT=`expr $COUNT + 1`
done

echo "Creating SolrCloud collection."
java -classpath .:/home/shinsuke/tmp/fess-cloud/target/solr-jars/* org.apache.solr.cloud.ZkCLI -zkhost localhost:9180,localhost:9280,localhost:9380 -cmd upconfig -confname fessconf -confdir /home/shinsuke/tmp/fess-cloud/target/solr-config
java -classpath .:/home/shinsuke/tmp/fess-cloud/target/solr-jars/* org.apache.solr.cloud.ZkCLI -zkhost localhost:9180,localhost:9280,localhost:9380 -cmd linkconfig -collection fess-collection -confname fessconf

# Create 1 Fess Server
$BUILD_DIR/fess-server-1/bin/startup.sh

tail -f $BUILD_DIR/zksolr-server-1/logs/catalina.out \
    $BUILD_DIR/zksolr-server-2/logs/catalina.out \
    $BUILD_DIR/zksolr-server-3/logs/catalina.out \
    $BUILD_DIR/solr-server-1/logs/catalina.out \
    $BUILD_DIR/fess-server-1/logs/catalina.out 
