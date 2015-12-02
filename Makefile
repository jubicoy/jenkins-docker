SHELL := /bin/bash

all: container

container:
	docker build -t jubicoy/jenkins-debian .

push:
	docker push jubicoy/jenkins-debian
