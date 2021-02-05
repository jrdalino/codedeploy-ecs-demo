# codedeploy-ecs-demo

## Part 1: Prepare and push container images to the remote repo

- Pull the Github Repo that supports this blog. This repo has two (2) branches master: blue and v2: green
```
% git clone git@github.com:aws-samples/aws-codedeploy-linear-canary-deployments-blog.git
```

- Create ECR Repo
```
% aws ecr create-repository \
--repository-name ecs-sample-app \
--region ap-southeast-1
```

- Build and push blue/green container images to the Amazon ECR repository (V1)
```
% cd ~/environment/aws-codedeploy-linear-canary-deployments-blog/Docker
% aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com
% docker build -t ecs-sample-app .
% docker tag ecs-sample-app:latest 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v1
% docker push 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v1
```

- Do the same for V2
```
% git fetch && git checkout v2
% docker build -t ecs-sample-app .
% docker tag ecs-sample-app:latest 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v2
% docker push 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v2
```

- Check Docker Images locally
```
% docker images
REPOSITORY                                                         TAG               IMAGE ID       CREATED       SIZE
182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app   v2                1bea669782de   8 hours ago   22.3MB
ecs-sample-app                                                     latest            1bea669782de   8 hours ago   22.3MB
182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app   v1                256a20c88ee2   8 hours ago   22.3MB
nginx                                                              mainline-alpine   629df02b47c8   7 weeks ago   22.3MB
```

- Check Docker Images Pushed to ECR
```
https://ap-southeast-1.console.aws.amazon.com/ecr/repositories?region=ap-southeast-1
```

## Part 2: Prepare Networking, LB, ECS Cluster, ECS Service

-  Launch CloudFormation Stack to create VPC w/ 2 Subnets, ECS Fargate, ALB
```
% cat ~/environment/aws-codedeploy-linear-canary-deployments-blog/cloudformation/linear_ecs.yaml
```
```
INPUTS:
- Stack Name: ecs-blog
- ImageURL: 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v1

OUTPUTS:
```
| Key | Value | 
| --- | ----- | 
| ClusterName	                  | ecs-blog-ECSCluster-dZuc0OQbylBP | 
| Servicename                     | ecs-blog-svc | 
| TaskDefinitionArn               | arn:aws:ecs:ap-southeast-1:182101634518:task-definition/ecs-blog-svc:1 |
| TargetGroup1Arn                 | arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:targetgroup/ecs-b-Targe-15DFR1XALQKIU/bf1976921edb755a |
| PublicLoadBalancerSecurityGroup | sg-0aa2f50f00d8d90b8 | 
| PrivateSubnetOne                | subnet-06c11555fdd2fe1f8 |
| PrivateSubnetTwo                | subnet-01bca9ecc887f20a5 |

| Key | Value | 
| --- | ----- | 
| ApplicationName                 | ecs-blog-app | 
| DeploymentGroupName             | ecs-blog-app-dg | 
| EcsRoleForCodeDeploy            | arn:aws:iam::182101634518:role/ecs-blog-EcsRoleForCodeDeploy-1S22N373MH8X4 |
| TargetGroup1Name	          | ecs-b-Targe-15DFR1XALQKIU | 
| TargetGroup2Name	          | ecs-b-Targe-10W9GARCREMEF |
| PublicListener1                 | arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:listener/app/ecs-b-Publi-VE736DDH3N40/6bc988be78395133/75ca6591207822f9 | 
| PublicListener2                 | arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:listener/app/ecs-b-Publi-VE736DDH3N40/6bc988be78395133/e13fc925ed906e53 | 
| Servicename                     | ecs-blog-svc | 
| ClusterName	                  | ecs-blog-ECSCluster-dZuc0OQbylBP | 

| Key | Value | 
| --- | ----- | 
| ECSTaskExecutionRole            | arn:aws:iam::182101634518:role/ecs-blog-ECSTaskExecutionRole-1J7HBSWQ4UGI | 
| ExternalUrl                     | http://ecs-b-Publi-VE736DDH3N40-1396101962.ap-southeast-1.elb.amazonaws.com	|
| TargetGroup2Arn                 | arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:targetgroup/ecs-b-Targe-10W9GARCREMEF/9a1ee0dbf3859d3c |

- Create an Amazon ECS Service for blue/green deployments
```
% vi ~/environment/aws-codedeploy-linear-canary-deployments-blog/json_files/create_service.json
```
```
{
    "cluster": "ecs-blog-ECSCluster-dZuc0OQbylBP",
    "serviceName": "ecs-blog-svc",
    "taskDefinition": "arn:aws:ecs:ap-southeast-1:182101634518:task-definition/ecs-blog-svc:1",
    "loadBalancers": [
        {
            "targetGroupArn": "arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:targetgroup/ecs-b-Targe-15DFR1XALQKIU/bf1976921edb755a",
            "containerName": "ecs-blog-svc",
            "containerPort": 80
        }
    ],
    "launchType": "FARGATE",
    "schedulingStrategy": "REPLICA",
    "deploymentController": {
        "type": "CODE_DEPLOY"
    },
    "platformVersion": "LATEST",
    "networkConfiguration": {
       "awsvpcConfiguration": {
          "assignPublicIp": "ENABLED",
          "securityGroups": ["sg-0aa2f50f00d8d90b8"],
          "subnets": ["subnet-06c11555fdd2fe1f8", "subnet-01bca9ecc887f20a5"]
       }
    },
    "desiredCount": 2
}
```
```
% aws ecs create-service \
--cli-input-json file://create_service.json \
--region ap-southeast-1
```

- Go to URL: ecs-b-Publi-VE736DDH3N40-1396101962.ap-southeast-1.elb.amazonaws.com

## Part 3: Create the CodeDeploy Resources

- Create CodeDeploy Resources: CodeDeploy Application
```
aws deploy create-application \
--application-name ecs-blog-app \
--compute-platform ECS \
--region ap-southeast-1
```

- Update JSON File and Create CodeDeploy Resources: CodeDeploy Deployment Group
```
% vi ~/environment/aws-codedeploy-linear-canary-deployments-blog/json_files/code_deployment_group.json
```
```
{
	"applicationName": "ecs-blog-app",
	"deploymentGroupName": "ecs-blog-app-dg",
	"deploymentConfigName": "CodeDeployDefault.ECSLinear10PercentEvery1Minutes",
	"serviceRoleArn": "arn:aws:iam::182101634518:role/ecs-blog-EcsRoleForCodeDeploy-1S22N373MH8X4",

	"deploymentStyle": {
		"deploymentType": "BLUE_GREEN",
		"deploymentOption": "WITH_TRAFFIC_CONTROL"
	},
	"blueGreenDeploymentConfiguration": {
		"terminateBlueInstancesOnDeploymentSuccess": {
			"action": "TERMINATE",
			"terminationWaitTimeInMinutes": 5
		},
		"deploymentReadyOption": {
			"actionOnTimeout": "CONTINUE_DEPLOYMENT"
		}
	},
	"loadBalancerInfo": {
		"targetGroupPairInfoList": [{
			"targetGroups": [{
					"name": "ecs-b-Targe-15DFR1XALQKIU"
				},
				{
					"name": "ecs-b-Targe-10W9GARCREMEF"
				}
			],
			"prodTrafficRoute": {
				"listenerArns": [
					"arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:listener/app/ecs-b-Publi-VE736DDH3N40/6bc988be78395133/75ca6591207822f9"
				]
			},
			"testTrafficRoute": {
					"listenerArns": [
						"arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:listener/app/ecs-b-Publi-VE736DDH3N40/6bc988be78395133/e13fc925ed906e53"
					]
			}
		}]
	},
	"ecsServices": [{
		"serviceName": "ecs-blog-svc",
		"clusterName": "ecs-blog-ECSCluster-dZuc0OQbylBP"
	}]
}
```
```
% aws deploy create-deployment-group \
--cli-input-json file://code_deployment_group.json \
--region ap-southeast-1
```

- Let's Review what we've created 
```
- View ECS Service and Tasks: AWS Console > ECS Cluster > View Service & Tasks
- View Application Load Balancer, Listerners & Target Groups
- Review Deployment Group: AWS Console > CodeDeploy > Applications > View Deployment Group
- Go to AWS Console > EC2 > ALB > View external DNS: http://ecs-b-publi-ve736ddh3n40-1396101962.ap-southeast-1.elb.amazonaws.com/
```

## Let's Deploy! 
- Let's create a revision of the Task Definition being used and tell ECS to use the new task set Container Image URI: V2
```
- Go to AWS Console > ECS > ECS Task Definitions > Check the box beside "ecs-blog-svc" > Create new revision
- Scroll down > Container Definitions > Click on Container Name "ecs-blog-svc"
- Replace Image from "v1" to "v2" > Scroll Down Click Update and Create
```

- Update ECS service to use new Task Definition revision and trigger a CodeDeploy linear deployment.
```
- Go to AWS Console > ECS Cluster Console > Services > Check the box beside "ecs-blog-svc" > Click Update
- Select Revision 2 > Click on Next Step, Accept all Defaults > Update Service
- Observe linear deployment: AWS Console > CodeDeploy Console > Deployemnts
- Validate using Browser: http://ecs-b-publi-ve736ddh3n40-1396101962.ap-southeast-1.elb.amazonaws.com/
```

## Cleanup
### Clean Up for Part 3 
- Delete Deployment Group
- Delete Application

### Clean Up for Part 2
- Delete ECS Service
- Delete CloudFormation Template (ECS, ALB, VPC)

### Clean Up for Part 1
- Delete ECR Repo
```
% aws ecr batch-delete-image --repository-name ecs-sample-app --image-ids imageTag=v2
% aws ecr delete-repository \
--repository-name ecs-sample-app
```
- Delete Local Docker Images
```
% docker image rm -f <image_id>
```
- Delete Local Git Repo
```
% rm -rf aws-codedeploy-linear-canary-deployments-blog
```

## References
- https://aws.amazon.com/blogs/containers/aws-codedeploy-now-supports-linear-and-canary-deployments-for-amazon-ecs/

## Appendix: Update my AWS Access Key
- Go to https://wknc.awsapps.com/start#/ > Command line or programmatic access and copy credentials
```
% vi ~/.aws/credentials
```
