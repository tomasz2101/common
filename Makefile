############################################################
## Base Makefile for services.
## create a Makefile in top level of your service, configure
## it and include this makefile.
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
VERSIONFILE := $(strip $(or $(wildcard ./test.yaml) $(wildcard ../test.yaml)))
ifneq (,${VERSIONFILE})
include .make.env # Environment generated from test.yaml
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
## TODO describe
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


.PHONY: build
build: ${BUILDMARKERS}
	### all is built
${BUILDMARKERS} : .%-built-${VERSION} :

	docker build --tag $* --file ${IMAGEDIR}/$*/Dockerfile ./${IMAGEDIR}/$*; \

	# for image in $(IMAGES) ; do \
    #     docker build --tag $$image --file ${IMAGEDIR}/$$image/Dockerfile ./${IMAGEDIR}/$$image; \
    # done
	@touch $@
##############################################################
## push
.PHONY: push
push: ${PUSHMARKERS}
	for image in $(IMAGES) ; do \
		docker tag $$image tomasz2101/$$image:latest; \
        docker push tomasz2101/$$image:latest; \
    done
	@touch $@

ifdef VERSION
.PHONY: release
release: ${RELEASEMARKERS}

${RELEASEMARKERS}: .%-released : .%-built-${VERSION}
	### Released all images as version ${VERSION}

	for image in $(IMAGES) ; do \
		docker tag $$image tomasz2101/$$image:${VERSION}; \
        docker push tomasz2101/$$image:${VERSION}; \
    done
else # ifdef ZRELEASE
release:
	@echo "You must define 'VERSION' to be able to release"
endif # ifdef ZRELEASE

RM = /bin/rm -f
RM-r = /bin/rm -rf
clean:
	- ${RM} .*-built-*
	- ${RM} .*-pushed
	- ${RM} .*-released
