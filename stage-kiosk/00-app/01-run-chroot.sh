#!/bin/bash -e
set -u

user=tone-kiosk
home=/home/$user
build=$(mktemp -d /var/tmp/tone3000-build.XXXXXX)
trap 'rm -rf -- "$build" /var/tmp/tone3000-image' EXIT
useradd --create-home --home-dir "$home" --shell /bin/bash --user-group "$user"
passwd --lock root
chmod 0700 "$home"
chown "$user:$user" "$build"
chmod 0755 /usr/local/libexec/tone3000-kiosk-session
test "$(stat -c '%u:%g' /etc/systemd/system/tone3000-kiosk-shutdown.service)" = 0:0
install -o "$user" -g "$user" -m 0644 /usr/share/tone3000-image/bash_profile "$home/.bash_profile"

revision=7eac7f0d5cd2797f8b2a854547c61b235f64d1e6
runuser -u "$user" -- bash -e -s -- "$build" "$revision" <<'APP_BUILD'
cd "$1"
git init --quiet
git fetch --depth 1 https://github.com/scullcom/tone3000-pi-fx.git "$2"
git checkout --quiet --detach FETCH_HEAD
git apply --check /var/tmp/tone3000-image/phone-sign-in.patch
git apply /var/tmp/tone3000-image/phone-sign-in.patch
install -m 0644 /var/tmp/tone3000-image/kiosk-autosave.patch cmake/patches/
# Use the fork's existing patch application path so the change survives reconfigure.
sed -i 's/juce-linux-desktop-id)/juce-linux-desktop-id kiosk-autosave)/' CMakeLists.txt
grep -q 'juce-linux-desktop-id kiosk-autosave)' CMakeLists.txt
T3K_PI_BUILD_DIR="$PWD/build" bash install.sh --with-guitarix
# The desktop installer treats a partial artwork download as recoverable.
python3 script/install-guitarix-artwork.py "$HOME/.config/tone3000-pi-fx/TONE3000"
APP_BUILD

app="$home/.local/share/tone3000-pi-fx/TONE3000"
profile="$home/.config/tone3000-pi-fx/TONE3000"
test -x "$app"
test -s "$profile/Presets/Factory/Clean Trem and Verb.t3kpreset"
test -n "$(find "$profile/lv2-artwork" -type f -name '*.png' -print -quit)"
install -d /opt/tone3000-pi-fx
mv -- "$app" /opt/tone3000-pi-fx/TONE3000
chown root:root /opt/tone3000-pi-fx/TONE3000
sed -i 's|^exec "\$XDG_DATA_HOME/TONE3000"|exec /opt/tone3000-pi-fx/TONE3000|' "$home/.local/bin/tone3000-pi-fx"
grep -q '^exec /opt/tone3000-pi-fx/TONE3000' "$home/.local/bin/tone3000-pi-fx"
bash -n "$home/.local/bin/tone3000-pi-fx"
printf '%s\n' "$revision" > /usr/share/tone3000-image/app-revision
systemctl enable getty@tty7.service tone3000-kiosk-shutdown.service
apt-get clean
