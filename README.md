# kcluster
aws cloudformation create-stack --stack-name mykcluster --template-body file://KFormation.yml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation delete-stack --stack-name mykcluster
aws cloudformation describe-stacks --stack-name mykcluster
aws ec2 delete-key-pair --key-name MyKeyPair
