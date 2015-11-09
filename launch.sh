#!/bin/bash

./cleanup.sh

#declare array in bash
declare -a arrayInstance

mapfile -t arrayInstance < <(aws ec2 run-instances --image-id ami-d05e75b8 --count $1 --instance-type t2.micro --key-name itmo544-fall2015 --security-group-ids sg-15ba5c73 --subnet-id subnet-95a792cc --associate-public-ip-address --iam-instance-profile Name=phpDeveloperRole --user-data file://install-webserver.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

#display the content of the array
echo ${arrayInstance[@]}

#wait until instances are launched to proceed
aws ec2 wait instance-running --instance-ids ${arrayInstance[@]}
echo "instances are running"

#creating the load balancer
ELBURL=(`aws elb create-load-balancer --load-balancer-name $2 --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups sg-15ba5c73 --subnets subnet-95a792cc --output=text`);
echo $ELBURL
echo -e "\nFinished launching ELB and waiting 25 seconds"
echo -e "\n"
for i in {0..25};do echo -ne '.';sleep 1;done
echo -e "\n"

#registering the load balancer
aws elb register-instances-with-load-balancer --load-balancer-name $2 --instances ${arrayInstance[@]}

#health check for the load balancer
aws elb configure-health-check --load-balancer-name $2 --health-check Target=HTTP:80/index.html,Interval=50,UnhealthyThreshold=3,HealthyThreshold=3,Timeout=4

#launch configuration
aws autoscaling create-launch-configuration --launch-configuration-name itmo-fas-launch-conf --image-id ami-d05e75b8 --key-name itmo544-fall2015 --security-groups sg-6d6a7c0a --instance-type t2.micro --user-data file://install-webserver.sh --iam-instance-profile phpDeveloperRole

#creating the autoscaling group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-autoscaling-group --launch-configuration-name itmo-fas-launch-conf --load-balancer-names $2 --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-95a792cc 


#cloud watch
PolicyARN1=(`aws autoscaling put-scaling-policy --policy-name policy-1 --auto-scaling-group-name itmo-autoscaling-group --scaling-adjustment 1 --adjustment-type ChangeInCapacity`);

PolicyARN2=(`aws autoscaling put-scaling-policy --policy-name policy-2 --auto-scaling-group-name itmo-autoscaling-group --scaling-adjustment 1 --adjustment-type ChangeInCapacity`);

aws cloudwatch put-metric-alarm --alarm-name AddCapacity --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 120 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold --dimensions "Name=AutoScalingGroupName,Value=itmo-autoscaling-group" --evaluation-periods 2 --alarm-actions $PolicyARN1

aws cloudwatch put-metric-alarm --alarm-name RemoveCapacity --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 120 --threshold 10 --comparison-operator LessThanOrEqualToThreshold --dimensions "Name=AutoScalingGroupName,Value=itmo-autoscaling-group" --evaluation-perids 2 --alarm-actions $PolicyARN2   

#creating the databse
aws rds create-db-subnet-group --db-subnet-group-name mp1 --db-subnet-group-description "group for mp1" --subnet-ids subnet-95a792cc subnet-b2333cc5

aws rds create-db-instance --db-name farah-db --db-instance-identifier fabdelsa-mp1 --db-instance-class db.t2.micro --engine MySQL --master-username fabdelsa --master-user-password fabdelsa --allocated-storage 5 --db-subnet-group-name mp1 --publicly-accessible

aws rds wait db-instance-available --db-instance-identifier fabdelsa-mp1   
