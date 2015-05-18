# == Define: resources
#
# Defined type to include resource types in the resource fact
#
class resource_facts (
  $conf_file = "${::settings::confdir}/resource_facts.yaml"
  ) {
  concat { $conf_file:
    ensure         => present,
    ensure_newline => true,
  }
  concat::fragment { "resource_fact_${title}":
    target  => $conf_file,
    content => '---',
    order   => '01'
  }

  Concat::Fragment <| tag == resource_fact |>

}
