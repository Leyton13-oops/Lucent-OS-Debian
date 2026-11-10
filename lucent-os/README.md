# Lucent OS

A real, installable Linux desktop: **Debian 13 + GNOME**, restyled to feel like a glass macOS,
with a built-in AI assistant, a browser, a file manager, a full app set and Windows app support.

| You asked for | What you get |
|---|---|
| Liquid-glass design, macOS-inspired | Floating translucent dock and top bar (Dash to Dock + Blur My Shell), WhiteSur theme with a glass Files sidebar, red/yellow/green window buttons on the left, glass wallpapers (light and dark), Inter font |
| Gemini-style AI built in | **Lucent Intelligence**, a glass assistant on **Super+I**. Runs a local model (Ollama) or a cloud model (Gemini, OpenAI, ...). Can open apps, switch dark/light, set volume, lock the screen, and summarize or rewrite whatever you copied |
| Browser, file explorer, more apps | Firefox, Files, Text Editor, Calculator, Terminal, Software store, LibreOffice, VLC, Calendar, Weather, Maps, Clocks, Disks, System Monitor and more |
| Run Windows apps | Wine and winetricks preinstalled (double-click a `.exe`), plus a one-click setup for Bottles and Steam (Proton) |
| A real OS | Boots on real hardware, installs to disk with a graphical installer, gets updates from Debian |

> **Status: untested on hardware.** I built this without being able to boot it. The pieces I could check
> (theme installers, desktop settings against the real extension schemas, all scripts, the assistant app) pass,
> but the full ISO build is yours to run first. Try it in a virtual machine before touching your real disk.

## Get it: pick one

### A. Build the ISO in the cloud (no Linux needed)
1. Create a free GitHub account and a new private repository.
2. Upload everything in this folder (keep the `.github` folder).
3. Open the **Actions** tab, choose **Build Lucent OS ISO**, press **Run workflow**.
4. In 30-60 minutes, download the ISO from the run's **Artifacts** (kept 7 days).

### B. Build the ISO yourself
On a Linux machine (or Windows with WSL2) with Docker and about 20 GB free:
```bash
./build-iso.sh docker
```
On a Debian 13 machine without Docker: `sudo ./build-iso.sh`. The ISO lands in `out/`.

### C. Convert an existing Debian 13 install
Install Debian 13 (trixie) with the GNOME desktop from debian.org, then:
```bash
sudo ./install-on-debian.sh
```
Log out and back in. This is the quickest way to try Lucent OS.

## Put it on a computer
1. Write the ISO to a USB stick with balenaEtcher or Rufus (DD mode).
2. Boot from the stick. If it will not boot, turn off Secure Boot in your firmware settings.
3. Try it live, then run **Install Lucent OS** from the dock (the installer icon). Back up your data first: installing alongside or over another system can erase it.
4. NVIDIA graphics: after installing, `sudo apt install nvidia-driver` and reboot.

## The AI assistant
Press **Super+I** (or click the sparkle in the dock). Press it again, or Esc, to close.

**Local and private (default):** open **Set up local AI** from the app grid. It installs Ollama and the
`gemma3:4b` model (a few GB). Use `lucent-ai-setup <model>` to choose a different model.

**Cloud model:** click the gear in the assistant to edit `~/.config/lucent/intelligence.json`. Any
OpenAI-compatible service works. For Google Gemini:
```json
{
  "base_url": "https://generativelanguage.googleapis.com/v1beta/openai/",
  "model": "<a model name your Gemini API key can use>",
  "api_key": "<your key from Google AI Studio>"
}
```
Commands that need no model: `open <app>`, `dark mode`, `light mode`, `volume 40`, `lock screen`.

## Windows apps
Open **Set up Windows apps** (or run `lucent-windows-setup`). It installs Bottles, and Steam if you want it.
Be realistic: Wine and Proton run a great many programs and games, but not everything. Software that needs a
Windows kernel driver, many anti-cheat games and Adobe Creative Cloud will not work. Check WineHQ AppDB or
ProtonDB first. For anything that will not run, a Windows virtual machine is the fallback.

## About the "liquid glass" look
Linux compositors cannot do Apple's lensing and refraction effects. This gets the closest honest
equivalent: live background blur, translucency, rounded floating dock, glassy sidebars and a soft sheen.
Switch light/dark everywhere with `lucent-appearance light|dark`, and tweak blur in the
**Blur my Shell** and **Dash to Dock** extension settings.

## Make it yours
* Rename the OS, version and ISO name: `overlay/usr/share/lucent/os.conf`
* Desktop defaults (dock, theme, shortcuts): `overlay/etc/dconf/db/local.d/00-lucent`
* Apps to include: `overlay/usr/share/lucent/packages-core.txt` (required) and `packages-extra.txt` (optional)
* The assistant: `overlay/usr/local/bin/lucent-intelligence` (plain Python and Qt)

"Lucent" is a placeholder name, chosen so it does not clash with the existing Aurora Linux distribution.

## Layout
```
overlay/            files copied into the OS (settings, scripts, wallpapers, the assistant)
iso/                live-build recipe for the installer ISO
build-iso.sh        builds the ISO
install-on-debian.sh  converts an existing Debian 13 install
.github/workflows/  cloud ISO build
```
