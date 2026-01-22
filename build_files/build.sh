#!/usr/bin/env bash

set "${CI:+-x}" -euo pipefail

ARCH="$(rpm -E '%_arch')"
KERNEL="$(rpm -q "${KERNEL_NAME:-kernel}" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
RELEASE="$(rpm -E '%fedora')"

dnf copr enable -y makl11/r8125-akmod

dnf install -y r8125-*.fc"${RELEASE}"."${ARCH}"

# Install akmods signing key to enable Secure Boot support
BUILD_DIR="$(dirname -- "${BASH_SOURCE[0]}")"
install -Dm644 "$BUILD_DIR"/certs/public_key.der   /etc/pki/akmods/certs/public_key.der
install -Dm644 "$BUILD_DIR"/certs/private_key.priv /etc/pki/akmods/private/private_key.priv

akmods --force --kernels "${KERNEL}" --kmod r8125
modinfo /usr/lib/modules/"${KERNEL}"/extra/r8125/r8125.ko.xz >/dev/null ||
	(find /var/cache/akmods/r8125/ -name \*.log -print -exec cat {} \; && exit 1)

rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:makl11:r8125-akmod.repo
