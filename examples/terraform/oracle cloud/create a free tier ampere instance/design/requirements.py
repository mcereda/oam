#!/usr/bin/env python3

from diagrams import Cluster, Diagram
from diagrams.oci.compute import VM
from diagrams.oci.network import InternetGateway, RouteTable, Vcn

with Diagram("Requirements", show=False):

    vcn = Vcn("VCN")
    vm = VM("Ampere instance")

    with Cluster("Public Subnet"):

        ig = InternetGateway("Internet Gateway")
        rt = RouteTable("Route Table")

    vcn >> ig >> rt
    rt >> vm
