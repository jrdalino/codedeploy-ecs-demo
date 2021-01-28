# codedeploy-ecs-demo

- Pull the Github Repo that supports this blog
```
git clone git@github.com:aws-samples/aws-codedeploy-linear-canary-deployments-blog.git
```

- Create ECR REpo
```
aws ecr create-repository \
--repository-name ecs-sample-app \
--region ap-southeast-1
```

- Build and push blue/green container images to the Amazon ECR repository (V1)
```
cd ~/environment/aws-codedeploy-linear-canary-deployments-blog/Docker
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com
docker build -t ecs-sample-app .
docker tag ecs-sample-app:latest 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v1
docker push 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v1
```

- V2
```
git fetch && git checkout v2
docker build -t ecs-sample-app .
docker tag ecs-sample-app:latest 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v2
docker push 182101634518.dkr.ecr.ap-southeast-1.amazonaws.com/ecs-sample-app:v2
```
