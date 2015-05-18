#### Resource Facts

## Overview

This puppet module provides a `resources` fact that contains the current state
of resources as would be displayed using the puppet resource command on
each resource type.


## Module Description

Resource facts provide structured facts that described the current state of
resources you can enumerate with the `puppet resource` command.

For example, to set the `resource` fact to list all mounts and all users:

```puppet
factery::resource_fact { 'mount': }
factery::resource_fact { 'user': }
```

The mounts would be listed in a structured fact something like:

```json
{
  "resources": {
    "mount": {
      "/": {
        "name": "/",
        "ensure": "mounted",
        "device": "/dev/mapper/localhost-root",
        "blockdevice": null,
        "fstype": "ext3",
        "options": "errors=remount-ro",
        "pass": "1",
        "atboot": null,
        "dump": "0",
        "target": "/etc/fstab"
      },
      "/boot": {
        "name": "/boot",
        "ensure": "mounted",
        "device": "UUID=03f2131a-a980-43ec-9c35-3001f440830c",
        "blockdevice": null,
        "fstype": "ext2",
        "options": "defaults",
        "pass": "2",
        "atboot": null,
        "dump": "0",
        "target": "/etc/fstab"
      }
    }
  }
}
```


## Why?

Resource facts allow puppet to be aware of unmanaged resources. If you're using
the Puppet 4 DSL / future parser, you can then define behavior, such as
removing unmanaged users, or creating noop versions of the resources in order
to make them queryable in puppetdb.

### Conditional Behavior
For example, say you want to enable the `attr2` mount option if `/` is an XFS
filesystem, but not on EXT4 filesystems, because `attr2` isn't a valid EXT4
mount option. Using resource facts, you can use the
`$::resources['mount']['/']` hash, check what
`$::resources['mount']['/']['fstype']` is, then create a new resource with the
desired mount options.

### PuppetDB Queryability
All this data ends up in PuppetDB, so if you track packages with resource facts
you could (for example) use [puppetdbquery](https://github.com/dalen/node-puppetdbquery)
to search for all the nodes that *actually* have openssl installed, not just the
ones that manage it with Puppet.

### Discover Resources
If you use the excellent [puppetlabs-aws](https://github.com/puppetlabs/puppetlabs-aws)
module, you may have noticed that some AWS resources can be enumerated using
puppet resource but (frustratingly) can't get to that data. For example, say
you'd like to assign an available, unassigned elastic IP to a node. Problem is
that puppet doesn't know what that IP is during the compile, even though puppet
resource shows it. With resource facts, you can simply access the `resources`
structured fact, iterate over the elastic IP resources with puppet 4 iteration,
and pick an unused one.

### Selective Purge
Do you want to selectively purge resources? For example, perhaps you'd like to
remove AWS ec2 instances that don't conform to a certain tagging standard. You
can't just enable purge on all unmanaged `ec2_instance` resources because
no individual node is aware of all of them, and you're willing to tolerate
manually-provisioned nodes so long as they comply with your tagging rules.

If you track `ec2_instance` resources with factery, and you grok puppet 4
iteration, you're in luck. You can iterate over the `resources['ec2_instance']`
structured fact, select resources that do not include the correct data in the
`tags` parameter, and define new `ec2_instance` resources with those nodes set
to `ensure => absent`.

## Getting Started

Install the `danieldreier/resource_facts` module, then define which resources
you want to track:

```bash
puppet module install danieldreier/resource_facts
```

```puppet
factery::resource_fact { 'mount': }
```

After running the puppet code above, you can run `facter -p resources` to see
what resources are tracked. If you're using puppet apply to do this, you may
need to set a custom fact path, something like:

```bash
puppet config set factpath /var/lib/puppet/lib/facter:/etc/puppet/modules/resource_facts/lib/facter
```


## Caveats

* This module several seconds to facter run time if you track all resources with resource facts
* PuppetDB will store a lot more data if you use a lot of resource facts
* resource facts can only track facts that are enumerable
* Keep in mind what secrets may be put in puppetdb; the user resource shows password hashes

If you write code expecting a resource fact to exist and that causes
compilation to fail, that can prevent the resource fact to never be configured,
permanently breaking compiles. You *must* code defensively and handle the case
where the resource is not listed in the `$::resources` hash yet.
