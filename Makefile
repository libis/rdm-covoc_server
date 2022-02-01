STAGE ?= dev

include env.$(STAGE)
export

.SILENT:
SHELL = /bin/bash

# Set USER_ID and GROUP_ID to current user's uid and gid if not set
USER_ID ?= $(shell id -u)
GROUP_ID ?= $(shell id -g)

build: update ## Build Docker image
	echo "Building Docker image ..."
	docker build \
		--build-arg RUBY_VERSION=$(RUBY_VERSION) --build-arg USER_ID=$(USER_ID) --build-arg GROUP_ID=$(GROUP_ID) \
		--tag "$(IMAGE_TAG)" ./image

push: ## Push Docker image (only in prod stage)
	if [ "$(STAGE)" = "prod" ]; then \
		echo "Pushing Docker image to repository ..."; \
		docker push $(IMAGE_TAG); \
	else \
		echo "Not in production stage. Pushing not allowed."; \
	fi

CP=rsync --info=name1,name2,del -ptgo

update: ## Update the script files in the image
	echo "Updating files in Docker image ..."
	$(CP) *.sh					image/bin/
	$(CP) Gemfile*			image/
	$(CP)	server/*			image/bin/
	$(CP) authors/*	    image/authors/
	