# codedeploy-ecs-demo

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
git fetch && git checkout v2
docker build -t ecs-sample-app .
docker tag ecs-sample-app:latest 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v2
docker push 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v2
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

-  Launch CloudFormation Stack to create VPC w/ 2 Subnets, ECS Fargate, ALB
```
% cat ~/environment/aws-codedeploy-linear-canary-deployments-blog/cloudformation/linear_ecs.yaml
```
```
INPUTS
- Stack Name: ecs-blog
- ImageURL: 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v1
```
```
OUTPUTS
cluster:
serviceName:
taskDefinition
loadBalancer > targetGroupArm
containerName: 
seurityGroups
subnets:
```

- Create an Amazon ECS Service for blue/gree deployments
```
% vi ~/environment/aws-codedeploy-linear-canary-deployments-blog/json_files/create_service.json
```

```
aws ecs create-service \
--cli-input-json file://create_service.json \
--region ap-southeast-1
```

```
{
    "cluster": "linearecs-ECSCluster-SM7VqD1GvNGg",
    "serviceName": "linearecs-svc",
    "taskDefinition": "arn:aws:ecs:ap-southeast-1:182101634518:task-definition/linearecs-svc:1",
    "loadBalancers": [
        {
            "targetGroupArn": "arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:targetgroup/linea-Targe-17BJT8FG061WT/f620652f18439815",
            "containerName": "linearecs-svc",
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
          "securityGroups": ["sg-0c538577d92e180e6"],
          "subnets": ["subnet-02f1e28d40fbb103d", "subnet-062403bf900755b7a"]
       }
    },
    "desiredCount": 2
}
```

- Create CodeDeploy Resources: CodeDeploy Application
```
aws deploy create-application \
--application-name linearecs-app \
--compute-platform ECS \
--region ap-southeast-1
```

- Update JSON File and Create CodeDeploy Resources: CodeDeploy Deployment Group
```
aws deploy create-deployment-group \
--cli-input-json file://code_deployment_group.json \
--region ap-southeast-1
```

```
{
	"applicationName": "linearecs-app",
	"deploymentGroupName": "linearecs-app-dg",
	"deploymentConfigName": "CodeDeployDefault.ECSLinear10PercentEvery1Minutes",
	"serviceRoleArn": "arn:aws:iam::182101634518:role/linearecs-EcsRoleForCodeDeploy-EC7NNZMX79AA",

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
					"name": "linea-Targe-17BJT8FG061WT"
				},
				{
					"name": "linea-Targe-1LYABM8TGVZJ5"
				}
			],
			"prodTrafficRoute": {
				"listenerArns": [
					"arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:listener/app/linea-Publi-1BHWQ3H2IKOES/747722d5859d647a/3470639a4da30578"
				]
			},
			"testTrafficRoute": {
					"listenerArns": [
						"arn:aws:elasticloadbalancing:ap-southeast-1:182101634518:listener/app/linea-Publi-1BHWQ3H2IKOES/747722d5859d647a/a33bf6a2cfc270ec"
					]
			}
		}]
	},
	"ecsServices": [{
		"serviceName": "linearecs-svc",
		"clusterName": "linearecs-ECSCluster-SM7VqD1GvNGg"
	}]
}
```

- We're ready to deploy. Go to: AWS Console > ECS Cluster > View Service

- Go to AWS Console > CodeDeploy > Applications > View Deployment Group

- Go to AWS Console > EC2 > ALB > View external DNS

- Go to AWS Console > ECS Task Definitions > Create new revision > Contaniner Definitions > Container Name > Add (v2) to Image > Click Update
```
182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v2
```

- Update ECS service to use new Task Definition revision and trigger a CodeDeploy linear deployment. ECS Cluster Console > Services > Service Name > Click on Update > Select Revision 2 > Click on Next Step, Accept all Defaults > Updare Service

- Observice linear deployment

## Cleanup
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
