#!/bin/bash
set -euo pipefail

doas xbps-install -Suy \
  alsa-pipewire \
  ark \
  base-devel \
  bat \
  btop \
  cava \
  clang-tools-extra \
  cmake \
  cryptsetup \
  ddcutil \
  dmidecode \
  dolphin \
  duf \
  edk2-ovmf \
  exfatprogs \
  fastfetch \
  fd \
  firefox \
  fzf \
  gnome-disk-utility \
  incus \
  jq \
  keepassxc \
  kitty \
  lazygit \
  libreoffice-fonts \
  libreoffice-gnome \
  libreoffice-i18n-ru \
  libreoffice-impress \
  lld \
  llvm \
  lsd \
  mesa-dri \
  mesa-vulkan-radeon \
  meson \
  niri \
  nmap \
  noto-fonts-emoji \
  ntfs-3g \
  nvme-cli \
  nvtop \
  openbsd-netcat \
  openjdk25 \
  pipewire \
  poppler \
  python3-Pillow \
  qbittorrent \
  qemu-img \
  qemu-system-amd64 \
  qt5-wayland \
  ranger \
  ripgrep \
  rtkit \
  swtpm \
  tcpdump \
  telegram-desktop \
  tuigreet \
  udiskie \
  virt-manager \
  vlc \
  vsv \
  wl-clipboard \
  xdg-user-dirs \
  xtools \
  xwayland-satellite \
  zellij

xdg-user-dirs-update

cp -r bat cava fastfetch fish kitty lazygit niri noctalia nvim ranger zellij btop /home/gluow/.config/
cp images/* /home/gluow/Изображения/
cp lavat.sh /home/gluow/

mkdir -p /home/gluow/.local/state/noctalia
touch /home/gluow/.local/state/noctalia/.setup-complete

git clone https://github.com/void-linux/void-packages.git /home/gluow/void-packages
cd /home/gluow/void-packages
./xbps-src binary-bootstrap
echo XBPS_ALLOW_RESTRICTED=yes >etc/conf

git clone https://github.com/gluow3377/void-srcpkgs.git /home/gluow/void-srcpkgs
cp -r /home/gluow/void-srcpkgs/* srcpkgs/
rm -rf /home/gluow/void-srcpkgs

./xbps-src pkg font-jetbrains-mono-nerd
./xbps-src pkg font-times-new-roman
./xbps-src pkg noctalia
./xbps-src pkg PrismLauncher
./xbps-src pkg google-chrome
./xbps-src pkg lavat
./xbps-src pkg obsidian
./xbps-src pkg throne

doas xbps-install -Suy --repository hostdir/binpkgs font-jetbrains-mono-nerd
doas xbps-install -Suy --repository hostdir/binpkgs/nonfree font-times-new-roman
doas xbps-install -Suy --repository hostdir/binpkgs noctalia
doas xbps-install -Suy --repository hostdir/binpkgs PrismLauncher
doas xbps-pkgdb -m repolock PrismLauncher
doas xbps-install -Suy --repository hostdir/binpkgs/nonfree google-chrome
doas xbps-install -Syu --repository hostdir/binpkgs lavat
doas xbps-install -Syu --repository hostdir/binpkgs/nonfree obsidian
doas xbps-install -Suy --repository hostdir/binpkgs throne

fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
fish -c 'fisher install IlanCosman/tide@v6'
fish -c "tide configure --auto --style=Rainbow --prompt_colors='16 colors' --show_time='24-hour format' --rainbow_prompt_separators=Round --powerline_prompt_heads=Sharp --powerline_prompt_tails=Round --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=No --prompt_spacing=Compact --icons='Many icons' --transient=Yes"

mkdir -p /home/gluow/.config/pipewire/pipewire.conf.d
ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /home/gluow/.config/pipewire/pipewire.conf.d/
ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /home/gluow/.config/pipewire/pipewire.conf.d/

doas mkdir -p /etc/alsa/conf.d
doas ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d
doas ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d

doas sed -i 's/^command = .*/command = "tuigreet --user gluow --session-wrapper dbus-run-session"/' /etc/greetd/config.toml

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
