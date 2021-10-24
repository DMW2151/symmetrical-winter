[![Core Infrastructure Up](https://github.com/DMW2151/symmetrical-winter/actions/workflows/infra-up.yaml/badge.svg)](https://github.com/DMW2151/symmetrical-winter/actions/workflows/infra-up.yaml)

# About

**[NOTE]: Branch `chef_a4g` has been made the default branch and will not undergo any further development during the judging period; other branches may show activity thru November 15th**

This project is a submission into the 2021 Chef Automate for Good Hackathon. [JupyterHub](https://jupyter.org/hub) is a Python application that runs in the cloud or on your own hardware, and makes it possible to serve a pre-configured data science environment to any user in the world. It is customizable and scalable, and is suitable for small and large teams, academic courses, and large-scale infrastructure.

However, JupyterHub traditionally depends on one of two configurations. Either a vertically-scaled single node deployment (ironically named, "the littlest JupyterHub") or a Kubernetes deployment. For many users, especially in education, both a single node or K8s deployment can quickly become impractical. Consider a lab session with 100+ students on a large single node instance, the instance would be deeply underutilized for all but a few hours a week. If the machine was under-provisioned, it may be unable to meet demand during the lab sessions with many concurrent users. K8s presents a viable alternative via autoscaling, but I propose an alternative solution.

This repository uses Terraform, Packer, GHActions, Chef, and Docker Swarm to provision and deploy a JupyterHub instance backed by anEC2 Auto-Scaling Group (ASG) instances with a shared NFS (AWS EFS) file-system. As CPU usage increases, the ASG group scales out, and the new ASG instances join the Chef Server as a worker via an unattended install of `chef-client`. From there, each node's run_list recipes configures it to join the Docker Swarm advertised by the main Jupyterhub Server.

Because there is no lock in from dedicated instances, the auto-scaling property of the system will save educators and researches budget for mission critical experiments rather than the exploratory analysis one might typically do in a notebook. Furthermore, because we expect ASG nodes to scale in and out with traffic, it's also reasonable to purchase these instances from the AWS spot market, where one can define a fleet of mixed node types and save upwards of 50% relative to permanent instances (of course, this is a risky choice, but for simple exploratory analysis, worth the occasional restart)

There are many ways to customize a Jupyter Hub instance, at the very least, an engineer is able to manage spawner method, spawner container, filesystem permissions, authentication method, and oauth providers. The recipes in this repo do not come close to covering all possibilities or combinations of deployment strategy, but instead use the following configuration as a proof of concept.

- Auth/Oauth: DummmyAuthentication for testing; but [OAuthenticator with GitHub](https://jupyterhub.readthedocs.io/en/stable/getting-started/authenticators-users-basics.html#use-oauthenticator-to-support-oauth-with-popular-service-providers) very simple to implement.
  
- Spawner Strategy: [DockerSwarmSpawner](https://github.com/jupyterhub/dockerspawner) to launch Docker Containers across a network o
  
- Launch Image: `dmw2151/geospatial-utils` - [Here](https://hub.docker.com/r/dmw2151/geo) - Public image I've used for demonstrations before that includes the Python3.8 Standard Lib, some C dependencies for geospatial processing, and some of Python's data science stack. For this deployment, I'm treating this as an internal image that is built within the repo, deployed to ECR, and then pulled by our swarm worker containers.

Please see the following links for more detail on the project:

- [YouTube](https://youtu.be/OfqXgwJsspw)
- [DevPost](https://devpost.com/software/autoscaling-jupyterhub)
- [System Architecture](./docs/high-level-application-arch.pdf)
## Requirements Before Deployment

### Github Assumptions

This repo has a CI job attached to it which deploys the infrastructure for the Chef Infra Server and Workstation, uploads recipes, and pushes them to the appropriate nodes. From there, Chef handles the management of the instances' NFS volumes, logging agent(s), files, docker containers, etc. To run an automated build, the CI for this deployment requires the following secrets attached to a Github repository.

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- CHEF__WORKSTATION_SSH_KEY
- AWS_ACCOUNT_ID
- CHEF_SSH_VPC_CIDR -> The whitelisted CIDR range for Hub users

Note that it is possible (but highly discouraged) to deploy from a local machine, the `local-exec` steps in the `terraform` pipeline are largely dependent on your environment. Deploying locally from an Ubuntu:20.04 VM would most closely replicate `hashicorp/terraform-github-actions`.

The credentialing information passed to the repository requires an IAM role with a fairly high level of privilege. If your org doesn't maintain IAM roles with write level access to AWS services in this deployment (e.g. you use SSO temp credentials)these will need to be rotated out relatively often.

As an additional benefit, because the CI is written to be idempotent, builds can be scheduled s.t. the instance and ASG nodes are always running on the most recent platform versions.

### AWS Assumptions

I tried to develop everything from scratch, but a few "shortcuts" were taken, at writing, this repo assumes a user has the following already deployed in their account

- A public AWS ROUTE53 ZONE corresponding for the domain to deploy the notebook server onto. Ideally you have a FQDN other than the EC2 DNS for the Chef Server as well; for this demo I rely on the public DNS for my Chef Server. The Nginx derivative Open-Resty (used by Chef) is not officially supported by Certbot, so I leave DNS resolution for the Chef Server as an exercise for the developer :).
  
- A AWS S3 BUCKET named `${user}-chef`, this bucket is used as a Terraform backend and for sharing some configuration files throughout the system setup.
  
- An SSH key named `public-jump-1` on your account (regrettably, it is a common key for all instances in this demo); this is clearly something to tighten-down for a proper deployment.

- Excludes hardening + (a lot) of security precautions to take, some of the more restrictive hardening suggestions work against this deployment's Jupyter NB assumptions, I would need to do a significant amount of additional development to harden the ASG nodes appropriately.

## TODO/Extras 

- :white_check_mark: The build for Chef Server is slow when Terraform comes up. It would be nice to use Packer to build the Chef Server into an AMI e.g. `Ubuntu-18.04-Chef-13.1.13`, use that in Terraform, and cut `cloud init` time by 90%. Moreover, it would be nice to build the ASG nodes into `Ubuntu-18.04-Knife-xx.xx.xx` so we bring instances up faster.

- :white_check_mark: Docker pull can be slow for large images, mostly for data science, consider pulling the working container as part of recipe

- :white_check_mark: Set a user disk space and CPU quota. CPU and Memory are handled in the Hub Config, but will need to set a limit on NFS/EFS. Depends on authentication mode and starting directories! [NOTE: Achieved w. `DummyAuthentication`, Need to Check on Others]

- :x: Built-In TLS for the Chef Server, using Certbot w. OpenResty.

- :x: Method by which to de-register ASG nodes from the Chef Sever after they're terminated. Either an on-termination hook on the instance itself, a recipe for this, or some rule that purges ASG nodes if last check-in is older than ${THRESHOLD}.

- :x: All instance IPs should be fetched via CloudMap x Route53, all other params should be fetched via SSM. As a general rule, things that can be discovered should use service discovery!

## What you Get

- An Infra Server Running at `https://${ec2_instance_public_dns}.amazonaws.com`
- A JupyterHub with a login panel at `https://notebooks.${domain}`
