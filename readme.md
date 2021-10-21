# About

This project is a submission into the 2021 Chef Automate for Good Hackathon. [JupyterHub](https://jupyter.org/hub) is a Python application that runs in the cloud or on your own hardware, and makes it possible to serve a pre-configured data science environment to any user in the world. It is customizable and scalable, and is suitable for small and large teams, academic courses, and large-scale infrastructure.

However, JupyterHub traditionally depends on one of two configurations. Either a vertically-scaled single node deployment (ironically named, "the little jupyterhub") or a Kubernetes deployment. For many users, especially in education, both a single node or K8s deployment may be impractical. Consider a lab session with 60+ students on a single node instance, the instance would be deeply underutilized for all but a few hours a week (or unable to meet demand during the lab sessions with many concurrent users). K8s presents a viable alternative using a cluster autoscaler, but I propose a simpler alternative solution.

This repository uses Terraform and Chef to provision a JupyterHub instance with Docker Swarm and EC2 Auto-Scaling Group (ASG) instances and a shared NFS (AWS EFS) file-system. As CPU usage increases, the ASG group scales out, and each additional ASG node joins the Chef Server as a worker via unattended install. The node's runbooks direct it to join the swarm advertised by the main Jupyterhub Server.

There are many ways to customize a Jupyter Hub instance, at the very least, an engineer is able to manage spawner method, spawner container, filesystem permissions, authentication method, oauth providers. The recipes in this repo do not come close to covering all possibilities or combinations of deployment strategy, but instead use the following configuration as a proof of concept/mimic what (in my experience) may be a realistic workflow for social or physical scientists to use.

- Auth/Oauth: [OAuthenticator with GitHub](https://jupyterhub.readthedocs.io/en/stable/getting-started/authenticators-users-basics.html#use-oauthenticator-to-support-oauth-with-popular-service-providers)
- Spawner Strategy: [DockerSwarmSpawner](https://github.com/jupyterhub/dockerspawner)
- Launch Image: `dmw2151/geospatial-utils` - [Here](https://hub.docker.com/r/dmw2151/geo) - Public image I've used for demonstrations before that includes the Python3.8 Standard Lib, some C dependencies for geospatial processing, and some of Python's data science stack

Please see the following links for more detail on the project:

- [YouTube](...)
- [DevPost](https://devpost.com/software/autoscaling-jupyterhub)
- [System Architecture](./docs/docs.pdf)

## Requirements Before Deployment

### Github

To run an automated build, the CI for this deployment requires the following secrets attached to a Github repository.

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- CHEF__WORKSTATION_SSH_KEY
- AWS_ACCOUNT_ID
  
Note that it is possible to deploy from a local machine, but the `local-exec` step in the `terraform` pipeline are largely dependent on your environment. Deploying from an Alpine VM would most closely replicate `hashicorp/terraform-github-actions`

### AWS

The credentialing information passed to the repository requires an IAM role with a fairly high level of privilege. If your org doesn't maintain IAM roles with write level access to AWS services in this deployment (e.g. you use SSO temp credentials) these will need to be rotated out relatively often.

## Miscellaneous Assumptions, Errata, Notes

- Assumes have a domain to use for the notebook server. Ideally you have a FQDN other than the EC2 DNS for the Chef Server as well; for this demo I rely on the public DNS for my Chef Server. The Nginx derivative Open-Resty (used by Chef) is not officially supported by Certbot, so I leave DNS resolution for the Chef Server as an exercise for the developer :).
  
- Excludes hardening + (a lot) of security precautions to take, some of the more restrictive hardening suggestions work against this deployment's Jupyter NB assumptions.

## TODO/Extras

- [ ] Use SQS Queue to de-register ASG nodes from the Chef Sever after they're terminated? or maybe an on-termination hook on the instance itself? or a recipe for the  to purge nodes if check-in > ${THRESHOLD}.

- [ ] Set a user disk space and CPU quota, either by setting a quota on NFS/EFS (sensitive to which authenticator used), or via Hub Config
  
- [ ] The build for Chef Server is slow when Terraform comes Up. It would be nice to use Packer to build the Chef Server into an AMI e.g. `Ubuntu-18.04-Chef-13.1.13`, use that in Terraform, and cut `cloud init` time by 95%. Moreover, it would be nice to build the ASG nodes into `Ubuntu-18.04-Knife-xx.xx.xx` so we bring instances up faster

- [ ] DNS Resolution for the Chef Server
  
