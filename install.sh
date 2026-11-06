#!/bin/bash
set -euo pipefail

packages=(
  alsa-pipewire
  alsa-pipewire-32bit
  ark
  base-devel
  bash-language-server
  bat
  btop
  cava
  clang-tools-extra
  cmake
  cryptsetup
  dconf
  ddcutil
  dmidecode
  dolphin
  duf
  edk2-ovmf
  exfatprogs
  fastfetch
  fd
  firefox
  fzf
  gnome-disk-utility
  gsettings-desktop-schemas
  incus
  jq
  keepassxc
  kitty
  lazygit
  libdrm-32bit
  libgcc-32bit
  libglvnd-32bit
  libpulseaudio-32bit
  libreoffice-fonts
  libreoffice-gnome
  libreoffice-i18n-ru
  libreoffice-impress
  libstdc++-32bit
  libva-32bit
  lld
  llvm
  lsd
  lua-language-server
  mesa-dri
  mesa-dri-32bit
  mesa-vulkan-radeon
  mesa-vulkan-radeon-32bit
  meson
  niri
  nmap
  noto-fonts-emoji
  ntfs-3g
  nvme-cli
  nvtop
  openbsd-netcat
  openjdk25
  papirus-icon-theme
  pipewire
  poppler
  python3-Pillow
  qbittorrent
  qemu-img
  qemu-system-amd64
  qt5-wayland
  qt5ct
  qt6ct
  ranger
  ripgrep
  rtkit
  shellcheck
  shfmt
  steam
  swtpm
  tcpdump
  telegram-desktop
  # tuigreet
  udiskie
  uv
  virt-manager
  vlc
  vsv
  vulkan-loader
  vulkan-loader-32bit
  wireshark-qt
  wl-clipboard
  xdg-user-dirs
  xmirror
  xtools
  xwayland-satellite
  zellij
  zstd
)

doas xbps-install -Suy "${packages[@]}"

xdg-user-dirs-update

cp -r bat cava fastfetch fish kitty lazygit niri noctalia nvim ranger zellij btop /home/gluow/.config/
cp -r gtk-3.0 gtk-4.0 qt5ct qt6ct keepassxc kdeglobals /home/gluow/.config/
mkdir -p /home/gluow/.local/share/color-schemes
cp color-schemes/GruvboxDark.colors /home/gluow/.local/share/color-schemes/
cp images/* /home/gluow/Изображения/
cp lavat.sh /home/gluow/

dbus-run-session -- sh -ec '
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
gsettings set org.gnome.desktop.interface cursor-theme Adwaita
gsettings set org.gnome.desktop.interface cursor-size 16
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
'

mkdir -p /home/gluow/.local/state/noctalia
touch /home/gluow/.local/state/noctalia/.setup-complete

git clone https://github.com/void-linux/void-packages.git /home/gluow/void-packages
cd /home/gluow/void-packages
./xbps-src binary-bootstrap
echo XBPS_ALLOW_RESTRICTED=yes >etc/conf

echo 'repository=https://gluow3377.github.io/void-repo/current' | doas tee /etc/xbps.d/20-gluow3377.conf
doas xbps-install -S
doas xbps-install -Suy font-jetbrains-mono-nerd noctalia lavat throne adw-gtk3 noctalia-greeter

git clone https://github.com/gluow3377/void-repo.git /home/gluow/void-repo
cp -r /home/gluow/void-repo/srcpkgs/* srcpkgs/
rm -rf /home/gluow/void-repo

# ./xbps-src pkg font-times-new-roman
./xbps-src pkg PrismLauncher-offline
# ./xbps-src pkg google-chrome
./xbps-src pkg obsidian

# doas xbps-install -Suy --repository hostdir/binpkgs/nonfree font-times-new-roman
doas xbps-install -Suy --repository hostdir/binpkgs PrismLauncher-offline
# doas xbps-install -Suy --repository hostdir/binpkgs/nonfree google-chrome
doas xbps-install -Syu --repository hostdir/binpkgs/nonfree obsidian

fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
fish -c 'fisher install IlanCosman/tide@v6'
fish -c "tide configure --auto --style=Rainbow --prompt_colors='16 colors' --show_time='24-hour format' --rainbow_prompt_separators=Round --powerline_prompt_heads=Sharp --powerline_prompt_tails=Round --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_spacing=Compact --icons='Many icons' --transient=Yes"

mkdir -p /home/gluow/.config/pipewire/pipewire.conf.d
ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /home/gluow/.config/pipewire/pipewire.conf.d/
ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /home/gluow/.config/pipewire/pipewire.conf.d/

doas mkdir -p /etc/alsa/conf.d
doas ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d
doas ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d

# doas sed -i 's/^command = .*/command = "tuigreet --user gluow --session-wrapper dbus-run-session"/' /etc/greetd/config.toml
doas sed -i 's/^command = .*/command = "noctalia-greeter-session -- --user gluow --session-wrapper dbus-run-session"/' /etc/greetd/config.toml

doas tee /var/lib/noctalia-greeter/greeter.toml >/dev/null <<'EOF'
[appearance]
scheme = "Gruvbox"
password_style = "random"

[keyboard]
layout = "us,ru"
options = "grp:alt_shift_toggle"
EOF

doas usermod -aG libvirt gluow
doas ln -s /etc/sv/{libvirtd,virtlockd,virtlogd} /var/service/

doas sed -i 's/^#\?CGROUP_MODE=.*/CGROUP_MODE=unified/' /etc/rc.conf
doas usermod -aG _incus-admin gluow
doas ln -s /etc/sv/incus /var/service/

doas nmcli connection add ifname br0 type bridge con-name br0
doas nmcli connection add type bridge-slave ifname enp5s0 master br0
doas nmcli connection modify br0 bridge.stp no
doas nmcli connection modify "Wired connection 1" connection.autoconnect no
doas nmcli connection modify br0 802-3-ethernet.cloned-mac-address 10:ff:e0:69:03:e6

doas ln -s /etc/sv/greetd /var/service/

doas zfs snapshot -r zroot@postinstall

doas reboot
