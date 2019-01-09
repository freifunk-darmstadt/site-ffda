DEFAULT_GLUON_RELEASE := 1.3~$(shell date '+%Y%m%d')
DEFAULT_GLUON_PRIORITY := 0

# enable multidomain support
GLUON_MULTIDOMAIN=1

# languages to include in images
GLUON_LANGS ?= en de

# region information for regulatory compliance
GLUON_REGION ?= eu

# Allow overriding the release number from the command line
GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)
GLUON_PRIORITY ?= ${DEFAULT_GLUON_PRIORITY}

# Prefer ath10k firmware with 802.11s support
GLUON_WLAN_MESH ?= 11s

# Featureset, these are either virtual or packages prefixed with "gluon-"
GLUON_FEATURES := \
	autoupdater \
	config-mode-domain-select \
	config-mode-geo-location-osm \
	config-mode-outdoor \
	ebtables-filter-multicast \
	ebtables-filter-ra-dhcp \
	ebtables-limit-arp \
	ebtables-source-filter \
	mesh-batman-adv-15 \
	mesh-vpn-fastd \
	radvd \
	radv-filterd \
	respondd \
	status-page \
	web-advanced \
	web-ffda-domain-director \
	web-logging \
	web-private-wifi \
	web-wizard

# Additional packages to install on every image
GLUON_SITE_PACKAGES := \
	ffda-domain-director \
	ffda-migrate-update-branch \
	ffda-update-stabilizer \
	iwinfo \
	haveged \
	respondd-module-airtime


include $(GLUON_SITEDIR)/pkgs.mk
