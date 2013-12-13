#!/bin/sh

export JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true -server -Xmx512m -XX:MaxPermSize=128m -XX:-UseGCOverheadLimit -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -XX:+CMSIncrementalMode -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycleMin=0 -XX:+UseParNewGC -XX:+UseStringCache -XX:+UseTLAB -XX:+DisableExplicitGC"
# -XX:+UseCompressedOops for 64bit OS
# -XX:+UseCompressedStrings if java6u20 or above
# -XX:+OptimizeStringConcat if java6u21 or above

# if Java heap size is over 32GB heap, remove -XX:+UseCompressedOops
# if your machine has 2 or more cpu, enabled -XX:+CMSParallelRemarkEnabled by -XX:+UseConcMarkSweepGC

