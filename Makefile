# Makefile for framework

.POSIX:

all: build

build:
	./build.sh

clean:
	rm -rf dist

serve: build
	@echo "Starting local server on http://localhost:8000"
	@cd dist && python3 -m http.server 8000

deploy: build
	@echo "Deploy target not configured."
	@echo "Edit this Makefile to add your deployment command."
	@echo "Example: rsync -av --delete dist/ user@server:/var/www/"

watch:
	@echo "Watching for changes..."
	@while true; do \
		inotifywait -r -e modify,create,delete src templates sw.conf 2>/dev/null || \
		sleep 2; \
		make build; \
	done

.PHONY: all build clean serve deploy watch
