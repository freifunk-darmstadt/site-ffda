DEFAULT_GLUON_RELEASE := 0.10.0~$(shell date '+%Y%m%d')
DEFAULT_GLUON_PRIORITY := 0

# languages to include in images
GLUON_LANGS ?= en de

# region information for regulatory compliance
GLUON_REGION ?= eu

# Allow overriding the release number from the command line
GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)
GLUON_PRIORITY ?= ${DEFAULT_GLUON_PRIORITY}

# Prefer ath10k firmware with 802.11s support
GLUON_ATH10K_MESH ?= 11s

GLUON_SITE_PACKAGES := \
	gluon-mesh-batman-adv-15 \
	gluon-respondd \
	respondd-module-airtime \
	gluon-autoupdater \
	gluon-config-mode-autoupdater \
	gluon-config-mode-contact-info \
	gluon-config-mode-core \
	gluon-config-mode-geo-location \
	gluon-config-mode-hostname \
	gluon-config-mode-mesh-vpn \
	gluon-ebtables-filter-multicast \
	gluon-ebtables-filter-ra-dhcp \
	gluon-ebtables-segment-mld \
	gluon-luci-admin \
	gluon-luci-autoupdater \
	gluon-luci-mesh-vpn-fastd \
	gluon-luci-portconfig \
	gluon-luci-private-wifi \
	gluon-luci-wifi-config \
	gluon-mesh-vpn-fastd \
	gluon-radvd \
	gluon-setup-mode \
	gluon-status-page \
	iwinfo \
	iptables \
	haveged \
	ffho-ebtables-net-rules

# basic support for USB stack
USB_PACKAGES_BASIC := \
	kmod-usb-core \
	kmod-usb-ohci \
	kmod-usb2 \
	kmod-usb3 \
	usbutils

# support for USB input devices
USB_PACKAGES_HID := \
	kmod-usb-hid \
	kmod-hid-generic

# storage support for USB devices
USB_PACKAGES_STORAGE := \
	block-mount \
	blkid \
	kmod-fs-ext4 \
	kmod-fs-vfat \
	kmod-usb-storage \
	kmod-usb-storage-extras \
	kmod-nls-cp1250 \
	kmod-nls-cp1251 \
	kmod-nls-cp437 \
	kmod-nls-cp775 \
	kmod-nls-cp850 \
	kmod-nls-cp852 \
	kmod-nls-cp866 \
	kmod-nls-iso8859-1 \
	kmod-nls-iso8859-13 \
	kmod-nls-iso8859-15 \
	kmod-nls-iso8859-2 \
	kmod-nls-koi8r \
	kmod-nls-utf8 \
	swap-utils

# network support for USB devices
USB_PACKAGES_NET := \
	kmod-ath9k-htc  \
	kmod-ath9k-common \
	kmod-ath \
	kmod-brcmfmac \
	kmod-carl9170 \
	kmod-mii \
	kmod-nls-base \
	kmod-rt73-usb \
	kmod-rtl8192cu \
	kmod-rtl8187 \
	kmod-usb-net \
	kmod-usb-net-asix \
	kmod-usb-net-asix-ax88179 \
	kmod-usb-net-cdc-eem \
	kmod-usb-net-cdc-ether \
	kmod-usb-net-cdc-mbim \
	kmod-usb-net-cdc-ncm \
	kmod-usb-net-cdc-subset \
	kmod-usb-net-dm9601-ether \
	kmod-usb-net-hso \
	kmod-usb-net-huawei-cdc-ncm \
	kmod-usb-net-ipheth \
	kmod-usb-net-kalmia \
	kmod-usb-net-kaweth \
	kmod-usb-net-mcs7830 \
	kmod-usb-net-pegasus \
	kmod-usb-net-qmi-wwan \
	kmod-usb-net-rndis \
	kmod-usb-net-rtl8152 \
	kmod-usb-net-sierrawireless \
	kmod-usb-net-smsc95xx

# bnx2: BCM5706/5708/5709/5716 (Broadcom NetExtreme)
# others may already be default packages on x86 targets
# - https://github.com/freifunk-gluon/gluon/blob/master/targets/x86-64
# - https://github.com/freifunk-gluon/gluon/blob/master/targets/x86-generic
# - https://github.com/freifunk-gluon/gluon/blob/master/targets/x86-geode
PCI_PACKAGES_NET := \
	kmod-bnx2

ifeq ($(GLUON_TARGET),x86-generic)
GLUON_SITE_PACKAGES += \
	$(USB_PACKAGES_BASIC) \
	$(USB_PACKAGES_HID) \
	$(USB_PACKAGES_STORAGE) \
	$(USB_PACKAGES_NET) \
	$(PCI_PACKAGES_NET)
endif

ifeq ($(GLUON_TARGET),x86-64)
GLUON_SITE_PACKAGES += \
	$(USB_PACKAGES_BASIC) \
	$(USB_PACKAGES_HID) \
	$(USB_PACKAGES_STORAGE) \
	$(USB_PACKAGES_NET) \
	$(PCI_PACKAGES_NET)
endif

#  Raspberry Pi A/B/B+
ifeq ($(GLUON_TARGET),brcm2708-bcm2708)
GLUON_SITE_PACKAGES += \
	$(USB_PACKAGES_BASIC) \
	$(USB_PACKAGES_HID) \
	$(USB_PACKAGES_STORAGE) \
	$(USB_PACKAGES_NET)
endif

# Raspberry Pi 2
ifeq ($(GLUON_TARGET),brcm2708-bcm2709)
GLUON_SITE_PACKAGES += \
	$(USB_PACKAGES_BASIC) \
	$(USB_PACKAGES_HID) \
	$(USB_PACKAGES_STORAGE) \
	$(USB_PACKAGES_NET)
endif

# Embedded Routers
ifeq ($(GLUON_TARGET),ar71xx-generic)
GLUON_SITE_PACKAGES += \
	$(USB_PACKAGES_BASIC) \
	$(USB_PACKAGES_HID) \
	$(USB_PACKAGES_STORAGE) \
	$(USB_PACKAGES_NET)
endif

ifeq ($(GLUON_TARGET),ar71xx-nand)
GLUON_SITE_PACKAGES += \
	$(USB_PACKAGES_BASIC) \
	$(USB_PACKAGES_HID) \
	$(USB_PACKAGES_STORAGE) \
	$(USB_PACKAGES_NET)
endif

ifeq ($(GLUON_TARGET),mpc85xx-generic)
GLUON_SITE_PACKAGES += \
	$(USB_PACKAGES_BASIC) \
	$(USB_PACKAGES_HID) \
	$(USB_PACKAGES_STORAGE) \
	$(USB_PACKAGES_NET)
endif

