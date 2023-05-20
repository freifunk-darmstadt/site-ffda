FFDA_SITE_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
#FFDA_SITE_VERSION_GIT := $(shell git -C $(FFDA_SITE_DIR) describe --tags --abbrev=0 | sed 's/-.*//')

FFDA_SITE_VERSION_FALLBACK := 3.3u
FFDA_SITE_VERSION := $(if $(FFDA_SITE_VERSION_GIT),$(FFDA_SITE_VERSION_GIT),$(FFDA_SITE_VERSION_FALLBACK))

DEFAULT_GLUON_RELEASE := $(FFDA_SITE_VERSION)~$(shell date '+%Y%m%d')
DEFAULT_GLUON_PRIORITY := 0

# Enable multidomain support
GLUON_MULTIDOMAIN := 1

# Languages to include in images
GLUON_LANGS ?= en de

# Region information for regulatory compliance
GLUON_REGION ?= eu

# Allow overriding the release number from the command line
GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)
GLUON_PRIORITY ?= ${DEFAULT_GLUON_PRIORITY}

# Don't build factory firmware for deprecated devices
GLUON_DEPRECATED ?= upgrade
