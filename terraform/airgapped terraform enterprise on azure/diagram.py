#!/usr/bin/env python3

from diagrams import Diagram
from diagrams.azure.compute import VMLinux
from diagrams.azure.database import CacheForRedis, DatabaseForPostgresqlServers
from diagrams.azure.network import LoadBalancers, NetworkInterfaces, Subnets, VirtualNetworks
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import BlobStorage
from diagrams.onprem.container import Docker
from diagrams.onprem.iac import Terraform

with Diagram("Requirements", show=False):

    cache = CacheForRedis("Redis Cache")
    db = DatabaseForPostgresqlServers("PostgreSQL DB")
    engine = Docker("Docker Engine")
    kv = KeyVaults("Key Vault")
    lb = LoadBalancers("Load Balancer")
    nic = NetworkInterfaces("Network Interface")
    storage = BlobStorage("Blob Storage")
    subnet_private = Subnets("Private Subnet")
    subnet_public = Subnets("Public Subnet")
    tfe = Terraform("Terraform Enterprise")
    vm = VMLinux("Linux Virtual Machine")
    vnet = VirtualNetworks("VNet")

    vnet >> [subnet_private, subnet_public]
    subnet_private >> kv
    [subnet_private, subnet_public] >> nic
    kv >> [cache, db, storage, vm]
    nic >> [lb, vm]
    vm >> engine
    [cache, db, engine, lb, storage] >> tfe
