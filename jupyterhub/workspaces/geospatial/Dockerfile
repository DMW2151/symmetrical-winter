FROM python:3.8-slim

# Install System utils, including all the gcc and geos packages; 
# Required for GDAL + Geospatial Python Libs; bit heavier on ubuntu
# than other distros...
RUN apt-get update &&\
    apt-get install -y \
        wget \ 
        unzip \
        build-essential \
        proj-bin \
        libproj-dev \
        proj-data \
        proj-bin \
        gdal-bin \
        libgdal-dev \
        libgeos-dev &&\
    apt-get clean

# Install GDAL - Required for Shapley; 
# NOTE: 
#   - The Shapely GEOS version (3.8.0-CAPI-1.13.1 ) is "incompatible" with the 
#    GEOS version PyGEOS was compiled with (3.9.0-CAPI-1.16.2).
RUN wget https://github.com/OSGeo/gdal/releases/download/v3.2.1/gdal-3.2.1.tar.gz &&\ 
    gunzip gdal-3.2.1.tar.gz 

# Install GEOS - Required for ...
RUN wget http://download.osgeo.org/geos/geos-3.9.1.tar.bz2 &&\
    bzip2 -d geos-3.9.1.tar.bz2

# Python Installs, Split by general category of import:
#   - Install Geospatial Support Libraries + JupyterHub minimal reqs, 
#       many redundant installs, depend on pip to resolve these; split them 
#
#   - No cache for Img Size Control: 
#       - https://pip.pypa.io/en/stable/reference/pip_install/#caching
#
#   - Following example of minimal container from JupyterHub docs.
#       - https://jupyterhub-dockerspawner.readthedocs.io/en/latest/docker-image.html
#
#   - See Note on Shapely building from binary
#       - https://pypi.org/project/Shapely/

RUN pip install --upgrade pip 

RUN pip install \
    --no-cache-dir \
        Cython \ 
        pandas \
        numpy \
        scipy \
        sklearn
        
RUN pip install \
    --no-cache-dir \
        matplotlib \  
        seaborn

RUN pip install \
    --no-cache-dir \
        geopandas \
        mapbox \
        descartes \
        contextily \
        pygeos \
        geoplot \
        shapely \ 
        mapclassify \
        --no-binary shapely

RUN pip install \
    --no-cache-dir \
        jupyterhub==1.0.0 \
        notebook>=5.0 \
        psycopg2-binary
    
# Create a user to avoid running container as root, use `jovyan`
# as convention from the JupyterHub Docs
RUN useradd -m jovyan

ENV HOME=/home/jovyan

WORKDIR $HOME

USER jovyan

# Start SingleUser JupyterHub NB Cluster on Container Init...
CMD ["jupyterhub-singleuser"]
