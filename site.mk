FFDA_SITE_VERSION := $(shell git describe --tags --abbrev=0 | sed 's/-.*//')

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
