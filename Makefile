############################################################
## Base Makefile for services.
## create a Makefile in top level of your service, configure
## it and include this makefile.
##
## !!!! git config user.email "email@example.com"
##
## Example:
##
## SERVICE = smurf
##  IMAGES = \
##
## include $(dir $(lastword ${MAKEFILE_LIST}))/tools/Makefile
##
##### SEE Makefile.md for more information ########
############################################################
ifndef IMAGES
    $(warning "NOTE: No images defined in 'IMAGES' variable")
endif # ifndef IMAGES

############################################################
## Setup
############################################################
SHELL = /bin/bash -e -o pipefail

## get information from version file
VERSIONFILE := $(strip $(or $(wildcard ./development.yaml) $(wildcard ../development.yaml)))
ifneq (,${VERSIONFILE})
include .make.env # Environment generated from development.yaml
.make.env: ${VERSIONFILE}
	@sed -n \
	    -e '1,$$s/ *#.*$$//g' \
	    -e '/^[ \t]*[A-Za-z][^ :]*[ :] *./s/^[ \t]*\([A-Za-z][^ :]*\)[ :] *\(..*\)/\1=\2/gp' \
	    ${VERSIONFILE} > $@
endif # ifneq (,${VERSIONFILE})

# where is top directory of service
TOPDIR = $(shell git rev-parse --show-toplevel)

# information about user
USER.email ?= $(strip $(shell git config --get user.email))
USER.username ?= ${LOGNAME}


############################################################
### lpass login to automate lpass ansible staff
############################################################

.PHONY: lpass
ifeq ($(findstring Not,$(shell lpass status)),Not)
    RESULT=FALSE
else
    RESULT=TRUE
endif

export LPASS_DISABLE_PINENTRY=1
lpass:
ifeq ($(RESULT),FALSE)
	lpass login ${USER.email};
endif
lpass_logout:
	lpass logout --force

#=============================================================
#
#                 Managing docker images
#
#=============================================================

BUILDMARKERS = ${IMAGES:%=.%-built-${VERSION}}
PUSHMARKERS = ${IMAGES:%=.%-pushed}
STAGEMARKERS = ${IMAGES:%=.%-staged}
RELEASEMARKERS = ${IMAGES:%=.%-released}
## find out where docker files are
## (we expect dir to be called 'images' and reside in CWD or above)
IMAGEDIR=images
DOCKERDIR := $(firstword $(wildcard ${IMAGEDIR}) $(wildcard ../${IMAGEDIR}))
ifndef DOCKERDIR
    $(error "Can't find docker directory. Please define 'IMAGEDIR'")
endif # ifndef DOCKERDIR

DOCKER.username = tomasz2101


##############################################################
## build
.PHONY: build
build: ${BUILDMARKERS}
	### all is built
${BUILDMARKERS} : .%-built-${VERSION} :
	docker build --tag $* --file ${IMAGEDIR}/$*/Dockerfile ./${IMAGEDIR}/$*;
	@touch $@

##############################################################
## push
.PHONY: push
push: ${PUSHMARKERS}
	### all is pushed

.PHONY: ${IMAGES:%=push-%}
${IMAGES:%=push-%}: push-% : .%-pushed
	### pushed $*

${PUSHMARKERS}: .%-pushed : .%-built-${VERSION}
	docker tag $* ${DOCKER.username}/$*:dev
	docker push ${DOCKER.username}/$*:dev
	@touch $@

##############################################################
## release
ifdef VERSION
.PHONY: release
release: ${RELEASEMARKERS}

${RELEASEMARKERS}: .%-released : .%-built-${VERSION}
	### Released all images as version ${VERSION}
	docker tag $* ${DOCKER.username}/$*:${VERSION}
	docker push ${DOCKER.username}/$*:${VERSION}
	@touch $@
else # ifdef RELEASE
release:
	@echo "You must define 'VERSION' to be able to release"
endif # ifdef RELEASE

clean::
	rm -rf .*-built-*
	rm -rf .*-pushed
	rm -rf .*-released
