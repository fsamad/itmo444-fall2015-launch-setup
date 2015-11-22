#!/bin/bash

ARN=(`aws sns create-topic --name mp2`)
echo "This is the ARN: $ARN"

aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value mp2

aws sns subscribe --topic-arn $ARN --protocol sms --notification-endpoint 13128334094
