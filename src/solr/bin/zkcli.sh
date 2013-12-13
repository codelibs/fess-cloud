#!/usr/bin/env bash

# You can override pass the following parameters to this script:
# 

JVM="java"

# Find location of this script

sdir="`dirname \"$0\"`"

PATH=$JAVA_HOME/bin:$PATH $JVM -Dlog4j.configuration=file:$sdir/../zk/resources/log4j.properties -classpath "$sdir/../webapps/solr/WEB-INF/lib/*:$sdir/../zk/lib/ext/*" org.apache.solr.cloud.ZkCLI ${1+"$@"}

