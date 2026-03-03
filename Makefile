SHELL=/bin/sh

current_dir:=$(shell pwd)
changelog:=$(current_dir)/debian/changelog

pkgname:=$(shell head -n 1 $(changelog) | \
           awk '{print $$1}')

version:=$(shell head -n 1 $(changelog) | \
           awk '{print $$2}' | \
           sed 's+[\(\)]++g')

pkgname_ver:=$(pkgname)_$(version)

src_dir:=$(current_dir)/$(pkgname_ver)
usr_dir:=$(current_dir)/usr

pkg_dist.dir?=/var/tmp

build: pre bld post

bld:

cfg: pre cfg-deb post

cfg-deb:

install: pre install-files prune fix post

install-files:
	mkdir -p $(DESTDIR)/sbin
	mkdir $(DESTDIR)/etc
	cp $(src_dir)/ifdl $(DESTDIR)/sbin/.
	cp $(src_dir)/ifset $(DESTDIR)/sbin/.
	cp $(src_dir)/ifdl.conf $(DESTDIR)/etc/.

prune:

fix:

dist:
	cp ../$(pkgname)_$(version)_i386.deb $(pkg_dist.dir)

bin-pkg:
	dpkg-buildpackage -B

src-pkg:
	dpkg-buildpackage -S

pre:
	if ! [ -d $(pkgname_ver) ]; then mv src $(pkgname_ver) ; fi

post:
	if [ -d $(pkgname_ver) ]; then mv $(pkgname_ver) src ; fi

# Clean targets
clean-debian:
	debian/rules clean

clean-src:

clean-dst:
	-rm -rf $(dst_dir)

clean-pkg:
	-rm ../$(pkgname_ver).dsc 
	-rm ../$(pkgname_ver).tar.gz 
	-rm ../$(pkgname_ver)_source.changes
	-rm ../$(pkgname_ver)_i386.deb 
	-rm ../$(pkgname_ver)_i386.changes

clean-most: pre clean-debian clean-src clean-dst post
distclean clean-all: pre clean-debian clean-src clean-dst clean-pkg post

.PHONY: clean
