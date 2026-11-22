#!/bin/bash -e

install -d "${ROOTFS_DIR}/var/tmp/tone3000-image"
install -m 0644 "${BASE_DIR}"/patches/*.patch "${ROOTFS_DIR}/var/tmp/tone3000-image/"
cp -a files/. "${ROOTFS_DIR}/"
