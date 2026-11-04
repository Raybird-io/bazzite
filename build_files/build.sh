#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Enable COPRs
dnf5 -y copr enable duxlabs/dms
dnf5 -y copr enable duxlabs/dux-repo

# Install niri + the Dux suite
dnf5 -y install \
niri \
xwayland-satellite \
dms \
dux-greeter \
dux-files \
danksearch \
dankcalendar \
dgop \
matugen \
cliphist \
wl-clipboard

# Disable the COPRs so they don't stay enabled on the final image
dnf5 -y copr disable duxlabs/dms
dnf5 -y copr disable duxlabs/dux-repo

#### Example for enabling a System Unit File
systemctl enable podman.socket