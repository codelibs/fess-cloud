#!/bin/bash

cd `dirname $0`
BASE_DIR=`pwd`
BUILD_DIR=$BASE_DIR/target
FESS_SRC_DIR=$BASE_DIR/src/fess
SOLR_SRC_DIR=$BASE_DIR/src/solr

FESS_DOWNLOAD_URL="http://sourceforge.jp/frs/redir.php?m=iij&f=%2Ffess%2F59462%2Ffess-server-8.2.0.zip"
FESS_NAME=fess-server-8.2.0
FESS_SERVER_DIR=$BUILD_DIR/$FESS_NAME
SOLR_NAME=solr-server-4.4.0
SOLR_SERVER_DIR=$BUILD_DIR/$SOLR_NAME
CLI_LIB_DIR=$BUILD_DIR/solr-jars
CONFIG_DIR=$BUILD_DIR/solr-config
ZKCLI=org.apache.solr.cloud.ZkCLI

. $BASE_DIR/config.sh

echo "Deleting $BUILD_DIR ..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

cd $BUILD_DIR

echo "Downloading Fess..."
wget -O ${FESS_NAME}.zip "$FESS_DOWNLOAD_URL"
#cp ../${FESS_NAME}.zip .
unzip ${FESS_NAME}.zip 

# copy fess to solr
echo "Copying Solr and Fess..."
cp $FESS_SRC_DIR/bin/setenv.sh $FESS_SERVER_DIR/bin
cp -r $FESS_SERVER_DIR $SOLR_SERVER_DIR

cp $SOLR_SRC_DIR/webapps/solr/WEB-INF/web.xml $SOLR_SERVER_DIR/webapps/solr/WEB-INF
cp $SOLR_SRC_DIR/solr/solr.xml $SOLR_SERVER_DIR/solr
cp $SOLR_SRC_DIR/solr/core1/conf/schema.xml $SOLR_SERVER_DIR/solr/core1/conf
cp $SOLR_SRC_DIR/solr/core1/conf/solrconfig.xml $SOLR_SERVER_DIR/solr/core1/conf
cp $SOLR_SRC_DIR/bin/zkcli.sh $SOLR_SERVER_DIR/bin
cp -r $SOLR_SRC_DIR/zk $SOLR_SERVER_DIR

rm $SOLR_SERVER_DIR/solr/core1/core.properties
rm -r $SOLR_SERVER_DIR/solr/core1/conf/dictionary
rm -r $SOLR_SERVER_DIR/solr/lib/lucene-gosen-4.4.0.jar
# workaround
rm $FESS_SERVER_DIR/webapps/fess/WEB-INF/lib/solr-solrj-4.3.1.jar
cp $BASE_DIR/src/workaround/solr-solrj-4.4.0.jar $FESS_SERVER_DIR/webapps/fess/WEB-INF/lib

chmod +x $FESS_NAME/bin/*.sh
rm -rf $SOLR_SERVER_DIR/webapps/fess
rm -rf $FESS_SERVER_DIR/webapps/solr
rm -rf $FESS_SERVER_DIR/solr

mkdir -p $CLI_LIB_DIR
cp $SOLR_SERVER_DIR/webapps/solr/WEB-INF/lib/*.jar $CLI_LIB_DIR
cp -r $SOLR_SERVER_DIR/solr/core1/conf $CONFIG_DIR

# ZK hosts
for (( I = 0; I < ${#ZK_SOLR_SERVER_NAMES[@]}; ++I )) do
    HOST=${ZK_SOLR_SERVER_HOSTS[$I]}
    ZK_PORT=${ZK_SOLR_SERVER_ZK_PORTS[$I]}
    if [ $I != 0 ] ; then
        ZK_HOSTS="${ZK_HOSTS},"
    fi
    ZK_HOSTS="${ZK_HOSTS}${HOST}:${ZK_PORT}"
done
echo "ZooKeeper Hosts: $ZK_HOSTS"

echo "Overwrite fess config files..."
cp -r $FESS_SRC_DIR/* $FESS_SERVER_DIR

# ZK+Solr
COUNT=1
for (( I = 0; I < ${#ZK_SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${ZK_SOLR_SERVER_NAMES[$I]}
    SOLR_PORT=${ZK_SOLR_SERVER_SOLR_PORTS[$I]}
    SOLR_SHUTDOWN_PORT=${ZK_SOLR_SERVER_SOLR_SHUTDOWN_PORTS[$I]}
    ZK_PORT=${ZK_SOLR_SERVER_ZK_PORTS[$I]}
    SERVER_DIR="$BUILD_DIR/$NAME"
    echo "Copying $SOLR_SERVER_DIR to $SERVER_DIR ..."
    cp -r $SOLR_SERVER_DIR $SERVER_DIR
    mkdir -p $SERVER_DIR/solr/zoo_data
    echo "$COUNT" > $SERVER_DIR/solr/zoo_data/myid
    ENV_FILE="$SERVER_DIR/bin/setenv.sh"
    echo "export JAVA_OPTS=\"\$JAVA_OPTS -DzkRun -DzkHost=$ZK_HOSTS -DsolrPort=$SOLR_PORT\"" >> $ENV_FILE
    echo "export JAVA_OPTS=\"\$JAVA_OPTS -Dsolr.solr.home=\$CATALINA_HOME/solr\"" >> $ENV_FILE
    sed -e "s/__SOLR_PORT__/$SOLR_PORT/g" \
        -e "s/__SOLR_SHUTDOWN_PORT__/$SOLR_SHUTDOWN_PORT/g" \
        $SOLR_SRC_DIR/conf/server.xml \
        > $SERVER_DIR/conf/server.xml
    COUNT=`expr $COUNT + 1`
done

# Solr
for (( I = 0; I < ${#SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${SOLR_SERVER_NAMES[$I]}
    SOLR_PORT=${SOLR_SERVER_PORTS[$I]}
    SOLR_SHUTDOWN_PORT=${SOLR_SERVER_SHUTDOWN_PORTS[$I]}
    SERVER_DIR="$BUILD_DIR/$NAME"
    echo "Copying $SOLR_SERVER_DIR $SERVER_DIR ..."
    cp -r $SOLR_SERVER_DIR $SERVER_DIR
    ENV_FILE="$SERVER_DIR/bin/setenv.sh"
    echo "export JAVA_OPTS=\"\$JAVA_OPTS -DzkHost=$ZK_HOSTS -DsolrPort=$SOLR_PORT\"" >> $ENV_FILE
    echo "export JAVA_OPTS=\"\$JAVA_OPTS -Dsolr.solr.home=\$CATALINA_HOME/solr\"" >> $ENV_FILE
    sed -e "s/__SOLR_PORT__/$SOLR_PORT/g" \
        -e "s/__SOLR_SHUTDOWN_PORT__/$SOLR_SHUTDOWN_PORT/g" \
        $SOLR_SRC_DIR/conf/server.xml \
        > $SERVER_DIR/conf/server.xml
done

# Fess
for (( I = 0; I < ${#FESS_SERVER_NAMES[@]}; ++I )) do
    NAME=${FESS_SERVER_NAMES[$I]}
    FESS_PORT=${FESS_SERVER_PORTS[$I]}
    FESS_SHUTDOWN_PORT=${FESS_SERVER_SHUTDOWN_PORTS[$I]}
    SERVER_DIR="$BUILD_DIR/$NAME"
    echo "Copying $FESS_SERVER_DIR $SERVER_DIR ..."
    cp -r $FESS_SERVER_DIR $SERVER_DIR
    ENV_FILE="$SERVER_DIR/bin/setenv.sh"
    echo "export JAVA_OPTS=\"\$JAVA_OPTS -Dfess.solr.data.dir=\$CATALINA_HOME/solr/core1/data -Dfess.log.file=\$CATALINA_HOME/webapps/fess/WEB-INF/logs/fess.out\"" >> $ENV_FILE
    sed -e "s/__FESS_PORT__/$FESS_PORT/g" \
        -e "s/__FESS_SHUTDOWN_PORT__/$FESS_SHUTDOWN_PORT/g" \
        $FESS_SRC_DIR/conf/server.xml \
        > $SERVER_DIR/conf/server.xml
    sed -e "s/__FESS_ZK_HOSTS__/$ZK_HOSTS/g" \
        -e "s/__FESS_COLLECTION__/$FESS_COLLECTION_ALIAS/g" \
        $FESS_SRC_DIR/webapps/fess/WEB-INF/classes/solrlib.dicon \
        > $SERVER_DIR/webapps/fess/WEB-INF/classes/solrlib.dicon
done

echo ""
echo "Upload a Solr configuration:"
echo "  $ java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd upconfig -confname $FESS_CONF -confdir $CONFIG_DIR"
echo "Link the uploaded Solr configuration with a collection:"
echo "  $ java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd linkconfig -collection $FESS_COLLECTION -confname $FESS_CONF"
echo "Run ZK commands:"
echo "  $ ./bin/zkcli.sh -z $ZK_HOSTS -cmd ..."

