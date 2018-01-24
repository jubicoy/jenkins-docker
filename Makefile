SHELL := /bin/bash

all: container

container:
	docker build --no-cache -t jubicoy/jenkins-debian .

push:
	docker push jubicoy/jenkins-debian
