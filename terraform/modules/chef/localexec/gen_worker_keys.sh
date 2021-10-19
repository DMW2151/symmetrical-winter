#!/bin/sh

# Generate Worker Key
openssl genrsa -out $(pwd)/.ssh/chef_worker 2048

openssl rsa \
    -in $(pwd)/.ssh/chef_worker \
    -outform PEM \
    -pubout \
    -out $(pwd)/.ssh/chef_worker.pub
    

