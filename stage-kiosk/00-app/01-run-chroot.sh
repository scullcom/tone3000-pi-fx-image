#!/bin/bash -e
set -u

user=tone-kiosk
home=/home/$user
build=$(mktemp -d /var/tmp/tone3000-build.XXXXXX)
trap 'rm -rf -- "$build" /var/tmp/tone3000-image' EXIT
useradd --create-home --home-dir "$home" --shell /bin/bash --user-group --groups audio,render "$user"
passwd --lock root
if id pi >/dev/null 2>&1; then passwd --lock pi; fi
# The kiosk already has its own account. Leave cloud-init available for Imager and Wi-Fi.
systemctl mask userconfig.service
chmod 0700 "$home"
chown "$user:$user" "$build"
chmod 0755 /usr/local/libexec/tone3000-kiosk-session /usr/local/libexec/tone3000-kiosk-keyboard
test "$(stat -c '%u:%g' /etc/systemd/system/tone3000-kiosk-shutdown.service)" = 0:0
install -o "$user" -g "$user" -m 0644 /usr/share/tone3000-image/bash_profile "$home/.bash_profile"

revision=523bbec7c35a15dd40f032ab6c9bf1bcce8f5b87
runuser -u "$user" -- env -i HOME="$home" USER="$user" LOGNAME="$user" \
  PATH=/usr/local/bin:/usr/bin:/bin T3K_PI_JOBS="${T3K_IMAGE_JOBS:-2}" \
  bash -e -s -- "$build" "$revision" <<'APP_BUILD'
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

theme=/usr/share/plymouth/themes/tone3000
rsvg-convert --width=420 --keep-aspect-ratio --output="$theme/logo.png" "$build/plugin/ui/assets/t3k.svg"
python3 - "$theme/logo.png" "$build/logo.tga" <<'SPLASH_IMAGE'
import sys
from PIL import Image

logo = Image.open(sys.argv[1]).convert("RGBA")
background = Image.new("RGB", logo.size, "black")
background.paste(logo, mask=logo.getchannel("A"))
background.quantize(colors=224).convert("RGB").save(sys.argv[2])
SPLASH_IMAGE
plymouth-set-default-theme tone3000
configure-splash "$build/logo.tga" --no-cmdline

# Keep the serial console and all root/resize arguments. HDMI shows the splash.
cmdline=/boot/firmware/cmdline.txt
read -r -a boot_params < "$cmdline" || [[ "${#boot_params[@]}" -gt 0 ]]
keep=()
for arg in "${boot_params[@]}"; do
  case "$arg" in
    console=tty1|quiet|splash|loglevel=*|systemd.show_status=*|plymouth.ignore-serial-consoles|\
    fullscreen_logo=*|fullscreen_logo_name=*|vt.global_cursor_default=*) ;;
    *) keep+=("$arg") ;;
  esac
done
keep+=(fullscreen_logo=1 fullscreen_logo_name=logo.tga vt.global_cursor_default=0 \
  splash plymouth.ignore-serial-consoles loglevel=3 systemd.show_status=false)
printf '%s\n' "${keep[*]}" > "$cmdline"
printf 'gb\n' > /boot/firmware/tone3000-keyboard.txt

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
