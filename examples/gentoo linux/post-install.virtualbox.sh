#!/usr/bin/env sh

eselect profile set "default/linux/amd64/17.1/desktop/plasma"
emerge --sync
emerge \
  --quiet --verbose \
  --update --deep --with-bdeps=y \
  --changed-use --newuse \
  @world


cat | tee /etc/portage/package.use/kde <<EOF
kde-plasma/powerdevil brightness-control

# include gtk support
# exclude vault
# discover not working for some reason to be checked
# qrcode not working for some reason to be checked
kde-plasma/plasma-meta grub gtk -crypt
EOF
emerge \
  --quiet --verbose \
  app-cdr/dolphin-plugins-mountiso \
  kde-apps/ark \
  kde-apps/dolphin-plugins-git \
  kde-apps/kdecore-meta \
  kde-plasma/plasma-meta
rc-update add dbus default
rc-update add elogind default
cat > /home/mek/.xinitrc <<EOF
#!/bin/sh
exec dbus-launch --exit-with-session startplasma-wayland
EOF

cp /etc/pam.d/sddm-greeter /etc/pam.d/sddm-greeter.backup
echo "session optional pam_elogind.so" >> /etc/pam.d/sddm-greeter
sed -i.backup 's/^DISPLAYMANAGER=.*$/DISPLAYMANAGER="sddm"/' /etc/conf.d/display-manager
rc-update add display-manager default

echo | tee /etc/portage/package.use/firefox-bin <<EOF
# required by media-sound/pulseaudio-13.0-r1::gentoo[alsa-plugin,alsa]
# required by www-client/firefox-bin-89.0.2::gentoo[pulseaudio]
# required by www-client/firefox-bin (argument)
media-plugins/alsa-plugins pulseaudio
EOF
emerge \
  --quiet --verbose \
  www-client/firefox-bin
