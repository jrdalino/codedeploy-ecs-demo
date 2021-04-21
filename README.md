# codedeploy-ecs-demo

## Prequisites
- Reset Resources
```
% terraform destroy
% terraform apply
```

## Part 1: Prepare and push container images to the remote repo
- Clone the repo
```
% git clone https://github.com/jrdalino/aws-codedeploy-linear-canary-deployments-blog
```

- Build and push blue/green container images to the Amazon ECR repository (V1)
```
% cd ~/environment/aws-codedeploy-linear-canary-deployments-blog/Docker
% aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com
% docker build -t foo-bar-ecs .
% docker tag foo-bar-ecs:latest 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/foo-bar-ecs:v1
% docker push 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/foo-bar-ecs:v1
```

- Do the same for V2
```
% git fetch && git checkout v2
% docker build -t foo-bar-ecs .
% docker tag foo-bar-ecs:latest 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/foo-bar-ecs:v2
% docker push 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/foo-bar-ecs:v2
```

- Check Docker Images locally & Check Docker image pushed to ECR
```
% docker images
REPOSITORY                                                      TAG       IMAGE ID       CREATED          SIZE
182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/foo-bar-ecs   v2        e985d8be7124   30 seconds ago   22.6MB
foo-bar-ecs                                                     latest    e985d8be7124   30 seconds ago   22.6MB
182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/foo-bar-ecs   v1        df741806e96f   9 minutes ago    22.6MB
```

- Go to ALB URL: http://foo-bar-alb-1797939265.ap-southeast-1.elb.amazonaws.com/


## Part 2: Let's Deploy a new version
- Let's create a revision of the Task Definition being used and tell ECS to use the new task set Container Image URI: V2
```
- Go to AWS Console > ECS > ECS Task Definitions > Check the box beside "foo-bar-ecs" > Create new revision
- Scroll down > Container Definitions > Click on Container Name "foo-bar-ecs"
- Replace Image from "v1" to "v2" > Scroll Down Click Update and Create
```

- Update ECS service to use new Task Definition revision and trigger a CodeDeploy linear deployment.
```
- Go to AWS Console > ECS Cluster Console > Services > Check the box beside "foo-bar-ecs" > Click Update
- Select Revision latest > Click on Next Step, Accept all Defaults > Update Service
- Observe linear deployment: AWS Console > CodeDeploy Console > Deployments
- Validate using Browser: http://foo-bar-alb-1797939265.ap-southeast-1.elb.amazonaws.com/
```

## Part 3: Rollback
- Let's redeploy v1
```
- Go to AWS Console > ECS Cluster Console > Services > Check the box beside "ecs-blog-svc" > Click Update
- Select Revision 1 > Click on Next Step, Accept all Defaults > Update Service
- Observe linear deployment: AWS Console > CodeDeploy Console > Deployemnts
- Validate using Browser: http://ecs-b-publi-ve736ddh3n40-1396101962.ap-southeast-1.elb.amazonaws.com/
```

## Cleanup
- Tear down infra
```
% terraform destroy
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
- To Update my AWS Access Key: Go to https://wknc.awsapps.com/start#/ > Command line or programmatic access and copy credentials
```
% vi ~/.aws/credentials
```