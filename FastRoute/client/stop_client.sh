#!/usr/bin/env bash
ps -ef | grep "/client/FastRoute_client.sh" | grep -v grep | awk '{print $2}' | sudo xargs sudo kill -9 