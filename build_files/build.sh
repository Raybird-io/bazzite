#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Enable COPRs 
dnf5 -y copr enable duxlabs/dux
dnf5 -y copr enable duxlabs/dms
dnf5 -y copr enable avengemedia/danklinux
dnf5 -y copr enable avengemedia/dms

# Install niri + the Dux suite
dnf5 -y install \
niri \
dms \
dcal \
dgop \
dsearch \
matugen \
cliphist \
wl-clipboard

# Brave (official RPM)
dnf5 config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
dnf5 install -y brave-browser

# Brave installs into /opt, which bootc never updates. Move it to /usr and link it back at boot.
mv --verbose /opt/brave.com /usr/lib/brave.com
echo "L /var/opt/brave.com - - - - /usr/lib/brave.com" > /usr/lib/tmpfiles.d/brave.conf

# Greeter + Files: install if available, don't fail the build if not
dnf5 -y install --skip-unavailable dms-greeter
dnf5 -y install dux-files || dnf5 -y install dux-files-git || true



# Check the core packages (must be present) and that the shell is 2.x
rpm -q niri quickshell dms dankcalendar dgop danksearch
DMS_VER="$(rpm -q --qf '%{VERSION}' dms)"
case "$DMS_VER" in
2.*) echo "Dux Shell $DMS_VER OK" ;;
*)   echo "Expected Dux Shell 2.x, got $DMS_VER" >&2; exit 1 ;;
esac
# Show greeter/Files versions in the log, without failing if one is missing
rpm -q dms-greeter dux-files dux-files-git || true



# Disable the extra repos so they don't stay enabled on the final image
dnf5 -y copr disable duxlabs/dux
dnf5 -y copr disable duxlabs/dms
dnf5 -y copr disable avengemedia/danklinux
dnf5 -y copr disable avengemedia/dms
dnf5 config-manager setopt brave-browser.enabled=0

# Start the shell automatically whenever a niri session starts
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