#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# 1. enable Dux Labs COPRs (e.g. Dux Shell formery DMS ,Dux Files, Dux Calendar)
dnf5 -y copr enable duxlabs/dux
dnf5 -y copr enable duxlabs/dms

# 2. Install niri + the dux suite 
dnf5 -y install \
    niri \
    dms \
    dms-greeter \
    dux-files \
    dcal \
    dgop \
    dsearch \
    matugen \
    cliphist \
    wl-clipboard

# 2a. Check if packages are installed 
rpm -q niri quickshell dms dms-greeter dux-files dcal dgop dsearch
DMS_VER="$(rpm -q --qf '%{VERSION}' dms)"
case "$DMS_VER" in
    2.*) echo "Dux Shell $DMS_VER OK" ;;
    *)   echo "Expected Dux Shell 2.x, got $DMS_VER" >&2; exit 1 ;;
esac

# 3. Disable the COPRs so they don't stay enabled on the final image
dnf5 -y copr disable duxlabs/dux
dnf5 -y copr disable duxlabs/dms

# 4. Start the shell automatically whenever a niri session starts
if [ -f /usr/lib/systemd/user/dms.service ]; then
    mkdir -p /usr/lib/systemd/user/niri.service.wants
    ln -sf /usr/lib/systemd/user/dms.service \
        /usr/lib/systemd/user/niri.service.wants/dms.service
fi


# --------- Template comments keeping for context 

# this installs a package from fedora repos
# dnf5 install -y tmux

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
