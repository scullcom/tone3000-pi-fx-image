# TONE3000 FX for Raspberry Pi 5

This project builds a 64-bit Raspberry Pi OS Trixie image that boots straight into the TONE3000 FX standalone app. It includes Guitarix LV2 effects and pedal artwork, plus the **Clean Trem and Verb** factory preset. The desktop version and its installer are available from the [TONE3000 FX app repo](https://github.com/scullcom/tone3000-pi-fx).

## Try a preview

1. Open [Actions](https://github.com/scullcom/tone3000-pi-fx-image/actions/workflows/image.yml) and download the artifact from a successful build. Extract the artifact ZIP to get a file ending in `.img.xz` and its SHA-256 checksum. Preview builds should go on a spare card, ideally 16 GB or larger.
2. In Raspberry Pi Imager, select **Raspberry Pi 5** and **Use custom**, then choose the `.img.xz` and the spare card. Imager erases the selected card. Use OS customisation to set your own maintenance username and password and, if needed, Wi-Fi and its country. Choose a username other than `tone-kiosk`, which the image reserves for the app. Ethernet also works for initial setup.
3. Connect a monitor, a USB audio interface and a keyboard, then boot. The kiosk should open TONE3000 FX full-screen. Use its audio settings to select the interface, input and output channels, sample rate and buffer size. Open **Clean Trem and Verb** from the preset list to try the signal chain.
4. For online tones, choose **Sign in**. Scan the QR code with a phone, or visit **tone3000.com/activate** on a second device and type the displayed code. The Pi needs internet access during sign-in and when browsing online tones. Local effects and presets work offline.

## Saving and shutting down

The app checkpoints the working rig every 15 seconds. At a clean shutdown it saves the rig and audio setup again. The session restores on boot, and saving it leaves named presets available as separate files. The TONE3000 account session is stored by the app on that card.

Use a short press on the Pi 5 power button to shut down, or run `sudo poweroff` from your maintenance account. Allow the Pi to finish shutting down before disconnecting power.

Press **Ctrl+Alt+F2** to log in to the maintenance console, where you can run `sudo nmtui` for network setup. Press **Ctrl+Alt+F7** to return to the kiosk. SSH starts disabled, and the kiosk account has a locked password and no sudo privileges by default.

## Build the image

The GitHub **Build Pi 5 kiosk image** workflow runs on a native ARM64 Linux runner and produces an image and checksum. On a 64-bit ARM Debian-family build machine with a Linux filesystem, at least 20 GB free is a practical starting point. Install the pi-gen dependencies and run:

```sh
sudo apt-get update
sudo apt-get install quilt parted qemu-user debootstrap zerofree zip dosfstools e2fsprogs \
  libcap2-bin libarchive-tools rsync xz-utils curl xxd file git kmod bc gpg pigz arch-test
bash build-image.sh
```

Find the compressed image and checksum in `dist/`. The build uses an official [pi-gen](https://github.com/RPi-Distro/pi-gen) release and a pinned revision of the TONE3000 FX fork. The patches in this repo add phone-first login and kiosk shutdown handling. Build output is separate from both source repositories.

## Preview verification

- Boot a fresh card with a USB interface. Confirm the app fills the display and its settings remain accessible.
- Sign in on a phone. Approve the login and check online browsing in the app. Reboot and confirm the account is still signed in.
- Open **Clean Trem and Verb**, adjust the tremolo or reverb, and shut down immediately using the power button. Boot and check the changed value, preset file, interface, channels and buffer size.
- Listen at your intended buffer size through at least one autosave. Boot again with networking disconnected to check offline playback.

## Credits and source

The image uses [Raspberry Pi OS and pi-gen](https://github.com/RPi-Distro/pi-gen), [labwc](https://github.com/labwc/labwc), [JUCE](https://github.com/juce-framework/JUCE), [Neural Amp Modeler](https://github.com/sdatkinson/NeuralAmpModelerCore), [Guitarix and its pedal artwork](https://github.com/brummer10/guitarix), and the [TONE3000 plugin](https://github.com/tone-3000/tone3000-plugin). The [app fork](https://github.com/scullcom/tone3000-pi-fx/tree/7eac7f0d5cd2797f8b2a854547c61b235f64d1e6) carries the factory preset and its model attribution. The package license notices are included in the image under `/usr/share/doc`.
