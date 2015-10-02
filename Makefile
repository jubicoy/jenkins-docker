SHELL := /bin/bash

all: container

container:
	docker build -t jubicoy/docker .

push:
	docker push jubicoy/docker
