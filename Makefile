#!/usr/bin/env make -f

VERSION := 0.1.0

tempdir        := $(shell mktemp -d -t log-shuttle.XXXXXXXX)
controldir     := $(tempdir)/DEBIAN
installpath    := $(tempdir)/usr/local/bin
buildpath      := .build
buildpackpath  := $(buildpath)/pack
buildpackcache := $(buildpath)/cache

define DEB_CONTROL
Package: log-shuttle
Version: $(VERSION)
Architecture: amd64
Maintainer: "Ryan R. Smith" <ryan@heroku.com>
Section: heroku
Priority: optional
Description: Move logs from the Dyno to the Logplex.
endef
export DEB_CONTROL

.PHONY: deb clean

deb: build
	mkdir -p -m 0755 $(controldir)
	echo "$$DEB_CONTROL" > $(controldir)/control
	mkdir -p $(installpath)
	install bin/log-shuttle $(installpath)/log-shuttle
	fakeroot dpkg-deb --build $(tempdir) .
	rm -rf $(tempdir)

$(buildpackcache):
	mkdir -p $(buildpath)
	mkdir -p $(buildpackcache)
	wget -P $(buildpath) http://codon-buildpacks.s3.amazonaws.com/buildpacks/fabiokung/go-git-only.tgz

$(buildpackpath)/bin: $(buildpackcache)
	mkdir -p $(buildpackpath)
	tar -C $(buildpackpath) -zxf $(buildpath)/go-git-only.tgz

build: $(buildpackpath)/bin
	$(buildpackpath)/bin/compile . $(buildpackcache)

clean:
	rm -rf $(buildpath)
	rm -f log-shuttle*.deb
