# 1. Outline
- [1. Outline](#1-outline)
- [2. Introduction to FastRoute](#2-introduction-to-fastroute)
- [3. Environment Configuration \& Compilation](#3-environment-configuration--compilation)
- [4. FastRoute deployment requirements: machine type](#4-fastroute-deployment-requirements-machine-type)
- [5. Conduct experiment](#5-conduct-experiment)
  - [5.1. Single machine test](#51-single-machine-test)
  - [5.2. Large-Scale Experiments](#52-large-scale-experiments)



# 2. Introduction to FastRoute
FastRoute is a CDN selection system applied to Microsoft's Bing search engine. The characteristic of Bing is that the number of requests/request files is large, and the size of each request is small. The FastRoute system mainly performs load balancing on the instantaneous traffic size, and the index of concern is only the throughput. This technology utilizes anycast technology to select the nearest routed CDN node. In order to avoid the overload of a single node, FastRoute builds a hierarchical relationship to achieve load balancing through traffic migration. Once the server load of the outer layer exceeds the limit, the traffic will be transferred to the inner layer and passed in turn.

Ashley Flavel, Pradeepkumar Mani, David A. Maltz, et al. "FastRoute: A scalable load-aware anycast routing architecture for modern CDNs." Proc. of NSDI, 381–394. 2015.

# 3. Environment Configuration & Compilation
To ensure a fair comparison and avoid bias by adopting different transmission protocols, we implement the FastRoute with the QUIC protocol. Please ref the environment configuration and compilation in [README_Polygon.md](../Polygon/README_Polygon.md)

# 4. FastRoute deployment requirements: machine type
- DNS resolution server
   1. Use [BIND](https://www.isc.org/bind/) software to resolve DNS requests.
   2. When it is necessary to migrate the traffic from the outer layer to the inner server, the DNS resolver will modify the configuration file of BIND to make the domain name resolution change from the IP of the outer server to the IP of the inner server
- server:
   1. CDN server
   2. It will be logically divided into outer and inner servers. We set three machines as the outer layer and two machines as the inner layer.
   4. When the **CPU of the outer server exceeds a certain load**, it will actively send a traffic migration request to the DNS resolver.
   5. The content of the traffic migration request is: the server's IP in outer layer, the server's IP to take over the migrated traffic in the inner layer
- client
   1. Client
   2. A DNS resolution request will be made every time a DNS request is sent to ensure that each request is the latest IP. The IP of the DNS resolver is specified as "10.128.0.2", which is the IP of the above-mentioned DNS resolution server


# 5. Conduct experiment
## 5.1. Single machine test
1. DNS (require root permission)
```
cd ~/FastRoute/DNS && sudo python3 dns.py
```

2. server
```
cd ~ && bash ~/FastRoute/server/FastRoute_server.sh # Run the server main program
cd ~/FastRoute/server && python3 LoadMonitor.py # Run CPU monitor
```

3. client
```
bash ~/FastRoute/client/FastRoute_client.sh
```

## 5.2. Large-Scale Experiments
1. bash remote_init.sh
2. bash remote_start_experiment.sh
3. bash remote_stop_experiment.sh
