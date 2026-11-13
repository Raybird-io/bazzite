#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Empty mount point for Nix (the Nix store itself lives in /var/home/nix).
# Delete this line if you no longer use Nix at all.
mkdir -p /nix

### Dux Modular Shell (DMS) + companion apps, from Dux Labs' own COPRs
# niri is only here to draw the DMS login screen (the greeter can't run on Umbriel yet).
# After first boot on this image, run once:  dms-greeter install --yes && dms greeter sync
# dux-repo provides quickshell; dms provides the shell itself.
dnf5 -y copr enable duxlabs/dux-repo
dnf5 -y copr enable duxlabs/dms

dnf5 -y install \
    dms \
    dux-greeter \
    niri \
    dux-files \
    dux-search \
    dux-calendar \
    dux-gop \
    matugen \
    cliphist \
    wl-clipboard

# Disable the COPRs so they don't stay enabled on the final image
dnf5 -y copr disable duxlabs/dms
dnf5 -y copr disable duxlabs/dux-repo

### Umbriel compositor, from Terra (already configured in Bazzite)
# Only nightly builds exist. This package also pulls in its screen-sharing
# portal (xdg-desktop-portal-umbriel-nightly) and xwayland-satellite.
dnf5 -y --enablerepo=terra install umbriel-nightly

### Start DMS and my two helper scripts with every Umbriel session (not in GNOME)
systemctl --global enable umbriel-monitors.service umbriel-resize-on-move.service
systemctl --global add-wants umbriel-session.target dms.service

#### Example for enabling a System Unit File
systemctl enable podman.socket
