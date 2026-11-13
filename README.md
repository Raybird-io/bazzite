# Bazzite + Umbriel + Dux Shell

My personal [Bazzite](https://bazzite.gg/) image. It keeps everything Bazzite gives me for gaming (kernel, drivers, Steam, updates, rollback) and adds my desktop on top:

- **[Umbriel](https://docs.noctalia.dev/umbriel/)**: the compositor I use every day (scrolling and tiling layouts).
- **[Dux Shell (DMS)](https://duxlabs.dev/)**: the bar, launcher, notifications, control centre and lock screen.
- **Dux apps**: Files, Calendar, Search and GOP (system monitor).
- **Dux Greeter**: the DMS-styled login screen.
- **My Umbriel config and two helper scripts**: automatic monitor setup, and resizing windows that move between monitors.

GitHub builds the image from this repo every day and whenever I push. My PC downloads the new image in the background and switches to it on the next reboot.

Built from Universal Blue's [image template](https://github.com/ublue-os/image-template), the recommended way to customise their images.

---

## How it fits together

| Path | What it does |
| --- | --- |
| `Containerfile` | Picks the base image (`bazzite-gnome:stable`), runs `build.sh`, then checks the result with `bootc container lint`. |
| `build_files/build.sh` | Installs packages and switches services on. **Most changes happen here.** |
| `system_files/` | Copied into the image as-is: `system_files/etc/...` ends up in `/etc/...`, and so on. |
| `system_files/etc/xdg/umbriel/` | My Umbriel config: `config.toml`, `keybinds.toml`, `rules.toml`. |
| `system_files/usr/libexec/` | My two helper scripts. |
| `system_files/usr/lib/systemd/user/` | The services that start those scripts in Umbriel sessions. |
| `.github/workflows/build.yml` | Builds, signs and publishes the image (daily at 03:15 UTC, and on every push). |
| `image-template.env` | Image name and description. |
| `cosign.pub` | Public key that proves the image is mine. The private key is the `SIGNING_SECRET` repo secret. |
| `disk_config/` | Settings for building an install ISO of this image, if I ever need one. |

### Where packages come from

| Packages | Source |
| --- | --- |
| `dms`, `dux-greeter` | Dux Labs COPR `duxlabs/dms` |
| `quickshell` (DMS needs it), `niri`, `dux-files`, `dux-search`, `dux-calendar`, `dux-gop`, `matugen` | Dux Labs COPR `duxlabs/dux-repo` |
| `umbriel-nightly` (brings its screen-sharing portal and `xwayland-satellite`) | Terra, which comes with Bazzite |
| `cliphist`, `wl-clipboard` | Fedora |

The two COPRs are only switched on during the build, then switched off again, so the finished image doesn't keep extra repos. Updates to DMS arrive with the daily image rebuild.

**Why niri is installed:** only to draw the login screen. Dux Greeter can't run on Umbriel yet; it supports niri, Hyprland, Sway, MangoWC and Miracle WM. Niri shows up as a session at login, but I don't use it.

### What starts when I log into Umbriel

`build.sh` hooks these into Umbriel's session (`umbriel-session.target`), so they start in Umbriel sessions only, not in GNOME:

- `dms.service`: Dux Shell.
- `umbriel-monitors.service`: runs `/usr/libexec/umbriel-monitors`.
- `umbriel-resize-on-move.service`: runs `/usr/libexec/umbriel-resize-on-move`.

---

## Using the image

### Switch a PC to this image

On any Bazzite or Fedora Atomic system:

```bash
sudo bootc switch ghcr.io/raybird-io/bazzite:latest
systemctl reboot
```

Check what the PC is running with `sudo bootc status`.

### First boot only: set up the login screen

Dux Labs' docs say to run the greeter setup yourself on image-based systems:

```bash
dms-greeter install --yes   # switches the login screen from GNOME's to Dux Greeter
dms greeter sync            # copies my DMS theme and wallpaper to the login screen
```

Reboot, then pick **Umbriel** at the login screen.

To go back to GNOME's login screen: `dms greeter uninstall`.

### First boot only: remove my old home config

If `~/.config/umbriel/` exists, Umbriel uses it **instead of** the config in this image. Move it out of the way:

```bash
mv ~/.config/umbriel ~/.config/umbriel.old
```

---

## Making changes

### Add or remove a package

1. Edit the `dnf5 -y install` list in `build_files/build.sh`.
2. Commit and push.
3. Watch the **Actions** tab on GitHub. A red ✗ means the build failed, and my PC simply stays on the last good image.
4. When the build is green, reboot to pick up the new image (or wait for the automatic update).

### Change my Umbriel config

The real config lives in `system_files/etc/xdg/umbriel/`, so changes there need a push and a rebuild.

To experiment without rebuilding, create `~/.config/umbriel/config.toml` on the PC:

```toml
[include]
files = ["/etc/xdg/umbriel/config.toml"]

# my experiments below; they win over the image's settings
```

Changes there apply as soon as the file is saved. When I'm happy with them, I copy them into the repo and delete the experiment file.

Check any config for mistakes with `umbriel config validate`.

### Change the helper scripts

Edit the files in `system_files/usr/libexec/` and push. The services run them with `bash`, so they don't need to be marked executable.

To change how side monitors are turned, edit `SIDE_ROTATION` at the top of `umbriel-monitors` (`"270"`, `"90"` or `"normal"`).

---

## When something goes wrong

| Problem | What to do |
| --- | --- |
| New image is broken | Reboot and pick the previous entry in the boot menu, or run `sudo bootc rollback` and reboot. |
| Build fails on GitHub | Open the failed run in the **Actions** tab. The red step shows the error. Nothing changes on my PC until a build succeeds. |
| DMS isn't running | `systemctl --user status dms` and `dms doctor` |
| Monitors aren't set up | `systemctl --user status umbriel-monitors`. The generated file is `~/.local/state/umbriel/monitors.toml`. |
| Windows don't resize when moved | `systemctl --user status umbriel-resize-on-move` |
| Umbriel config error | `umbriel config validate` shows the file, line and problem. |
| Login screen is broken | Switch to a text console with Ctrl+Alt+F3, log in, and run `dms greeter uninstall`. |

---

## Things to know

- **Umbriel only has nightly builds.** If a nightly changes one of its commands, a helper script may stop working until I update it.
- **DMS supports Umbriel at a basic level.** The DMS developers are holding off on deeper Umbriel support until Umbriel matures ([dux-shell#4023](https://github.com/duxlabs-dev/dux-shell/issues/4023)).
- **Package names changed in the Dank → Dux rename.** This repo uses the new names (`dux-greeter`, `dux-search`, `dux-calendar`, `dux-gop`). The commands didn't change (`dms`, `dms-greeter`, `dsearch`, `dcal`, `dgop`).
- **`mkdir -p /nix` in `build.sh`** is left over from using Nix. Remove it once I'm sure I no longer need it.
