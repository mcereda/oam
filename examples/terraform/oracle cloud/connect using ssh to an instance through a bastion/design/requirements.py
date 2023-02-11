#!/usr/bin/env python3

from diagrams import Cluster, Diagram
from diagrams.oci.compute import VM
from diagrams.oci.connectivity import NATGateway
from diagrams.oci.network import RouteTable, Vcn
from diagrams.onprem.client import User
from diagrams.onprem.network import Internet

with Diagram("Requirements", show=False):

    i = Internet("Internet")
    vcn = Vcn("VCN")
    u = User("User")

    with Cluster("Private Subnet"):

        b = VM("Bastion")
        ng = NATGateway("NAT Gateway")
        rt = RouteTable("Route Table")
        vm = VM("Instance")

    vcn >> [ng, rt] >> b >> vm
    u >> i >> b
