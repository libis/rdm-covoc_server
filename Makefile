STAGE ?= dev

include env.$(STAGE)
-include .env
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

CP=rsync --recursive --info=name1,name2,del -ptgo

update: ## Update the script files in the image
	echo "Updating files in Docker image ..."
	$(CP) Gemfile*      image/
	$(CP) bin/          image/bin/
	$(CP) server/       image/
	$(CP) authors/      image/authors/
	$(CP) lib/		    image/lib/

run: ## Run the server locally
	cd server && bundle exec puma -p 9292 config.ru

covoc_drop:
	./bin/drop_index.sh

covoc_create:
	./bin/create_index.sh

covoc_load:
	./bin/load_index.sh

covoc_recreate: drop_index create_index load_index

covoc_config:
	./bin/config_index.sh
