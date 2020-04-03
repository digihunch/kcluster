# KLab infrastructure

This project provides an AWS CloudFormation template for lab environment. It specifies a virtual private cloud with two subnets, a public subnet and a private subnet.  This instruction also provides 3 examples of what can be configured in this lab infrastructure. 

# The Infrastructure as Code

A NAT instance is placed in the public subnet, it performs two functions: routing public traffic initiated from instances on private subnet; and serving as jumbox (aka Bastion host). Users need to have their own public key provided to the template as input so they can SSH to the NAT instance/jumpbox. On the jumpbox, a new RSA key pair is generated dynamically during the boot process and the public key is automatically added to other instances as public. By the time  the cloudformation stack is created, user will be able to SSH to any server from jumpbox with RSA key authorization.

Here are the VM instances defined in KFormation.yml template:

---------------------------------------------------------------------------------------------------------------
| ResourceName    | Platform | Subnet  | Puppet Role | LaunchTemplate             | Typical Server Role      |
| --------------- | -------- | ------- | ----------- | -------------------------- | ------------------------ |
| NATInstance     | Linux    | Public  | N/A         | N/A                        | Jumpbox and NAT Instance |
| KNodeWebInst1   | Linux2   | Public  | Agent       | KPublicNodeLaunchTemplate  | Frontend Web Server      |
| KNodeMasterInst | Linux2   | Private | Master      | KPrivateNodeLaunchTemplate | Puppet Master            |
| KNodeBkndInst1  | Linux2   | Private | Agent       | KPrivateNodeLaunchTemplate | Backend App Server       |
---------------------------------------------------------------------------------------------------------------

Amazon Linux distribution is built to be compatible with RedHat/CentOS. All commands in this lab work with CentOS 7 and RedHat 7 platforms. 

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
A keypar is created as part of stack creation for communication between bastion host and other servers. This key should be manually deleted after the lab. The key name is provided in stack output.
```sh
aws ec2 delete-key-pair --key-name MyKeyPair
```

It is important to remember to tear down the stack after the lab or they will incur charges.

# Lab 1. Create a local YUM repository server for Amazon Linux 2

In this lab, we will create a local YUM repository on KNodeWebInst1, and configure YUM client on KNodeBkndInst1. Then we confirm the YUM repo is correctly configured by using it to install a package.

## Build out infrastructure
Use KFormation.yml to create infrastructure and use describe-stacks command to obtain stack output. Then SSH to the Bastion Host.

## Create YUM repo on WebInst1
2. From Bastion Host SSH to WebInst1 by private DNS and run the followings to start nginx.
   ```sh
   sudo amazon-linux-extras install nginx1.12
   sudo systemctl start nginx
   ```
2. Once nginx is installed, browse by the public DNS address (port 80) and you should see nginx landing page.
3. Configure local repo named amzn2-core and sync from the official source.

   ```sh
   sudo yum install createrepo  yum-utils
   sudo mkdir -p /var/www/html/repos/amzn2-core
   sudo reposync -g -l -d -m --repoid=amzn2-core --newest-only --download-metadata --download_path=/var/www/html/repos/
   ```
4. The official repo contains 8400+ packages and can take a few minutes to sync. Once completed, create new repodata for the local repo:

   ```sh
   sudo createrepo -g comps.xml /var/www/html/repos/amzn2-core/
   ```
5. Then reconfigure nginx by editing repos.conf

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
6. In the server configuration file above, note that the server_name property include both public dns and private dns names. This way we can verify by public DNS, and pull from private DNS. After the configuration restart nginx:
   ```sh
   sudo systemctl restart nginx
   ```

7. Now browse public DNS you should see the content of the repo. To automatically synchronize the repo, we can also configure a cronjob to synchronize the repo. The entry looks like this:

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



# Lab 2. Minimal deployment of Gitlab Community

In this simple lab we install GitLab CE on an instance of T2 medium. Then create a porject on web portal and git clone it to a client.

1. Configure gitlab repo using a provided script.

   ```sh
   curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
   ```

2. Confirm gitlab repo is installed with "yum repolist". Then install Gitlab CE:

   ```sh
   sudo yum -y install gitlab-ce
   ```

   Open /etc/gitlab/gitlab.rb and confirm that external_url line already populated with public DNS. Browse to the public DNS address with plain HTTP and open the portal.

3. Once at the portal, set password for root user and login. Create a new project with public visibility and initialize repository with README. Suppose project name is project1 and copy the link for git clone.

4. Pick a server as client, run the following to clone directory to local:

   ```sh
   git clone http://ec2-34-207-137-79.compute-1.amazonaws.com/root/project1.git
   ```

Note: this lab involves a lot of simplifications. In a real environment the browser traffic must be secured. This should also be deployed on a private instance although you will need port forwarding to browse to GitLab portal.
