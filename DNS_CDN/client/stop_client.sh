#!/usr/bin/env bash
ps -ef | grep "/client/DNSCDN_client.sh" | grep -v grep | awk '{print $2}' | sudo xargs sudo kill -9 