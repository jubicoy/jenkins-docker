SHELL := /bin/bash

all: container

container:
	docker build -t jubicoy/jenkins .

push:
	docker push jubicoy/jenkins
