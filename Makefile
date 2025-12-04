REDIS_URL ?= redis://localhost:6379/0

.PHONY: test lint-fix console install

install:
	bundle install

console:
	bin/console

test:
	REDIS_URL=$(REDIS_URL) bundle exec rspec $(filter-out $@,$(MAKECMDGOALS))

lint-fix:
	bundle exec standardrb --fix

%:
	@:
