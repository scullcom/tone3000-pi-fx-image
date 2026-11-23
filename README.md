# TONE3000 FX for Raspberry Pi 5

This project builds a 64-bit Raspberry Pi OS Trixie image that boots straight into the TONE3000 FX standalone app. It includes Guitarix LV2 effects and pedal artwork, plus the **Clean Trem and Verb** factory preset. The desktop version and its installer are available from the [TONE3000 FX app repo](https://github.com/scullcom/tone3000-pi-fx).

The image uses TONE3000 FX **v1.3.0**, including USB preset import and export. [App release notes](https://github.com/scullcom/tone3000-pi-fx/releases/tag/v1.3.0)

## Try a preview

1. Open [Actions](https://github.com/scullcom/tone3000-pi-fx-image/actions/workflows/image.yml) and download the artifact from a successful build. Extract the artifact ZIP to get a file ending in `.img.xz` and its SHA-256 checksum. Preview builds should go on a spare card, ideally 16 GB or larger.
2. In Raspberry Pi Imager, select **Raspberry Pi 5** and **Use custom**, then choose the `.img.xz` and the spare card. Imager erases the selected card. If OS customisation is offered, you can set Wi-Fi and create a maintenance account with a username other than `tone-kiosk`. If Imager skips customisation, use the first-boot Wi-Fi setup below or connect Ethernet. The kiosk keyboard defaults to English (UK). To change it, use the keyboard helper below before booting the card.
3. Connect a monitor and a USB audio interface, then boot. The TONE3000 logo should appear during startup before the full-screen app opens. The kiosk account and keyboard are preconfigured, so the interactive Raspberry Pi user setup is skipped. In the app's audio settings, select the interface, input and output channels, sample rate and buffer size. Open **Clean Trem and Verb** from the preset list to try the signal chain.
4. For online tones, choose **Sign in**. Scan the QR code with a phone, or visit **tone3000.com/activate** on a second device and type the displayed code. The Pi needs internet access during sign-in and when browsing online tones. Local effects and presets work offline.

### Wi-Fi when Imager skips customisation

Before the card's first boot, reinsert it into the Windows PC and look for the **bootfs** drive in File Explorer. Run the helper from this repository in PowerShell, replacing `D:` with the card's drive letter.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\configure-wifi.ps1 -BootDrive D:
```

Enter the country code, network name, and Wi-Fi password at the prompts. The helper updates the `network-config` file on the card. Eject the card and boot the Pi. For the manual file format, see [Raspberry Pi's first-boot Wi-Fi example](https://www.raspberrypi.com/news/cloud-init-on-raspberry-pi-os/#networking-configuration-network-config).

### Choose the keyboard layout from Windows

After flashing, open PowerShell in this repository and replace `D:` with the card's **bootfs** drive letter. For example, to choose US English, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\configure-keyboard.ps1 -BootDrive D: -Layout us
```

Use `gb` for English (UK), `de` for German, or `fr` for French. You can also pass an XKB variant, for example `-Layout us -Variant intl`. The helper writes `tone3000-keyboard.txt` on the card. The Pi applies it before the kiosk starts, so you can also edit the card later. To set it manually, put the layout code on the first line and the optional variant on the second line of that file.

## Saving and shutting down

The app checkpoints the working rig every 15 seconds. At a clean shutdown it saves the rig and audio setup again. The session restores on boot, and saving it leaves named presets available as separate files. The TONE3000 account session is stored by the app on that card.

Open the Settings and Login menu in TONE3000, select **Shut down Pi…**, and confirm. The app saves the working session for the next boot. To update a named preset, save it in the app before shutting down. A short press on the Pi 5 power button also shuts down the device. Allow it to finish before disconnecting power.

If you configured a maintenance account, press **Ctrl+Alt+F2** to log in to the maintenance console, where you can run `sudo nmtui` for network setup. Press **Ctrl+Alt+F7** to return to the kiosk. SSH starts disabled, and the kiosk account has a locked password and no sudo privileges by default.

## Move presets between cards

To migrate user presets to this image, use **Export** in the Settings and Login menu of TONE3000 FX v1.3.0. Select the banks and presets you want to keep. The app writes them to `/Tone3000-pi-fx/presets` on the USB drive and replaces any previous backup in that folder.

Boot this kiosk image, open the same menu, and choose **Import**. Insert the USB drive and select what to restore. Banks with matching names are merged and matching presets within those banks are overwritten. This backup transfers user presets and banks. Set up your audio interface and TONE3000 sign-in separately on the new card.

## Build the image

The GitHub **Build Pi 5 kiosk image** workflow runs on a native ARM64 Linux runner and produces an image and checksum. On a 64-bit ARM Debian-family build machine with a Linux filesystem, at least 20 GB free is a practical starting point. Install the pi-gen dependencies and run:

```sh
sudo apt-get update
sudo apt-get install quilt parted qemu-user debootstrap debian-archive-keyring zerofree zip dosfstools e2fsprogs \
  libcap2-bin libarchive-tools rsync xz-utils curl xxd file git kmod bc gpg pigz arch-test
bash build-image.sh
```

Find the compressed image and checksum in `dist/`. The build uses an official [pi-gen](https://github.com/RPi-Distro/pi-gen) release and a pinned revision of the TONE3000 FX fork. The patches in this repo add phone-first login and kiosk shutdown handling. Build output is separate from both source repositories.

## Preview verification

- Boot a fresh card with a USB interface. Confirm the logo appears without setup prompts, the app fills the display, and its settings remain accessible. Repeat with a layout chosen through `configure-keyboard.ps1` and verify layout-specific keys.
- From the Settings and Login menu, export a test bank to a USB drive and import it again. Confirm the kiosk mounts the drive without a password prompt and replaces matching presets in the correct bank.
- Sign in on a phone. Approve the login and check online browsing in the app. Reboot and confirm the account is still signed in.
- Open **Clean Trem and Verb** and adjust the tremolo or reverb. Open **Shut down Pi…** and cancel once, then confirm a second time. Boot and check the changed value, preset file, interface, channels and buffer size. Also verify shutdown using the physical power button.
- Listen at your intended buffer size through at least one autosave. Boot again with networking disconnected to check offline playback.

## Credits and source

The image uses [Raspberry Pi OS and pi-gen](https://github.com/RPi-Distro/pi-gen), [Plymouth](https://gitlab.freedesktop.org/plymouth/plymouth), [labwc](https://github.com/labwc/labwc), [JUCE](https://github.com/juce-framework/JUCE), [Neural Amp Modeler](https://github.com/sdatkinson/NeuralAmpModelerCore), [Guitarix and its pedal artwork](https://github.com/brummer10/guitarix), and the [TONE3000 plugin](https://github.com/tone-3000/tone3000-plugin). The [app fork](https://github.com/scullcom/tone3000-pi-fx) carries the factory preset and its model attribution. The package license notices are included in the image under `/usr/share/doc`.
