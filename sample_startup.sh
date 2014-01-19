#!/bin/bash

cd `dirname $0`
BASE_DIR=`pwd`
MAX_COUNT=100

. $BASE_DIR/config.sh

bash $BASE_DIR/setup_cloud.sh

chmod +x $BUILD_DIR/*/bin/*.sh

# ZK hosts
for (( I = 0; I < ${#ZK_SOLR_SERVER_NAMES[@]}; ++I )) do
    SOLR_HOST=${ZK_SOLR_SERVER_HOSTS[$I]}
    SOLR_PORT=${ZK_SOLR_SERVER_SOLR_PORTS[$I]}
    ZK_PORT=${ZK_SOLR_SERVER_ZK_PORTS[$I]}
    if [ $I != 0 ] ; then
        ZK_HOSTS="${ZK_HOSTS},"
    fi
    ZK_HOSTS="${ZK_HOSTS}${SOLR_HOST}:${ZK_PORT}"
done
echo "ZooKeeper Hosts: $ZK_HOSTS"

# Create ZK+Solr Servers
for (( I = 0; I < ${#ZK_SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${ZK_SOLR_SERVER_NAMES[$I]}
    echo "Starting $NAME ..."
    $BUILD_DIR/$NAME/bin/startup.sh
done

tail -f $BUILD_DIR/*/logs/catalina.out &
TAIL_PID=$!

for (( I = 0; I < ${#ZK_SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${ZK_SOLR_SERVER_NAMES[$I]}
    COUNT=0
    while [ $COUNT -lt $MAX_COUNT ] ; do
        grep "Server startup in" $BUILD_DIR/$NAME/logs/catalina.out > /dev/null
        if [ $? = 0 ] ; then
            COUNT=$MAX_COUNT
        else
            echo "waiting for $NAME"
            sleep 1
        fi
        COUNT=`expr $COUNT + 1`
    done
done

# Create Solr Servers
for (( I = 0; I < ${#SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${SOLR_SERVER_NAMES[$I]}
    echo "Starting $NAME ..."
    $BUILD_DIR/$NAME/bin/startup.sh
done

for (( I = 0; I < ${#SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${SOLR_SERVER_NAMES[$I]}
    COUNT=0
    while [ $COUNT -lt $MAX_COUNT ] ; do
        grep "Server startup in" $BUILD_DIR/$NAME/logs/catalina.out > /dev/null
        if [ $? = 0 ] ; then
            COUNT=$MAX_COUNT
        else
            echo "waiting for $NAME"
            sleep 1
        fi
        COUNT=`expr $COUNT + 1`
    done
done

echo "Creating SolrCloud collection(core)."
echo java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd upconfig -confname $FESS_CONF -confdir $FESS_CONFIG_DIR
java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd upconfig -confname $FESS_CONF -confdir $FESS_CONFIG_DIR
echo java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd linkconfig -collection $FESS_COLLECTION -confname $FESS_CONF
java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd linkconfig -collection $FESS_COLLECTION -confname $FESS_CONF
echo curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=$FESS_COLLECTION&numShards=$NUM_SHARDS&replicationFactor=$REPLICATION_FACTOR&maxShardsPerNode=$MAX_SHARDS_PER_NODE"
curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=$FESS_COLLECTION&numShards=$NUM_SHARDS&replicationFactor=$REPLICATION_FACTOR&maxShardsPerNode=$MAX_SHARDS_PER_NODE"
echo curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATEALIAS&name=$FESS_COLLECTION_ALIAS&collections=$FESS_COLLECTION"
curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATEALIAS&name=$FESS_COLLECTION_ALIAS&collections=$FESS_COLLECTION"

echo "Creating SolrCloud collection(suggest)."
echo java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd upconfig -confname $FESS_SUGGEST_CONF -confdir $SUGGEST_CONFIG_DIR
java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd upconfig -confname $FESS_SUGGEST_CONF -confdir $SUGGEST_CONFIG_DIR
echo java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd linkconfig -collection $FESS_SUGGEST_COLLECTION -confname $FESS_SUGGEST_CONF
java -classpath .:$CLI_LIB_DIR/* $ZKCLI -zkhost $ZK_HOSTS -cmd linkconfig -collection $FESS_SUGGEST_COLLECTION -confname $FESS_SUGGEST_CONF
echo curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=$FESS_SUGGEST_COLLECTION&numShards=$NUM_SHARDS&replicationFactor=$REPLICATION_FACTOR&maxShardsPerNode=$MAX_SHARDS_PER_NODE"
curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATE&name=$FESS_SUGGEST_COLLECTION&numShards=$NUM_SHARDS&replicationFactor=$REPLICATION_FACTOR&maxShardsPerNode=$MAX_SHARDS_PER_NODE"
echo curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATEALIAS&name=$FESS_SUGGEST_COLLECTION_ALIAS&collections=$FESS_SUGGEST_COLLECTION"
curl "$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CREATEALIAS&name=$FESS_SUGGEST_COLLECTION_ALIAS&collections=$FESS_SUGGEST_COLLECTION"

# Create 1 Fess Server
for (( I = 0; I < ${#FESS_SERVER_NAMES[@]}; ++I )) do
    NAME=${FESS_SERVER_NAMES[$I]}
    echo "Starting $NAME ..."
    $BUILD_DIR/$NAME/bin/startup.sh
done

kill $TAIL_PID
tail -f $BUILD_DIR/*/logs/catalina.out 

