# 1. Introduction to Polygon
CDN is a crucial Internet infrastructure that allows users to access Internet content with a short delay. With the development of CDN application scenarios, except for latency, resource types like bandwidth and CPU are also important for the performance of the CDN. Moreover, our measurement reveals that there are clear differences in the impact of different resource types on different CDN requests. Unfortunately, mainstream CDN server selection schemes only consider a single resource type, which cannot select the most suitable CDN servers under the conditions of multiple resource type requirements. 

We propose **Polygon**, a CDN server selection system supporting multiple resource demands. The specific resource demands are appended in requests to facilitate resource awareness. The keystone of the awareness of multiple resource types is a set of dispatchers, aiming to select suitable CDN servers and allocate requests. Meanwhile, Polygon adopts the 0-RTT and connection migration mechanisms of the QUIC protocol to mitigate the extra delay for connection and forwarding. The real-world evaluations on the Google Cloud Platform and extensive simulation using Mininet demonstrate the Polygon's advantages in improving QoS and resource utilization. The results in the real-world environment show that, compared with the existing solutions, Polygon can provide a better CDN service with a median job completion time reduction of up to 54.8%. Also, Polygon improves resource utilization by 13% in terms of bandwidth and by 7% in terms of CPU. 

- The workflow of Polygon for CDN server selection

![The workflow of Polygon for CDN server selection](./framework.png)

- The job completion time performance comparison of DNS-based, PureAnycast, FastRoutet, and Polygon

![The job completion time performance comparison of DNS-based, PureAnycast, FastRoutet, and Polygon](./results.png)


Mengying Zhou, Tiancheng Guo, Yang Chen, Junjie Wan, and Xin Wang. Polygon: A QUIC-Based CDN Server Selection System Supporting Multiple Resource Demands. Proc. of the 22nd ACM/IFIP Middleware Conference (Middleware’21), Industry Track, Virtual Event, Canada, Dec. 2021. [PDF](https://mengyingzhou.github.io/research/Zhou_Polygon_Middleware21.pdf)


# 2. Content of this repo
This repository contains two main parts: the implementation of the prototype and the evaluation-related scripts.

We list the four prototypes, which are:
1. [Polygon](./Polygon/README_Polygon.md)
2. [DNS-based solution baseline](./DNS_CDN/README_DNS.md)
3. [PureAnycast solution baseline](./Polygon/README_Polygon.md)
4. [FastRoute solution baseline](./FastRoute/README_FastRoute.md)

We have written detailed README documents for all of the above prototypes for reference. Each document includes configuration of the environment required to run the prototype, how to compile the prototype, and the pipeline for evaluating the prototype.
