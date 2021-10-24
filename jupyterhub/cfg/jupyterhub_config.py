import os
import logging

# Internal - Memory Management...
c.JupyterHub.log_level = logging.DEBUG
c.SwarmSpawner.remove_containers = True
c.SwarmSpawner.debug = True

## Authentication ##
c.JupyterHub.authenticator_class = 'jupyterhub.auth.DummyAuthenticator'

c.ConfigurableHTTPProxy.should_start = True

c.JupyterHub.spawner_class = 'dockerspawner.SwarmSpawner'

c.SwarmSpawner.network_name = "hub"

c.SwarmSpawner.extra_host_config = {
    'network_mode': "swarm_jupyterhub_net"
}


## Hub Listening Addresses ##

# The "public" facing port of the hub proxy
c.JupyterHub.hub_port = os.environ.get('HUB__PROXY_PORT') or 8081
c.JupyterHub.hub_ip = '0.0.0.0'

# The "public" facing port of the hub service
c.JupyterHub.port = os.environ.get('HUB__SVC_PORT') or  8000
c.SwarmSpawner.host_ip = "0.0.0.0"

## Data Persistance + Launch Image ##
notebook_dir = os.environ.get('NOTEBOOK_DIR') or '/home/jovyan/'
c.SwarmSpawner.notebook_dir = notebook_dir

# Volume Persistance #
c.DockerSpawner.volumes = { 
  '/efs/hub' : notebook_dir
}

c.DockerSpawner.container_image = os.environ.get('HUB__ANALYSIS_CONTAINER') or 'dmw2151/geo:latest'

c.SwarmSpawner.container_spec = {
    'Image': os.environ.get('HUB__ANALYSIS_CONTAINER') or 'dmw2151/geo:latest',
}

## Resource Limits ##
c.Spawner.mem_limit = '2G'
c.Spawner.cpu_limit = 0.30 

