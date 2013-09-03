pacemaker
===

This module sets up a corosync with pacemaker service. It allows you to
manage pacemaker resources, ordering constraints and cluster nodes.

It is highly recommended to read through pacemaker and corosync documentation first.
This module abstracts the `crm`, `cibadmin` and `cib_verify` cli tools. It generates
cib xml file from specified hashes, does cib verification and if that passes, then it
applies the configuration to the cluster.

This module is most flexible and most easier to manage when used with hiera.

## Classes

### pacemaker

#### Parameters
* `package` - used to specify what version of the package should be used.
Valid values: `installed`, `absent` or specific package version. Default:
`installed`. Note: Puppet cannot downgrade packages.

* `service` - service state. Valid values: `running` or `stopped`.
Default: `running`.

* `onboot` - whether to enable or disable the service on boot. Valid values:
`true`, `false` or `manual`. Default: `true`.

* `manage_cib` - if this is set to `true`, then the node which it is set on
will manage CIB configuration. Default: `false`.

* `service_delay` - Number of seconds for the corosync service to be delayed to start.
This is useful when you have LACP bonded network interfaces, because they usually take
around a minute to come up and start sending traffic. Default: `0`.

* `bindnetaddr` - This specifies the network address the corosync executive
should bind to. `bindnetaddr` should be an IP address configured on the system,
or a network address. For  example,  if  the  local  interface  is  192.168.5.92
with  netmask  255.255.255.0,  you should set bindnetaddr to 192.168.5.92 or 192.168.5.0.
If the local interface is 192.168.5.92 with netmask 255.255.255.192, set bindnetaddr
to 192.168.5.92 or 192.168.5.64, and so forth. It must be specified, otherwise puppet
run will fail.

* `mcastaddr` - This  is  the multicast address used by corosync executive.  The
default should work for most networks, but the network administrator should be queried
about a multicast address to use.  Avoid 224.x.x.x because this is a "config" multicast
address. It must be specified, otherwise puppet run will fail.

* `mcastport` - This specifies the UDP port number. It is possible to use the same
multicast address on a network with the corosync services configured for different
UDP ports. Please note corosync uses two UDP ports `mcastport` (for mcast receives)
and mcastport - 1 (for mcast sends). If you have multiple clusters on the same
network using the same mcastaddr please configure the mcastports with a gap.
Default: `5410`.

* `debug_logging` - This specifies whether debug output is logged for this particular
logger. Also can contain value trace, what is highest level of debug informations.
Default: `off`.

* `crm_config` - It's a hash. It's generated from a set of hashes which specify `crm_config`
parameters. See official documentation for valid parameters and their values. See examples
below for the syntax.

* `nodes` - Takes a list of node hostnames. Depending on your DNS and hostname settings, but
preferably you should use `hostname --short` names here. It must be specified, otherwise
puppet run will fail.

* `resources` - It's a hash of hashes. Each hash defines a resource in pacemaker xml config.
Valid hash keys are the following:
  * `agent` - which agent manages this resource, i.e. `ocf:heartbeat:IPaddr2`.
  * `params` - a hash of valid agent parameters.
  * `operations` - a hash of valid agent operations.
  * `clone` - whether to clone this resource or not. Valid values: `true` or `false`.
  * `clone_params` - valid cloned resource parameters.

* `constraints` - It's a hash of hashes. Currently only order constraint is supported, but
it's very easy to extend this module to support other constraint types. Valid hash keys:
  * `type` - type of a constraint. `order` is the only supported one right now.
  * `first` - which resource comes first, i.e. `nginx:start`
  * `then` - which resource comes next, i.e.`ip200:start`

#### Examples
    ---
    classes:
      - pacemaker
    
    pacemaker::bindnetaddr: 192.168.76.0
    pacemaker::mcastaddr: 226.95.1.1
    
    pacemaker::crm_config:
      'no-quorum-policy': 'ignore'
      'stonith-enabled': 'false'
      'cluster-infrastructure': 'openais'
    
    pacemaker::nodes:
      - 'node0'
      - 'node1'
      - 'node2'
    
    pacemaker::resources:
      'ip200':
        agent: 'ocf:heartbeat:IPaddr2'
        params:
          ip: 192.168.76.201
          cidr_netmask: 32
        operations:
          monitor:
            interval: 60s
      'ip201':
        agent: 'ocf:heartbeat:IPaddr2'
        params:
          ip: 192.168.76.202
          cidr_netmask: 32
        operations:
          monitor:
            interval: 60s
      'nginx':
        agent: 'ocf:heartbeat:nginx'
        operations:
          monitor:
            interval: 10s
        clone: true
        clone_params:
          'clone-max': 2
    
    pacemaker::constraints:
      'nginx_clone_before_ip201':
        type: order
        first: 'nginx_clone:start'
        then: 'ip201:start'


## Limitations
* Needs better validation of hash parameters.
* Changes will only be made if `cib_config.xml` changes, which means, that if you make a
change manually to the cluster configuration it will not be corrected until the next time
you make a change by changing one of the hashes.
* Supports Debian based distros only.


## Authors
* Vaidas Jablonskis <jablonskis@gmail.com>

