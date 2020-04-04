## /etc/puppetlabs/code/environments/production/manifests/web.pp
node 'WebNodeInst1.ec2.internal' {
  package { 'httpd':
    ensure=> installed,
  }
}
