# Build a docker image for oiservices wrapping
# Building requires :
#  - bsmem sources
#  - OImaging-uws war
# look at the Dockerfile for main building operations
#
# oiservices can run the service (UWS server) without args
#   or run a binary inside the container

include ../oiservices/common.mk

TAR_FILE=$(NAME)-$(VERSION).tar

# Define the max running jobs on the OImaging server within docker (hard-coded as docker image is not prepared on server VM)
SERVER_MAX_JOBS:=8

SERVER_MEM_LIMIT:=8g
SERVER_PORT:=81




# The OMP_THREAD_LIMIT environment variable sets the maximum number of OpenMP threads to use in a contention group
# https://www.openmp.org/spec-html/5.1/openmpse67.html
OMP_THREAD_LIMIT:=1

# use all threads for make jobs:
NTHREADS := $(shell getconf _NPROCESSORS_ONLN) # find nthreads for make -j

# CONTAINER_REGISTRY
CONTAINER_REGISTRY:=gricad-registry.univ-grenoble-alpes.fr/osug/jmmc/containers/

# $(shell grep -c '^processor' /proc/cpuinfo)


all:	build tag_latest

# call force-build to start again building process from the beginning
force-build:	Dockerfile OImaging-uws.war
	docker build --no-cache=true -t $(NAME):$(VERSION) --rm .

build:	Dockerfile OImaging-uws.war
	echo "Setting SERVER_MAX_JOBS=$(SERVER_MAX_JOBS) in docker env..." ;\
	docker build -t $(NAME):$(VERSION) --build-arg SERVER_MAX_JOBS=$(SERVER_MAX_JOBS) --build-arg OMP_THREAD_LIMIT=$(OMP_THREAD_LIMIT) --build-arg MAKEJ_NTHREADS=$(NTHREADS) --rm .

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

OImaging-uws.war: ../../../target/OImaging-uws.war
	cp $? .

../../../target/OImaging-uws.war:
	cd ../../.. ;\
	mvn clean install ;\
	cd -

run:
	docker rm $(NAME) || true
	docker run -it --name $(NAME) --memory $(SERVER_MEM_LIMIT) --memory-swappiness 0 -p $(SERVER_PORT):8080 $(NAME):$(VERSION)

shell:
	docker exec -it $(NAME) /bin/bash


$(TAR_FILE):
	docker save -o $(TAR_FILE) $(NAME):$(VERSION)

# This image snapshot is used in the ansible jmmc-oimaging-uws role (look into vars so that the versions match)
publish: $(TAR_FILE)
	scp $(TAR_FILE) apps-old.jmmc.fr.to:/data/docker/

push:
	@echo "Please login first using next command if your push fails ():"
	@echo " docker login $(CONTAINER_REGISTRY)"
	docker tag $(NAME):$(VERSION) $(CONTAINER_REGISTRY)$(NAME):$(VERSION)
	docker push $(CONTAINER_REGISTRY)$(NAME):$(VERSION)
	@echo "Please logout after your pushes:"
	@echo " docker logout $(CONTAINER_REGISTRY)"

push_latest:
	docker tag $(NAME):$(VERSION) $(CONTAINER_REGISTRY)$(NAME):latest
	docker push $(CONTAINER_REGISTRY)$(NAME):latest


exec-bsmem-ci-help:
	docker run -it $(NAME):$(VERSION) bsmem-ci -h

exec-wisard-ci-help:
	docker run -it $(NAME):$(VERSION) wisard-ci -h


clean:
	rm -f ../../../target/OImaging-uws.war ;\
	rm -rf OImaging-uws.war $(TAR_FILE)

