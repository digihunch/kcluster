## /etc/puppetlabs/code/environments/production/manifests/db.pp
node 'BackendNode1.ec2.internal' {
  package { 'mysql':
    ensure=> installed,
  }
}
