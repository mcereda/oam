# Beowulf cluster

Multi-computer architecture which can be used for parallel computations.  
It is usually composed of **commodity**, **non custom** hardware and software components and is trivially reproducible, like any PC capable of running a Unix-like operating system with standard Ethernet adapters and switches.

The cluster usually consists of one **server** node, and one or more **client** nodes connected via some kind of network.  
The server controls the whole cluster, and provides files to the clients. It is also the cluster's console and gateway to the outside world. Large Beowulf machines might have more than one server node, and possibly other nodes dedicated to particular tasks like consoles or monitoring stations.  
In most cases, client nodes in a Beowulf system are dumb, and the dumber the better. Clients are configured and controlled by the server, and do only what they are told to do.

Beowulf clusters behave more like a single machine rather than many workstations: nodes can be thought of as a CPU and memory package which is plugged into the cluster, much like a CPU or memory module can be plugged into a motherboard.

Beowulf is no more than a technology of clustering computers to form a parallel, virtual supercomputer. One can build a Beowulf class machine using a standard Linux distribution without any additional software; two networked computers sharing a folder via NFS and which trust each other to execute remote shells can be considered a two node Beowulf machine.

1. [Further readings](#further-readings)
1. [Sources](#sources)

## Further readings

- [Protogonus: The FINAL Labs™ HPC Cluster]

## Sources

- [Wikipedia]

<!-- projects' references -->
<!-- internal references -->
<!-- external references -->
[protogonus: the final labs™ hpc cluster]: https://www.final-labs.org/dev/protogonus
[wikipedia]: https://en.wikipedia.org/wiki/Beowulf_cluster
