#!/usr/bin/env bash
set -ex

buildcmd() {
  buildah run -v "${VOLUME_ID}":/var/db/repos/gentoo --network host "${c}" -- "$@"
}

podman run -d gentoo/portage
VOLUME_ID="$(podman volume list | tail -n1 | awk '{print $2}')"
c=$(buildah from gentoo/stage3)

buildcmd mkdir -p /repo
buildcmd emerge --quiet-build -q dev-util/pkgcheck
# shellcheck disable=SC2016
buildcmd bash -c 'source /etc/portage/make.conf && rm "${DISTDIR}"/*'
buildcmd echo 'FEATURES="-ipc-sandbox -network-sandbox"' \| tee -a /etc/portage/make.conf

buildah config --entrypoint "/usr/bin/pkgcheck" "${c}"
buildah config --workingdir "/repo" "${c}"