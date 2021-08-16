#!/usr/bin/env bash
set -ex

buildcmd() {
  buildah run -v "${MOUNT_POINT}":/var/db/repos/gentoo --network host "${c}" -- "$@"
}

podman run -d gentoo/portage
VOLUME_ID="$(podman volume list | tail -n1 | awk '{print $2}')"
MOUNT_POINT="$(podman volume inspect $VOLUME_ID | jq -r '.[].Mountpoint')"
c=$(buildah from gentoo/stage3)

buildcmd mkdir -p /repo
buildcmd emerge --quiet-build -q dev-util/pkgcheck
# shellcheck disable=SC2016
buildcmd bash -c 'source /etc/portage/make.conf && rm "${DISTDIR}"/*'
buildcmd rm /etc/portage/make.profile
# shellcheck disable=SC2016
buildah run -v "${MOUNT_POINT}":/mnt "${c}" -- bash -c 'source /etc/portage/make.conf && cp -a /mnt/profiles "${PORTDIR}"'
buildcmd echo 'FEATURES="-ipc-sandbox -network-sandbox"' \| tee -a /etc/portage/make.conf

buildah config --entrypoint '["/usr/bin/pkgcheck"]' "${c}"
buildah config --workingdir "/repo" "${c}"

buildah commit --format=docker --squash --rm "${c}" "ghcr.io/${GITHUB_REPOSITORY_OWNER}/pkgcheck:latest"
buildah push "ghcr.io/${GITHUB_REPOSITORY_OWNER}/pkgcheck:latest"