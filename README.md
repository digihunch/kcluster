# KLab infrastructure


# The Infrastructure

---------------------------------------------------------------------------------------------------------------
| ResourceName          | Platform | Subnet  | Puppet Role | LaunchTemplate             | Typical Server Role      |
|-----------------------|----------|---------|-------------|----------------------------|--------------------------|
| NATInstance           | Linux    | Public  | N/A         | N/A                        | Jumpbox and NAT Instance |
| KNodeWebInst1         | Linux2   | Public  | Agent       | KPublicNodeLaunchTemplate  | Frontend Web Server      |
| KNodePuppetMasterInst | Linux2   | Private | Master      | KPrivateNodeLaunchTemplate | Puppet Master            |
| KNodeBkndInst1        | Linux2   | Private | Agent       | KPrivateNodeLaunchTemplate | Backend App Server       |
---------------------------------------------------------------------------------------------------------------

## Prerequisite for KFormation.yml
AWSCLI should be configured in local SSH client (access key, secret key, region specified). In addition, the CloudFormation template requires
- PubKeyName to specify the public key stored in the AWS account
- PuppetRepoURL (default is https://yum.puppet.com/puppet6/el/8/x86_64/)
- InstanceType (default is t2.micro)

## Common commands 

 
- Build a stack with mykcluster name 
```sh
aws cloudformation create-stack --stack-name mykcluster --template-body file://KFormation.yml --capabilities CAPABILITY_NAMED_IAM
```

- Describe stack
```sh
aws cloudformation describe-stacks --stack-name mykcluster
aws cloudformation describe-stacks --stack-name mykcluster | jq ".Stacks[].Outputs[]"
```
The describe-stacks command returns hostname of the newly created instances.

- Delete the stack created
```sh
aws cloudformation delete-stack --stack-name mykcluster
```
A keypar is created as part of stack creation for communication between bastion host and other servers. This key should be manually deleted after tearing down the stack. The key name is provided in stack output.
```sh
aws ec2 delete-key-pair --key-name MyKeyPair
```


# Lab 1. Create a local YUM repository server for Amazon Linux 2

In this lab, we will create a local YUM repository on KNodeWebInst1, and configure YUM client on KNodeBkndInst1. Then we confirm the YUM repo is correctly configured by using it to install a package.

## Build out infrastructure
Use KFormation.yml to create infrastructure and use describe-stacks command to obtain stack output.

## Create YUM repo on WebInst1
1. SSH to Bastion Host
2. From Bastion Host SSH to WebInst1 by private DNS and run the followings to start nginx.
```sh
sudo amazon-linux-extras install nginx1.12
sudo systemctl start nginx
```
3. Once nginx is installed, browse by the public DNS address (port 80) and you should see nginx landing page.
4. Configure local repo named amzn2-core and sync from the official source.
```sh
sudo yum install createrepo  yum-utils
sudo mkdir -p /var/www/html/repos/amzn2-core
sudo reposync -g -l -d -m --repoid=amzn2-core --newest-only --download-metadata --download_path=/var/www/html/repos/
```
5. The official repo contains 8400+ packages and can take a few minutes to sync. Once completed, create new repodata for the local repo:
```sh
sudo createrepo -g comps.xml /var/www/html/repos/amzn2-core/
```
6. Then reconfigure nginx by editing repos.conf
```sh
sudo vim /etc/nginx/conf.d/repos.conf
```
```
server {
        listen   80;
        server_name publicdns.compute-1.amazonaws.com privatedns.internal;
        root   /var/www/html/repos;
        location / {
                index  index.php index.html index.htm;
                autoindex on;   #enable listing of directory index
        }
}
```
7. Note that in the configuration, server_name should include both public dns and private dns names. This way we can verify by public DNS, and pull from private DNS. After the configuration restart nginx
```sh
sudo systemctl restart nginx
```

8. Now browse by public DNS you should see the content of the repo. Optionally, we can also configure a cronjob to synchronize the repo. The entry looks like this:
```sh
reposync -g -l -d -m --repoid=amzn2-core --newest-only --download-metadata --download_path=/var/www/html/repos/ && createrepo -g comps.xml /var/www/html/repos/amzn2-core/ 
```

## Configure YUM client on BackendNode1
1. From Bastion host, SSH to BackendNode1. This node is in private subnet, although it still can access Internet through a NAT instance in the public subnet.
2. Configure YUM repo source:
```sh
sudo vim /etc/yum.repos.d/local-repos.repo
```
   with the following content
   ```
   [local-amzn2-core]
name=AmazonLinux 2 Core Local
baseurl=http://privatedns.internal/amzn2-core/
gpgcheck=0
enabled=1
   ```
3. Confirm that local-amz2-core repo is listed when you run 
```sh
sudo yum repolist
```
4. Now test the repo server by removing a package (e.g. word) and re-installing it using local repo
```sh
sudo yum remove words
sudo yum install words --disablerepo=* --enablerepo=local-amzn2-core
```
