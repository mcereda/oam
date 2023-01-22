#!/usr/bin/env python3

from diagrams import Cluster, Diagram
from diagrams.azure.compute import OsImages, VMLinux
from diagrams.azure.database import CacheForRedis, DatabaseForPostgresqlServers
from diagrams.azure.network import ApplicationGateway, NetworkInterfaces, VirtualNetworks
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import BlobStorage
from diagrams.custom import Custom
from diagrams.generic.os import RedHat
from diagrams.onprem.container import Docker
from diagrams.onprem.iac import Terraform

with Diagram("Requirements", show=False):
    container_engine = Docker("Docker Engine")
    replicated = Custom("Replicated", icon_path = "images/replicated.png")
    rhel = RedHat("RHEL")
    tfe = Terraform("Terraform Enterprise")

    with Cluster("Azure"):
        os = OsImages("Image")
        vnet = VirtualNetworks("VNet")

        with Cluster("Private Subnet"):
            cache = CacheForRedis("Redis Cache")
            db = DatabaseForPostgresqlServers("PostgreSQL DB")
            kv = KeyVaults("Key Vault")
            nic = NetworkInterfaces("Network Interface")
            storage = BlobStorage("Blob Storage")
            vm = VMLinux("Linux Virtual Machine")

        with Cluster("Public Subnet"):
            lb = ApplicationGateway("Application Gateway")

    vnet >> [kv, nic]
    kv >> [cache, db, lb, storage, vm]
    nic >> [lb, vm]
    rhel >> os >> vm
    storage >> vm >> container_engine >> replicated
    [cache, db, lb, replicated] >> tfe
