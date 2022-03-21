IMAGE_NAME ?= docker.kopla.jyu.fi/tools/nix
IMAGE_TAG ?= $(CI_BUILD_REF_NAME)

# Defaults to current git tag, or branch if no tag
CI_BUILD_REF_NAME ?= $(shell git describe --tags --exact-match 2>/dev/null || git name-rev --name-only HEAD)

all: build

build: Dockerfile nix.tar.gz
	docker build --rm -t "$(IMAGE_NAME):$(IMAGE_TAG)" .

dist: build
	docker build --rm -t "$(IMAGE_NAME):$(IMAGE_TAG)" .

push:
	docker push "$(IMAGE_NAME):$(IMAGE_TAG)"

clean:
	rm -f nix.tar.gz

clean-image:
	docker rmi "$(IMAGE_NAME):$(IMAGE_TAG)" || true

###

.PHONY: all build dist push clean clean-image

nix.tar.gz: bootstrap.sh
	cat bootstrap.sh | docker run --rm -i busybox sh > nix.tar.gz
