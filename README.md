# kcluster

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
```

Delete key pair created during stack creation
```sh
aws ec2 delete-key-pair --key-name MyKeyPair
```
