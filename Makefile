
.DEFAULT_GOAL := help
.PHONY: help
help:	## Show this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s \n", $$1, $$2}'


requirements:		## Create requirements.txt from poetry.lock
	poetry update && poetry export --without-hashes > requirements.txt

.PHONY: build
build: 		## Build the docker image
	docker build -t mastobot -f docker/Dockerfile .

.PHONY: run
run: build		## Run the docker image
	CURRENT_UID=$(id -u):$(id -g) docker-compose up



