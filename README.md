# GVM (OpenVAS) Docker

This repository serves as the "builder" portion of the GVM (OpenVAS) single container deployed to docker hub.
It offers the latest version of OpenVAS (Asof 23/11/23 V23.0.0) built in a single container made for rapid deployment
on your own device or in the cloud (see instructions below).

Although no warranty or support is offered on this repository, Cytix will endeavour to keep this repository up to date as
newer versions of GVM are released by the Greenbone team. We also welcome pull requests into the repository for additional features
or updates.

## Build/Installation Instructions

A prebuilt version of this repository is available on the docker hub, at https://hub.docker.com/r/cytix/openvas.
You can begin using this immediately by running `docker pull cytix/openvas` with docker installed in the command line.

We do however recommend performing a build yourself. This can be performed with the following commands:

```bash
# clone the OpenVAS repository
git clone https://github.com/cytix-software/openvas-docker.git && cd openvas-docker

# build the docker container. Note this may take up to or over 1 hour. (See build arguments below for more recommended options)
# note you also don't need to use buildx or --platform if on an x64/x86 machine. The build below is provided for ARM based systems,
# such as the M(X) series macbooks.
docker buildx build --platform linux/amd64 -f Dockerfile -t openvas:latest .

# run the container (Note the --platform flag is not required on x64/x86 machines. This is provided for ARM based systems)
docker run -p 8080:80 --name openvas --platform linux/amd64 -d openvas:latest
```

Following a successful build using the steps above, the OpenVAS server should now be accesible via http://localhost:8080/.
The default username and password are admin and password respectively.

### Build Arguments.

We recommend reading the build arguments and applying them based on your required use case. They can be applied during the
build step of the docker file using the `--build-arg W=X Y=Z` flag.

#### FEED_PROVISION
- Available values: `init`, `build`
Defines when the scanner feed update takes place, either during the `build` step or on `init`ialisaton of the container.
For the most up to date scanner feed, it is recommended to use `init` (default), although if you want rapid container
initialisation (e.g cloud deployments), it is recommended to use `build`. The step itself takes up to or over 15 minutes
and therefore can be useful to perform on a high end machine.

#### GVM_ADMIN_PASSWORD
The GVM admin password is the password attributed to the default admin user created during the build process of the GVM
image. The default is `password` and it is highly recommended this is changed to be more secure, especially if you are
hosting the container with a public facing URL.

## Deployment to the Cloud (AWS Example)
Due to the single container nature of this image, it can easily be deployed into the cloud using a container orchestration
service, such as Kubenetes or ECS. In the example below we will describe how to self-host OpenVAS in the cloud for additional
compute resource capabilities or for offering Vulnerability Scanning as a Service (VSaaS).

The following guide will outline using AWS's ECS service along with the pre-compiled docker image hosted on the docker registry,
to use your own image build follow the guide above and deploy to your own private container repository, replacing the image URL when required with the
URL of your hosted image. The ECS instructions supplied should also be easily converted into commands for your appropriate cloud host, like GCP or Azure.

With the AWS CLI installed and signed in locally, run the following commands to run a 2vCPU 4GB instance in the cloud. This is the minimum recommended size
for a hosted VM, and ideally should be larger to support bigger hosts or more parallel tasks. A 4vCPU 8GB instance we have found reasonable enough for most
use cases in our testing, but it is advised to attempt running your own tests to see which server size works best for you.

```bash
# create the cluster to run the task against
aws ecs create-cluster --cluster-name openvas-cluster

# create the task definition input
TASK_DEFINITION='{
  "family": "openvas",
  "taskRoleArn": "<TASK ROLE ARN>",
  "executionRoleArn": "<EXECUTION ROLE ARN>",
  "networkMode": "awsvpc",
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "2048",
  "memory": "4096",
  "runtimePlatform": {
    "cpuArchitecture": "X86_64",
    "operatingSystemFamily": "LINUX"
  }
  "containerDefinitions": [
    {
      "name": "openvas",
      "image": "docker.io/cytix/openvas:latest",
      "portMappings": [
        {
          "name": "openvas-80-tcp",
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp",
          "appProtocol": "http"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "true",
          "awslogs-group": "/ecs/openvas",
          "awslogs-region": "eu-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost/ || exit 1"
        ],
        "interval": 10,
        "timeout": 5,
        "retries": 10,
        "startPeriod": 20
      }
    }
  ]
}'

# create the task definition
aws ecs register-task-definition --cli-input-json "$TASK_DEFINITION"

# run the task against the cluster created above
aws ecs run-task \
  --cluster "openvas-cluster" \
  --task-definition "openvas:<VERSION_NUMBER>"
  --launch-type FARGATE
  --count 1
  --network-configuration "awsvpcConfiguration={subnets=[<SUBNET_ID>],securityGroups=[<SECURITY_GROUP_ID>],assignPublicIp=ENABLED}"
```

Once the task is running you should be able to see the public IP address within the container view of the ECS panel in your AWS Console.
You can then enter "http://<PUBLIC_IP_ADDRESS>" to sign in to OpenVAS using the credentials defined in your build or "admin,password" if you used the
default build image. It is highly recommended if using a public IP address to configure security groups to your IP on port 80 to prevent generic exposure
and also changing the default admin password within the console if using the Cytix OpenVAS docker image.