#!/usr/bin/env bash

ps -ef | grep "data/client" | grep -v grep | awk '{print $3}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "data/client" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "data/start_polygon.sh" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "data/start_anycast.sh" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "iftop" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
# ps -ef | grep "python3 ~/data/get_active_port.py" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1