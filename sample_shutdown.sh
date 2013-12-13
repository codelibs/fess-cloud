#!/bin/bash

cd `dirname $0`
BASE_DIR=`pwd`
BUILD_DIR=$BASE_DIR/target

. $BASE_DIR/config.sh

for (( I = 0; I < ${#FESS_SERVER_NAMES[@]}; ++I )) do
    NAME=${FESS_SERVER_NAMES[$I]}
    $BUILD_DIR/$NAME/bin/shutdown.sh
done

for (( I = 0; I < ${#SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${SOLR_SERVER_NAMES[$I]}
    $BUILD_DIR/$NAME/bin/shutdown.sh
done

for (( I = 0; I < ${#ZK_SOLR_SERVER_NAMES[@]}; ++I )) do
    NAME=${ZK_SOLR_SERVER_NAMES[$I]}
    $BUILD_DIR/$NAME/bin/shutdown.sh
done

