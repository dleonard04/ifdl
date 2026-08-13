#!/bin/sh
# Build the ifdl Debian package.
set -e

cd "$(dirname "$0")"
dpkg-buildpackage -b -us -uc
