.PHONY: lpass_login
ifeq ($(findstring Not,$(shell lpass status)),Not)
    RESULT=FALSE
else
    RESULT=TRUE
endif

lpass_login:
ifeq ($(RESULT),FALSE)
ifeq ($(strip $(user)),)
	read -p "Enter user:" user; \
	lpass login $$user;
else
	lpass login $$user;
endif
endif
docker_build:
	for image in $(IMAGES) ; do \
        docker build --tag $$image --file docker/$$image/Dockerfile ./docker/$$image; \
    done
docker_publish: build
	for image in $(IMAGES) ; do \
		docker tag $$image tomasz2101/$$image:latest; \
        docker push tomasz2101/$$image:latest; \
    done