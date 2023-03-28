# 1. Outline
- [1. Outline](#1-outline)
- [2. Environment Configuration \& Compilation](#2-environment-configuration--compilation)
- [3. Conduct DNS-based scheme](#3-conduct-dns-based-scheme)



# 2. Environment Configuration & Compilation
To ensure a fair comparison and avoid bias by adopting different transmission protocols, we implement the FastRoute with the QUIC protocol. Please ref the environment configuration and compilation in [README_Polygon.md](../Polygon/README_Polygon.md)

# 3. Conduct DNS-based scheme
In the DNS-based solution, the request allocation is static, which means that a client's requests are only processed by a same server.
Therefore, we implement the DNS-based solution on top of the QUIC implementation of the client and server by directly specifying the server IP for the client.

1. bash remote_init.sh
2. bash remote_start_experiment.sh
3. bash remote_stop_experiment.sh
