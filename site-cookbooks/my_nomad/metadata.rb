name 'my_nomad'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'All Rights Reserved'
description 'Installs/Configures my_nomad'
long_description 'Installs/Configures my_nomad'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'nomad'
depends 'ark'
depends 'hashi_ui'
