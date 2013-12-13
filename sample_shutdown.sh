#!/bin/bash

cd `dirname $0`
BASE_DIR=`pwd`
BUILD_DIR=$BASE_DIR/target

$BUILD_DIR/fess-server-1/bin/shutdown.sh

$BUILD_DIR/solr-server-1/bin/shutdown.sh

$BUILD_DIR/zksolr-server-3/bin/shutdown.sh
$BUILD_DIR/zksolr-server-2/bin/shutdown.sh
$BUILD_DIR/zksolr-server-1/bin/shutdown.sh

