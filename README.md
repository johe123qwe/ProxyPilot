# ProxyPilot (formerly SwitchyOmega)

ProxyPilot is a modern, Manifest V3 (MV3) compatible fork of the popular proxy switching extension **SwitchyOmega**. 

## 🌟 Why ProxyPilot?

The original SwitchyOmega project is no longer actively maintained. With Google Chrome enforcing Manifest V3 and deprecating Manifest V2, the original extension has stopped working for many users. 

**ProxyPilot** was created to rescue this essential tool. We have fully refactored the extension to be MV3 compatible, fixing all API deprecations and background script issues while retaining the exact same powerful features and UI you know and love.

### What's Fixed in v3.0.0:
- **Full Manifest V3 Support**: Upgraded `manifest.json` and background scripts.
- **Fixed Profile Display Bug**: Resolved issues where newly created profiles wouldn't show up in the popup due to `localStorage` being unavailable in MV3 Service Workers.
- **Fixed Proxy Authentication**: Refactored `webRequest` blocking mode to use `asyncBlocking` along with the required `webRequestAuthProvider` permission (Chrome 120+).
- **Deprecated APIs Removed**: Migrated from `chrome.extension.getURL` to `chrome.runtime.getURL`.
- **Bug Fixes**: Addressed alarms listener registration bugs and removed dead code.

## 🚀 Installation

1. Go to the [Releases page](https://github.com/johe123qwe/ProxyPilot/releases) and download the latest `ProxyPilot-x.x.x.zip` file.
2. Unzip the downloaded file.
3. Open Chrome and navigate to `chrome://extensions/`.
4. Enable **Developer mode** in the top right corner.
5. Click **Load unpacked** and select the `build` directory (or the unzipped folder).

*Note: ProxyPilot will soon be available directly on the Chrome Web Store.*

## 📄 License

ProxyPilot is free software licensed under the **GNU General Public License v3.0**. It is a fork based on the incredible work by FelisCatus and the SwitchyOmega contributors.
