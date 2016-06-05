This directory contains Heat templates to help configure
Vlans on a single NIC for each Overcloud role.

There are two versions of the controller role template, one with
an external network interface, and another without. If the
external network interface is not configured, the ctlplane address
ranges will be used for external (public) network traffic.

Configuration
-------------

To make use of these templates create a Heat environment that looks
something like this:

  resource\_registry:
    OS::TripleO::BlockStorage::Net::SoftwareConfig: network/config/single-nic-vlans/cinder-storage.yaml
    OS::TripleO::Compute::Net::SoftwareConfig: network/config/single-nic-vlans/compute.yaml
    OS::TripleO::Controller::Net::SoftwareConfig: network/config/single-nic-vlans/controller.yaml
    OS::TripleO::ObjectStorage::Net::SoftwareConfig: network/config/single-nic-vlans/swift-storage.yaml
    OS::TripleO::CephStorage::Net::SoftwareConfig: network/config/single-nic-vlans/ceph-storage.yaml

Or use this Heat environment file:

  environments/net-single-nic-with-vlans.yaml

Configuration with no External Network
--------------------------------------

Same as above except set the following value for the controller role:

    OS::TripleO::Controller::Net::SoftwareConfig: network/config/single-nic-vlans/controller-no-external.yaml

Configuration with System Management Network
--------------------------------------------

To enable the optional System Management network, create a Heat environment
that looks something like this:

  resource\_registry:
    OS::TripleO::Network::Management: ../network/management.yaml
    OS::TripleO::Controller::Ports::ManagementPort: ../network/ports/management.yaml
    OS::TripleO::Compute::Ports::ManagementPort: ../network/ports/management.yaml
    OS::TripleO::CephStorage::Ports::ManagementPort: ../network/ports/management.yaml
    OS::TripleO::SwiftStorage::Ports::ManagementPort: ../network/ports/management.yaml
    OS::TripleO::BlockStorage::Ports::ManagementPort: ../network/ports/management.yaml

Or use this Heat environment file:

  environments/network-management.yaml
