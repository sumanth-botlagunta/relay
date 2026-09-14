# Relay — choose where your Mac opens links

**One link. Your choice of browser.** Relay is a free Mac app that lets you choose Safari, Chrome, another installed browser, or a Chrome profile whenever you open a link from email, chat, or a document.

[![Latest release](https://img.shields.io/github/v/release/sumanth-botlagunta/relay)](https://github.com/sumanth-botlagunta/relay/releases/latest)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-black)
![Apple Silicon](https://img.shields.io/badge/Mac-Apple%20Silicon-blue)

[**Download Relay for Mac →**](https://github.com/sumanth-botlagunta/relay/releases/latest) · [See the app](docs/GALLERY.md) · [Installation help](docs/INSTALL.md)

<p align="center">
  <img src="docs/images/picker.png" alt="Relay browser picker showing Safari, Google Chrome, Incognito, and sample Personal and Work profiles with keyboard shortcuts" width="390">
</p>

## Try Relay

You need **macOS 15 Sequoia or later and a Mac with an Apple chip (M1 or newer)**. Intel Macs are not supported.

1. [Download the latest release](https://github.com/sumanth-botlagunta/relay/releases/latest) and choose the file ending in **apple-silicon.dmg**.
2. Open the download, drag **Relay** into **Applications**, then open Relay.
3. Choose **Settings → General → Make Default** and approve the macOS request.
4. Click a link in another app and choose where to open it. You can also try **Settings → Setup & Help → Test Picker**.

Relay lives in your **menu bar**, with no Dock icon. Open it again from Applications whenever you want to reach Settings.

**First launch:** Relay is an early release and has not yet been notarized by Apple. If macOS blocks it, follow the [first-launch instructions](docs/INSTALL.md#when-macos-blocks-the-first-launch) for a download you trust. Some work-managed Macs may not allow it.

## What can you do with it?

- **Keep work and personal browsing separate.** Pick your Work or Personal Chrome profile, or open a link in Chrome Incognito.
- **Remember familiar sites.** Always open a work site in your work browser, and leave other links up to you.
- **Choose with your keyboard.** Press a browser’s number, or use the arrow keys and Return.
- **Remove common tracking tags.** See the cleaned link before opening it, with the option to keep the original address.
- **Handle several links at once.** Work through waiting links, skip one, or dismiss them all with Escape.
- **Change your mind.** Hold Option while clicking to choose a browser even for a saved rule, or pause Relay from its menu.
- **Move an open tab.** Press Control–Option–B to send the current tab to another browser. If Relay cannot read the tab, it can use a link you copied.

## Take a look

| Inspect a cleaned link | Set up your preferences |
| --- | --- |
| <img src="docs/images/link-details.png" alt="Relay link details showing the cleaned example.com destination and an option to open the original URL with its tracking parameter" width="310"> | <img src="docs/images/settings.png" alt="Relay General settings with primary browser, launch at login, tracking cleanup, suspicious-link warnings, and keyboard shortcut controls" width="560"> |

[**View all seven interfaces in the full-resolution gallery →**](docs/GALLERY.md)

| Automate familiar sites | Handle several links |
| --- | --- |
| <img src="docs/images/rules.png" alt="Relay routing rules sending github.com to a sample Work Chrome profile, example.com to Safari, and example.org to Incognito" width="520"> | <img src="docs/images/link-queue.png" alt="Relay picker with three queued links, a waiting count, and Skip and dismiss-all controls" width="300"> |

Images show the actual app with sample links and profile names. Your available browsers and profiles will depend on your Mac.


## A few things to know

**Your choices stay on your Mac.** Relay needs no account and has no analytics or cloud service. Reading an open browser tab may ask for macOS Automation permission; choosing where a new link opens does not. [Read the privacy details](PRIVACY.md).

**Chrome has extra options.** Named profiles and Incognito choices are currently available for Chrome. Other browsers appear as regular destinations. Links clicked inside a browser may stay there; Relay handles links that other apps send to your default browser.

**Link warnings are a helpful check, not a safety guarantee.** Relay can flag some unusual addresses, but it cannot tell you whether every website is safe.

**Updates are manual for now.** Download a new release when you want to update. See [updating, troubleshooting, and uninstalling](docs/INSTALL.md).

## Need help or have an idea?

[Report a problem or suggest an improvement](https://github.com/sumanth-botlagunta/relay/issues/new/choose). Include your macOS version, Relay version, and browser, and use example links instead of private ones.

Relay is free and open source under the [MIT license](LICENSE). If you would like to help build it, start with [Contributing](CONTRIBUTING.md), the [architecture docs](docs/ARCHITECTURE.md), or the [roadmap](docs/ROADMAP.md).

Browser names and icons belong to their respective owners; no browser vendor endorsement is implied.
