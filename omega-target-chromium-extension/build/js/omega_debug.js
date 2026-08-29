(function() {
  var globalObj;

  globalObj = typeof window !== 'undefined' ? window : self;

  globalObj.OmegaDebug = {
    getProjectVersion: function() {
      return chrome.runtime.getManifest().version;
    },
    getExtensionVersion: function() {
      return chrome.runtime.getManifest().version;
    },
    downloadLog: function() {
      return chrome.storage.local.get('log', function(res) {
        var api, blob, filename, hasBlob, hasURL, log, url, _ref, _ref1;
        log = res.log || '';
        filename = "OmegaLog_" + (Date.now()) + ".txt";
        hasBlob = typeof Blob !== 'undefined';
        hasURL = typeof URL !== 'undefined';
        if (hasBlob && hasURL && (URL.createObjectURL != null)) {
          blob = new Blob([log], {
            type: "text/plain;charset=utf-8"
          });
          api = (typeof browser !== "undefined" && browser !== null ? browser.downloads : void 0) || (typeof chrome !== "undefined" && chrome !== null ? chrome.downloads : void 0);
          if ((api != null ? api.download : void 0) != null) {
            url = URL.createObjectURL(blob);
            return api.download({
              url: url,
              filename: filename
            });
          } else if (typeof saveAs !== 'undefined') {
            return saveAs(blob, filename);
          }
        } else {
          url = "data:text/plain;charset=utf-8," + encodeURIComponent(log);
          if ((typeof chrome !== "undefined" && chrome !== null ? (_ref = chrome.downloads) != null ? _ref.download : void 0 : void 0) != null) {
            return chrome.downloads.download({
              url: url,
              filename: filename
            });
          } else if ((typeof chrome !== "undefined" && chrome !== null ? (_ref1 = chrome.tabs) != null ? _ref1.create : void 0 : void 0) != null) {
            return chrome.tabs.create({
              url: url
            });
          }
        }
      });
    },
    resetOptions: function() {
      if (typeof localStorage !== "undefined" && localStorage !== null) {
        localStorage.clear();
      }
      return chrome.storage.local.clear(function() {
        return chrome.storage.local.set({
          'omega.local.syncOptions': '"conflict"'
        }, function() {
          return chrome.runtime.reload();
        });
      });
    },
    reportIssue: function() {
      var body, e, env, extensionVersion, finalUrl, projectVersion, url;
      url = 'https://github.com/johe123qwe/ProxyPilot/issues/new?title=&body=';
      finalUrl = url;
      try {
        projectVersion = OmegaDebug.getProjectVersion();
        extensionVersion = OmegaDebug.getExtensionVersion();
        env = {
          extensionVersion: extensionVersion,
          projectVersion: extensionVersion,
          userAgent: navigator.userAgent
        };
        body = chrome.i18n.getMessage('popup_issueTemplate', [env.projectVersion, env.userAgent]);
        body || (body = "\n\n\n<!-- Please write your comment ABOVE this line. -->\nProxyPilot " + env.projectVersion + "\n" + env.userAgent);
        finalUrl = url + encodeURIComponent(body);
        return chrome.storage.local.get('logLastError', function(res) {
          var err;
          err = res.logLastError;
          if (err) {
            body += "\n```\n" + err + "\n```";
            finalUrl = (url + encodeURIComponent(body)).substr(0, 2000);
          }
          return chrome.tabs.create({
            url: finalUrl
          });
        });
      } catch (_error) {
        e = _error;
        return chrome.tabs.create({
          url: finalUrl
        });
      }
    }
  };

}).call(this);
