############################################################
## Base Makefile for services.
## create a Makefile in top level of your service, configure
## it and include this makefile.
##
## !!!! git config user.email "email@example.com"
## !!!! git config user.name "user"
##
## Example:
##
##  IMAGES = \w
##
## include $(dir $(lastword ${MAKEFILE_LIST}))/tools/Makefile
##
## to create secrets read secrets task
##### SEE Makefile.md for more information ########
############################################################
ifndef IMAGES
    $(warning "NOTE: No images defined in 'IMAGES' variable")
endif # ifndef IMAGES

############################################################
## Setup
############################################################
SHELL = /bin/bash -e -o pipefail
TEMP_DIR = .temp_dir
## get information from version file
VERSIONFILE := $(strip $(or $(wildcard ./services.yml) $(wildcard ../services.yml)))

ifneq (,${VERSIONFILE})
include ${TEMP_DIR}/make.env # Environment generated from services.yml
${TEMP_DIR}/make.env: ${VERSIONFILE}
	@mkdir -p .temp_dir
	@sed -n \
	    -e '1,$$s/ *#.*$$//g' \
	    -e '/^[ \t]*[A-Za-z][^ :]*[ :] *./s/^[ \t]*\([A-Za-z][^ :]*\)[ :] *\(..*\)/\1=\2/gp' \
	    ${VERSIONFILE} > $@
else
$(warning "NOTE: Create services.yml file")
endif # ifneq (,${VERSIONFILE})
.PHONY: init_repo
repo/init:
	@read -p "Enter name:" user; \
	git config user.name $$user;
	@read -p "Enter mail:" mail; \
	git config user.email $$mail;
# where is top directory of service
TOPDIR = $(shell git rev-parse --show-toplevel)

# information about user
USER.email ?= $(strip $(shell git config --get user.email))
USER.username ?= $(strip $(shell git config --get user.name))

user/name/check:
ifeq (,${USER.username})
	$(error "NOTE: Please define username, run: make init_repo")
endif # ifndef IMAGES

user/mail/check:
ifeq (,${USER.email})
	$(error "NOTE: Please define user mail, run: make init_repo")
endif # ifndef IMAGES

############################################################
### lpass login to automate lpass ansible staff
############################################################

.PHONY: lpass
ifeq ($(findstring Not,$(shell lpass status)),Not)
    RESULT=FALSE
else
    RESULT=TRUE
endif
# To disable lpass login pin entry / faster way of providing password
export LPASS_DISABLE_PINENTRY=1
lpass: user/mail/check
ifeq ($(RESULT),FALSE)
	lpass login ${USER.email};
endif
lpass/logout:
	lpass logout --force

docker/login: user/name/check
	docker login -u ${USER.username}

############################################################
### create secrets
############################################################

# secrets: lpass
# 	python3 tools/prepare_secrets.py --loglevel info --input_file ${DEPLOYMENT.secrets.template} --output_file ${DEPLOYMENT.secrets.output}

# To create secrets please specify DEPLOYMENT.secrets = test.tmpl=test.secret test1.tmpl=test1.secret

.PHONY: secrets
secrets: lpass ${DEPLOYMENT.secrets}
divide = $(word $2,$(subst =, ,$1))
${DEPLOYMENT.secrets}: % :
	python3 tools/prepare_secrets.py --loglevel info --input_file $(call divide,$*,1) --output_file $(call divide,$*,2)


############################################################
### kubernetes helpers
############################################################
k8s/ports:
	/bin/sh -c 'kubectl port-forward ${K8S.service.name} ${K8S.service.port}:${K8S.service.port}'
k8s/namespace:
	kubectl config set-context --current --namespace=${K8S.namespace}
k8s/namespace/init:
	kubectl create namespace ${K8S.namespace}

#=============================================================
#
#                 Managing docker images
#
#=============================================================

BUILDMARKERS = ${IMAGES:%=${TEMP_DIR}/%-built-${VERSION}}
PUSHMARKERS = ${IMAGES:%=${TEMP_DIR}/%-pushed-${VERSION}}
STAGEMARKERS = ${IMAGES:%=${TEMP_DIR}/%-staged-${VERSION}}
RELEASEMARKERS = ${IMAGES:%=${TEMP_DIR}/%-released-${VERSION}}
## find out where docker files are
## (we expect dir to be called 'images' and reside in CWD or above)
IMAGEDIR=images
DOCKERDIR := $(firstword $(wildcard ${IMAGEDIR}) $(wildcard ../${IMAGEDIR}))
ifndef DOCKERDIR
    $(error "Can't find docker directory. Please define 'IMAGEDIR'")
endif # ifndef DOCKERDIR



##############################################################
## build
.PHONY: build
build: ${BUILDMARKERS}

	### all is built
${BUILDMARKERS} : ${TEMP_DIR}/%-built-${VERSION} :
	@mkdir -p .temp_dir
	docker build --tag $* --file ${IMAGEDIR}/$*/Dockerfile ./${IMAGEDIR}/$*;
	@touch $@

##############################################################
## push
.PHONY: push
push: user/name/check ${PUSHMARKERS}
	### all is pushed

.PHONY: ${IMAGES:%=push-%}
${IMAGES:%=push-%}: push-% : .%-pushed
	### pushed $*

${PUSHMARKERS}: ${TEMP_DIR}/%-pushed-${VERSION} : ${TEMP_DIR}/%-built-${VERSION}
	docker tag $* ${USER.username}/$*:dev
	docker push ${USER.username}/$*:dev
	@touch $@

##############################################################
## release
ifdef VERSION
.PHONY: release
release: user/name/check ${RELEASEMARKERS}

${RELEASEMARKERS}: ${TEMP_DIR}/%-released-${VERSION} : ${TEMP_DIR}/%-built-${VERSION}
	### Released all images as version ${VERSION}
	docker tag $* ${USER.username}/$*:${VERSION}
	docker push ${USER.username}/$*:${VERSION}
	@touch $@
else # ifdef RELEASE
release:
	@echo "You must define 'VERSION' to be able to release"
endif # ifdef RELEASE
##############################################################
## help tasks

clean::
	rm -rf ${TEMP_DIR}
	$(foreach var,${DEPLOYMENT.secrets}, \
		rm -rf  $(call divide,$(var),2);)
