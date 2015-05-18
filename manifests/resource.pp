# == Define: resources
#
# Defined type to include resource types in the resource fact
#
# === Parameters
#
# [*resource_type*]
#   Name of the resource to be included in the resources fact. The purpose of
#   having this separate from the resource title is so you can use it in a
#   module without having duplicate resources. For example, you might create
#   the following in a module that depends on enumerating mount resources:
#
#   factery::resource_fact {'modulename_mounts':
#     resource_type => 'mount'
#   }
#
#   this will ensure that mounts are enumerated regardless of whether this
#   is already requested elsewhere in the manifest, provided you use a unique
#   resource title.

define resource_facts::resource (
  $resource_type = $title
  ){
  include ::resource_facts

  # the reason for this strange approach is so that modules can add resource
  # facts without necessarily conflicting with each other
  @concat::fragment { "resource_fact_${resource_type}_${title}":
    target  => $::resource_facts::conf_file,
    content => "- ${resource_type}",
    order   => '02',
    tag     => 'resource_fact',
  }
}
