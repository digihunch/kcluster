# kcluster


---------------------------------------------------------------------------------------------------------------
| ResourceName          | Platform | Subnet  | Puppet Role | LaunchTemplate             | Server Role              |
|-----------------------|----------|---------|-------------|----------------------------|--------------------------|
| NATInstance           | Linux    | Public  | N/A         | Not launched by template   | Jumpbox and NAT Instance |
| KNodeWebInst1         | Linux2   | Public  | Agent       | KPublicNodeLaunchTemplate  | Frontend Web Server      |
| KNodePuppetMasterInst | Linux2   | Private | Master      | KPrivateNodeLaunchTemplate | Puppet Master            |
| KNodeBkndInst1        | Linux2   | Private | Agent       | KPrivateNodeLaunchTemplate | Backend App Server       |
---------------------------------------------------------------------------------------------------------------

Build a stack with mykcluster name 
```sh
aws cloudformation create-stack --stack-name mykcluster --template-body file://KFormation.yml --capabilities CAPABILITY_NAMED_IAM
```

Delete stack
```sh
aws cloudformation delete-stack --stack-name mykcluster
```

Describe stack
```sh
aws cloudformation describe-stacks --stack-name mykcluster
aws cloudformation describe-stacks --stack-name mykcluster | jq ".Stacks[].Outputs[]"
```

Delete key pair created during stack creation
```sh
aws ec2 delete-key-pair --key-name MyKeyPair
```
