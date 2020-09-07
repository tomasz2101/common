############################################################
## Service Data
IMAGES = \
	nginx \
	proxmox_exporter \
	python3 \
	ansible \
	tools

include $(dir $(lastword ${MAKEFILE_LIST}))/Makefile.common

############################################################
