# Beowulf cluster

Multi-computer architecture which can be used for parallel computations.<br/>
It is usually composed of **commodity**, **non custom** hardware and software components and is trivially reproducible, like any PC capable of running a Unix-like operating system with standard Ethernet adapters and switches.

The cluster usually consists of one **server** node, and one or more **client** nodes connected via some kind of network.<br/>
The server controls the whole cluster, and provides files to the clients. It is also the cluster's console and gateway to the outside world. Large Beowulf machines might have more than one server node, and possibly other nodes dedicated to particular tasks like consoles or monitoring stations.<br/>
In most cases, client nodes in a Beowulf system are dumb, and the dumber the better. Clients are configured and controlled by the server, and do only what they are told to do.

Beowulf clusters behave more like a single machine rather than many workstations: nodes can be thought of as a CPU and memory package which is plugged into the cluster, much like a CPU or memory module can be plugged into a motherboard.

Beowulf is no more than a technology of clustering computers to form a parallel, virtual supercomputer. One can build a Beowulf class machine using a standard Linux distribution without any additional software; two networked computers sharing a folder via NFS and which trust each other to execute remote shells can be considered a two node Beowulf machine.

## Table of contents <!-- omit in toc -->

1. [Scheduler](#scheduler)
1. [Create a quick and dirty cluster](#create-a-quick-and-dirty-cluster)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Scheduler

Takes care of scheduling the jobs and juggling the resources in the cluster.<br/>
The most used one at the time of writing is [Slurm].

## Create a quick and dirty cluster

Uses [MPICH] on Linux.<br/>
Just follow this procedure:

1. prepare at least 2 Linux hosts
1. assign a fixed, known IP address to all the hosts
1. create a file on the **server** node listing the IP addresses of all the **client** nodes (e.g. `machines_file`)
1. install, enable and start SSH on all the hosts
1. configure SSH on all the hosts to let the **server** node connect to all the **client** nodes **without** using a password
1. install [MPICH] on all the hosts, possibly the same version
1. test the installation:
   ```sh
   # execute `hostname` on all hosts
   mpiexec -f 'machines_file' -n 'number_of_processes' 'hostname'
   ```

See the [Vagrant example].

## Further readings

- [Protogonus: The FINAL Labs™ HPC Cluster]
- [A simple Beowulf cluster]
- Building a Beowulf cluster from old MacBooks:
  - [part 1][building a beowulf cluster from old macbooks - part 1]
  - [part 2][building a beowulf cluster from old macbooks - part 2]
  - [Parallel computing with custom Beowulf cluster]
- [Engineering a Beowulf-style compute cluster]
- [Parallel and distributed computing with Raspberry Pi clusters]
- [Sequence analysis on a 216-processor Beowulf cluster]
- [Setting up an MPICH2 cluster in Ubuntu]
- [The Beowulf howto]
- [BOINC]
- [Folding@Home]

## Sources

All the references in the [further readings] section, plus the following:

- [beowulf.org][beowulf]
- [Wikipedia]

<!--
  References
  -->

<!-- Upstream -->
[apptainer]: https://github.com/apptainer/apptainer
[beowulf]: https://beowulf.org/overview/
[hkube]: https://hkube.io/
[mpi4py]: https://mpi4py.readthedocs.io/en/stable/
[mpich]: https://www.mpich.org/
[openmpi]: https://www.open-mpi.org/doc/current/
[pvm]: https://en.wikipedia.org/wiki/Parallel_Virtual_Machine
[singularity]: https://github.com/gmkurtzer/singularity
[slurm]: https://slurm.schedmd.com/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[boinc]: boinc.md

<!-- Files -->
[vagrant example]: ../examples/vagrant/beowulf%20cluster/Vagrantfile

<!-- Others -->
[a container for hpc]: https://www.admin-magazine.com/HPC/Articles/Singularity-A-Container-for-HPC
[a simple beowulf cluster]: http://www.kerrywong.com/2008/11/04/a-simple-beowulf-cluster/
[building a beowulf cluster from old macbooks - part 1]: https://jondeaton.wordpress.com/2017/10/01/building-a-beowulf-cluster-from-old-macbooks-part-1/
[building a beowulf cluster from old macbooks - part 2]: https://jondeaton.wordpress.com/2017/10/08/building-a-beowulf-cluster-from-old-macbooks-part-2/
[building a simple beowulf cluster with ubuntu]: https://www-users.york.ac.uk/~mjf5/pi_cluster/src/Building_a_simple_Beowulf_cluster.html
[container orchestration on hpc systems through kubernetes]: https://journalofcloudcomputing.springeropen.com/articles/10.1186/s13677-021-00231-z
[engineering a beowulf-style compute cluster]: https://webhome.phy.duke.edu/~rgb/Beowulf/beowulf_book/beowulf_book/index.html
[folding@home]: https://foldingathome.org/
[hpc on the cloud: slurm cluster vs kubernetes]: https://www.matecdev.com/posts/cloud-hpc-kubernetes-vs-slurm.html
[kubernetes meets high-performance computing]: https://kubernetes.io/blog/2017/08/kubernetes-meets-high-performance/
[kubernetes, containers and hpc]: https://www.hpcwire.com/2019/09/19/kubernetes-containers-and-hpc/
[parallel and distributed computing with raspberry pi clusters]: https://opensource.com/article/23/3/parallel-distributed-computing-raspberry-pi-clusters
[parallel computing with custom beowulf cluster]: https://jondeaton.wordpress.com/2017/12/04/parallel-computing-with-custom-beowulf-cluster/
[protogonus: the final labs™ hpc cluster]: https://www.final-labs.org/dev/protogonus
[sequence analysis on a 216-processor beowulf cluster]: https://www.usenix.org/legacy/publications/library/proceedings/als00/2000papers/papers/full_papers/michalickova/michalickova.pdf
[setting up an mpich2 cluster in ubuntu]: https://help.ubuntu.com/community/MpichCluster
[shifter: bringing linux containers to hpc]: https://www.nersc.gov/research-and-development/user-defined-images/
[the beowulf howto]: https://tldp.org/HOWTO/Beowulf-HOWTO/index.html
[wikipedia]: https://en.wikipedia.org/wiki/Beowulf_cluster
