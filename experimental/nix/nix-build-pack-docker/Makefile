IMAGE_TAG := latest
EXPRESSION := docker.nix
BUILDER_COMMAND := bash nix-builder.sh $(EXPRESSION)
RUN_COMMAND := python hello_world.py
IMAGE_NAME := ""

DOCKER := docker
BUILDER_CONTAINER := nix-builder
DATA_CONTAINER := nix-store
BUILD_OPTIONS := --rm=true

IF_STORE = $(DOCKER) ps -a | grep $(DATA_CONTAINER) &&
IF_BUILDER = $(DOCKER) images | grep $(BUILDER_CONTAINER) &&
IF_IMAGE = $(DOCKER) images | grep $(IMAGE) &&
IF_IMAGE_NAME = IMAGE_NAME > 0 &&

IF_NOT_STORE = $(DOCKER) ps -a | grep $(DATA_CONTAINER) ||
IF_NOT_BUILDER = $(DOCKER) images | grep $(BUILDER_CONTAINER) ||

MAKE_IMAGE := .sentinel.image
MAKE_BUILDER := .sentinel.builder

run: $(MAKE_IMAGE)
	$(IF_IMAGE_NAME) $(DOCKER) run --rm -v $(PWD)/workdir:/home/user $(RUN_COMMAND)

image: $(MAKE_IMAGE)
	@:

$(MAKE_BUILDER): $(EXPRESSION) $(MAKE_BUILDER)
	$(IF_NOT_STORE) $(DOCKER) create --name $(DATA_CONTAINER) $(BUILDER_CONTAINER):$(IMAGE_TAG)
	$(DOCKER) run --rm --volumes-from=$(DATA_CONTAINER) -v $(PWD):/home/user \
		$(BUILDER_CONTAINER):$(IMAGE_TAG) $(COMMAND)
	make image IMAGE_NAME=$(docker load < result | sed -ne 's|^Loaded image:\([a-zA-Z0-9^\s]*\)|\1|p')

builder: $(MAKE_BUILDER)
	@:

$(MAKE_BUILDER): builder/nix-builder.docker builder/nix-builder.sh
	$(IF_NOT_BUILDER) $(DOCKER) build -t $(BUILDER_CONTAINER) -f builder/nix-builder.docker $(BUILD_OPTIONS) .
	@touch $(MAKE_BUILDER)

clean:
	$(IF_IMAGE) $(DOCKER) rmi --force=true $(IMAGE) || true
	@rm -f $(EXPRESSION).tar.gz $(MAKE_IMAGE) $(MAKE_BUILDER)

purge: clean
	$(IF_STORE) $(DOCKER) rm --volumes=true $(DATA_CONTAINER) || true
	$(IF_BUILDER) $(DOCKER) rmi --force=true $(BUILDER_CONTAINER) || true

.PHONY: run image builder clean
