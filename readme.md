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
- [System Architecture](https://tiles.maphub.dev/docs/pages/asg_arch.pdf)


## Requires In Github

The CI for this deployment requires the following secrets attached to your repo

- AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY/CHEF__WORKSTATION_SSH_KEY


- Not Highly Available - Push sinks you!



## Assumptions, Errata, Notes

- Assumes you have a domain to use for the notebook server.

- Assumes `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`...
  
- Ideally you have a FQDN beyond the EC2 DNS as well, but for this example I rely on the public DNS for my Chef Server. SSL Nginx derivative openresty (used by Chef) is not officially supported by certbot, so I leave DNS resolution for the Chef Server as an exercise for the developer.
  
- Excludes hardening + (a lot) of security precautions to take, some of the more restrictive hardening suggestions work against this deployment's Jupyter NB assumptions.

## TODO

- [ ] Use SQS Queue to de-register ASG nodes from the sever after they're terminated

- [ ] Set a user disk quota at the at hub level or by setting a quota on NFS/EFS

- [ ] The build for Chef Server is slow (8-10min). It would be nice to use Packer to build the Chef Server into an AMI e.g. `Ubuntu-18.04-Chef-13.1.13`, use that in Terraform, and cut `cloud init` time by 95%
  
- [ ] Moreso, it would be nice to build the ASG nodes into `Ubuntu-18.04-Knife-xx.xx.xx` so we bring instances up faster

- [ ] DNS Resolution for the Chef Server
