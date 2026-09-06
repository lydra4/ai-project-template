IMAGE ?= temp
PORT  ?= 7860

.PHONY: build run clean setup remove check test

build:
	docker build -f docker/Dockerfile -t $(IMAGE) .

run:
	docker run --rm -p $(PORT):$(PORT) $(IMAGE)

clean:
	docker ps -aq --filter ancestor=$(IMAGE) | xargs -r docker rm -f
	docker rmi -f $(IMAGE) 2>/dev/null || true

setup:
	bash scripts/setup_env.sh

remove:
	bash scripts/remove_env.sh

check:
	pre-commit run --all-files

test:
	pytest -q --cov=src --cov-report=term-missing
