## See Sample Config Here: https://jupyterhub.readthedocs.io/en/stable/reference/config-reference.html

import os
import logging

# Internal - Memory Management...
c.JupyterHub.log_level = logging.DEBUG
c.SwarmSpawner.remove_containers = True
c.SwarmSpawner.debug = True

## Authentication ##
c.JupyterHub.authenticator_class = "jupyterhub.auth.DummyAuthenticator"

c.ConfigurableHTTPProxy.should_start = True

c.JupyterHub.spawner_class = "dockerspawner.SwarmSpawner"

c.SwarmSpawner.network_name = "hub"


## Hub Listening Addresses ##

# The "public" facing port of the hub proxy
c.JupyterHub.hub_port = os.environ.get("HUB__PROXY_PORT") or 8081
c.JupyterHub.hub_ip = "0.0.0.0"

# The "public" facing port of the hub service
c.JupyterHub.port = os.environ.get("HUB__SVC_PORT") or 8000
c.SwarmSpawner.host_ip = "0.0.0.0"

## Data Persistance + Launch Image ##
notebook_dir = f"/home/jovyan/{os.environ.get('HUB__NOTEBOOK_DIR')}"
c.SwarmSpawner.notebook_dir = notebook_dir

# Volume Persistance #
c.DockerSpawner.volumes = {"/efs/hub": notebook_dir}

# Launch Container, prefer a private version...
public_container = os.environ.get("HUB__PUBLIC_ANALYSIS_CONTAINER")
private_container = f"{os.environ.get('AWS__ACCOUNT_ID')}.dkr.{os.environ.get('AWS__REGION')}.amazonaws.com/{os.environ.get('HUB__ANALYSIS_CONTAINER')}"

c.DockerSpawner.container_image = private_container or public_container
c.SwarmSpawner.container_spec = {"Image": private_container or public_container}

## Resource Limits ##
c.Spawner.mem_limit = os.environ.get("HUB__SPAWNER_MEM_LIMIT") or "1G"
c.Spawner.cpu_limit = os.environ.get("HUB__SPAWNER_CPU_LIMIT") or 0.30
