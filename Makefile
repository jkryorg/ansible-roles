all: lint

lint:
	yamllint .
	find . -mindepth 1 -maxdepth 1 -type d '!' -name '.*' -execdir ansible-lint {} +
