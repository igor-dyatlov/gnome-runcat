# Basic Makefile

.PHONY : _build clean install uninstall
.DEFAULT_GOAL := help

UUID = runcat@kolesnikov.se
BASE_MODULES = src/extension.js src/stylesheet.css src/metadata.json LICENSE
EXTRA_MODULES = src/cpu.js src/iconProvider.js src/panelMenuButton.js src/prefs.js src/settings.js src/timer.js
EXTRA_ICONS = src/icons/cat/my-running-0-symbolic.svg src/icons/cat/my-running-1-symbolic.svg src/icons/cat/my-running-2-symbolic.svg src/icons/cat/my-running-3-symbolic.svg src/icons/cat/my-running-4-symbolic.svg src/icons/cat/my-sleeping-symbolic.svg

ifeq ($(strip $(DESTDIR)),)
	INSTALLTYPE = local
	INSTALLBASE = $(HOME)/.local/share/gnome-shell/extensions
else
	INSTALLTYPE = system
	SHARE_PREFIX = $(DESTDIR)/usr/share
	INSTALLBASE = $(SHARE_PREFIX)/gnome-shell/extensions
endif
INSTALLNAME = runcat@kolesnikov.se

# The command line passed variable VERSION is used to set the version string
# in the metadata and in the generated zip-file. If no VERSION is passed, the
# current commit SHA1 is used as version number in the metadata while the
# generated zip file has no string attached.

all: extension

clean:
	rm -f ./src/schemas/gschemas.compiled

extension: ./schemas/gschemas.compiled

./schemas/gschemas.compiled: ./src/schemas/org.gnome.shell.extensions.runcat.gschema.xml
	glib-compile-schemas ./src/schemas

install: uninstall install-local

install-local: _build
	rm -rf $(INSTALLBASE)/$(INSTALLNAME)
	mkdir -p $(INSTALLBASE)/$(INSTALLNAME)
	cp -r ./_build/* $(INSTALLBASE)/$(INSTALLNAME)/
ifeq ($(INSTALLTYPE),system)
	# system-wide settings and locale files
	rm -rf $(INSTALLBASE)/$(INSTALLNAME)
	mkdir -p $(INSTALLBASE)/$(INSTALLNAME)
	cp -r ./_build/* $(INSTALLBASE)/$(INSTALLNAME)/
endif
	-rm -fR _build

zip-file: _build
	cd _build ; \
	zip -qr "$(UUID).zip" .
	mv _build/$(UUID).zip ./
	-rm -fR _build

_build: all
	-rm -fR ./_build
	mkdir -p _build
	cp $(BASE_MODULES) $(EXTRA_MODULES) _build
	mkdir -p _build/icons/cat
	cp $(EXTRA_ICONS) _build/icons/cat
	mkdir -p _build/schemas
	cp src/schemas/*.xml _build/schemas/
	cp src/schemas/gschemas.compiled _build/schemas/
	sed -i 's/"version": -1/"version": "$(VERSION)"/'  _build/metadata.json;

uninstall:
	gnome-extensions uninstall $(UUID) | true

help:
	@echo -n "Available commands: "
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs