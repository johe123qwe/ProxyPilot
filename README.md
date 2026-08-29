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
5. Click **Load unpacked** and select the unzipped folder.

*Note: ProxyPilot will soon be available directly on the Chrome Web Store.*

## 🔨 Building from source

The built extension is **not** kept in this repository — it is generated from
the sources. Cloning the repo alone will not give you a folder you can load
into Chrome; build it first, or just download the zip from the Releases page.

You need [Node.js](https://nodejs.org/) and two global CLI tools:

```bash
npm install -g grunt-cli bower
```

Then, from the root of the repository:

```bash
for m in omega-pac omega-target omega-web omega-target-chromium-extension; do
  (cd "$m" && npm install)
done
(cd omega-web && bower install)
```

Build every module, in this order — later modules consume the output of
earlier ones:

```bash
for m in omega-pac omega-target omega-web omega-target-chromium-extension; do
  (cd "$m" && grunt)
done
```

This produces `omega-target-chromium-extension/build`, which is the folder to
pick with **Load unpacked**.

To produce a release zip instead:

```bash
(cd omega-target-chromium-extension && grunt release)
```

The zip is written to `omega-target-chromium-extension/release.zip`. Note that
this is the Chrome Web Store variant: it drops the `downloads` permission, so
"Error log" in the toolbar context menu opens the log in a tab rather than
saving a file. The zips attached to the Releases page are packed from `build`
directly and keep that permission.

### Running the tests

```bash
(cd omega-pac && npm test)
(cd omega-target && npm test)
```

Three `TimeCondition` failures in `omega-pac` are expected on current Node
versions: the tests construct URLs like `http://time-00:00:00/`, which Node
now rejects as having an invalid port. They are unrelated to the extension.

## 📄 License

ProxyPilot is free software licensed under the **GNU General Public License v3.0**. It is a fork based on the incredible work by FelisCatus and the SwitchyOmega contributors.
