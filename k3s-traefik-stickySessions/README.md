# Show how Sticky sessions can be handled by Ingress 

## App

We use simple python Flask application that returns hostname (pod name) and how many time it has been hit so far 

## Docker file 

Then we build a image out of it 

## k3s

We install k3s 

## Deploy a Application 

We create a deployment file and deploy 5 replica of this application

## Create a Service 

We create a NodePort service , pay attention to annotations

## Create a Ingress 

We deploy ingress that points to above service 

## We test it via Browser or via CURl    