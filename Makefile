SHELL=/bin/sh

# debhelper runs `make -j16`; pre/post rename the source dir, so serialize
.NOTPARALLEL:

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

# Must be set here: clean-dst does `rm -rf` on it, and make would otherwise
# take the value from the environment
dst_dir:=$(current_dir)/dst

pkg_dist.dir?=/var/tmp

build: pre bld post

bld:

cfg: pre cfg-deb post

cfg-deb:

install: pre install-files prune fix post

install-files:
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/etc
	cp $(src_dir)/ifdl $(DESTDIR)/sbin/.
	cp $(src_dir)/ifset $(DESTDIR)/sbin/.
	cp $(src_dir)/ifdl.conf $(DESTDIR)/etc/.

prune:

fix:

dist:
	cp ../$(pkgname_ver)_*.deb $(pkg_dist.dir)

bin-pkg:
	dpkg-buildpackage -b

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
	rm -rf $(dst_dir)

# Clean up build artifacts, which dpkg writes to the parent directory
clean-pkg:
	rm -f ../$(pkgname_ver).dsc \
	      ../$(pkgname_ver).tar.* \
	      ../$(pkgname_ver)_*.deb \
	      ../$(pkgname_ver)_*.changes \
	      ../$(pkgname_ver)_*.buildinfo

clean-most: pre clean-debian clean-src clean-dst post
distclean clean-all: pre clean-debian clean-src clean-dst clean-pkg post

# Keep this complete: `build` has no recipe, so without it make applies its
# built-in `%: %.sh` rule and generates a `build` file from build.sh
.PHONY: build bld cfg cfg-deb install install-files prune fix dist \
        bin-pkg src-pkg pre post clean clean-debian clean-src clean-dst \
        clean-pkg clean-most distclean clean-all
