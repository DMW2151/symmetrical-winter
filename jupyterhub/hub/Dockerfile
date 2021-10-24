# https://github.com/jupyterhub/dockerspawner/tree/main/examples/oauth
FROM jupyterhub/jupyterhub:1.4.2

RUN pip install --upgrade pip 

RUN pip install --no-cache-dir \
    dockerspawner \
    jupyterhub-dummyauthenticator \
    jupyter