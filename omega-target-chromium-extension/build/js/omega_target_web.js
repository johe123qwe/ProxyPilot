(function() {
  var __slice = [].slice,
    __hasProp = {}.hasOwnProperty;

  angular.module('omegaTarget', []).factory('omegaTarget', function($q) {
    var callBackground, callBackgroundNoReply, connectBackground, decodeError, isChromeUrl, maxAttempts, maxWorkerDownAttempts, omegaTarget, optionsChangeCallback, prefix, requestInfoCallback, sendMessageWithRetry, urlParser;
    decodeError = function(obj) {
      var err;
      if (obj._error === 'error') {
        err = new Error(obj.message);
        err.name = obj.name;
        err.stack = obj.stack;
        err.original = obj.original;
        return err;
      } else {
        return obj;
      }
    };
    maxAttempts = 5;
    maxWorkerDownAttempts = 9;
    sendMessageWithRetry = function(message, attempt, cb) {
      return chrome.runtime.sendMessage(message, function(response) {
        var delay, err, max, workerDown, _ref;
        err = chrome.runtime.lastError;
        if (err != null) {
          workerDown = ((_ref = err.message) != null ? _ref.indexOf('Receiving end does not exist') : void 0) >= 0;
          max = workerDown ? maxWorkerDownAttempts : maxAttempts;
          if (attempt < max) {
            delay = workerDown && attempt > maxAttempts ? 2000 * Math.pow(2, attempt - maxAttempts - 1) : 100 * attempt;
            setTimeout((function() {
              return sendMessageWithRetry(message, attempt + 1, cb);
            }), delay);
            return;
          }
          if (typeof cb === "function") {
            cb(err);
          }
          return;
        }
        return typeof cb === "function" ? cb(null, response) : void 0;
      });
    };
    callBackgroundNoReply = function() {
      var args, method;
      method = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return sendMessageWithRetry({
        method: method,
        args: args,
        noReply: true
      }, 1, null);
    };
    callBackground = function() {
      var args, d, method;
      method = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      d = $q['defer']();
      sendMessageWithRetry({
        method: method,
        args: args
      }, 1, function(err, response) {
        if (err != null) {
          d.reject(err);
          return;
        }
        if (response.error) {
          return d.reject(decodeError(response.error));
        } else {
          return d.resolve(response.result);
        }
      });
      return d.promise;
    };
    connectBackground = function(name, message, callback) {
      var onDisconnect, port;
      port = chrome.runtime.connect({
        name: name
      });
      onDisconnect = function() {
        port.onDisconnect.removeListener(onDisconnect);
        return port.onMessage.removeListener(callback);
      };
      port.onDisconnect.addListener(onDisconnect);
      port.postMessage(message);
      port.onMessage.addListener(callback);
    };
    isChromeUrl = function(url) {
      return url.substr(0, 6) === 'chrome' || url.substr(0, 4) === 'moz-' || url.substr(0, 6) === 'about:';
    };
    optionsChangeCallback = [];
    requestInfoCallback = null;
    prefix = 'omega.local.';
    urlParser = document.createElement('a');
    omegaTarget = {
      options: null,
      state: function(name, value) {
        var d, payload;
        d = $q['defer']();
        if (arguments.length === 1) {
          chrome.storage.local.get(null, function(items) {
            var getValue;
            getValue = function(key) {
              var raw;
              raw = items[prefix + key];
              try {
                return JSON.parse(raw);
              } catch (_error) {
                return raw;
              }
            };
            if (Array.isArray(name)) {
              return d.resolve(name.map(getValue));
            } else {
              return d.resolve(getValue(name));
            }
          });
        } else {
          payload = {};
          payload[prefix + name] = JSON.stringify(value);
          chrome.storage.local.set(payload, function() {
            return d.resolve(value);
          });
        }
        return d.promise;
      },
      lastUrl: function(url) {
        var name;
        name = 'web.last_url';
        if (url) {
          localStorage[prefix + name] = JSON.stringify(url);
          return url;
        } else {
          try {
            return JSON.parse(localStorage[prefix + name]);
          } catch (_error) {}
        }
      },
      addOptionsChangeCallback: function(callback) {
        return optionsChangeCallback.push(callback);
      },
      refresh: function(args) {
        return callBackground('getAll').then(function(opt) {
          var callback, _i, _len;
          omegaTarget.options = opt;
          for (_i = 0, _len = optionsChangeCallback.length; _i < _len; _i++) {
            callback = optionsChangeCallback[_i];
            callback(omegaTarget.options);
          }
          return args;
        });
      },
      renameProfile: function(fromName, toName) {
        return callBackground('renameProfile', fromName, toName).then(omegaTarget.refresh);
      },
      replaceRef: function(fromName, toName) {
        return callBackground('replaceRef', fromName, toName).then(omegaTarget.refresh);
      },
      optionsPatch: function(patch) {
        return callBackground('patch', patch).then(omegaTarget.refresh);
      },
      resetOptions: function(opt) {
        return callBackground('reset', opt).then(omegaTarget.refresh);
      },
      updateProfile: function(name, opt_bypass_cache) {
        return callBackground('updateProfile', name, opt_bypass_cache).then(function(results) {
          var key, value;
          for (key in results) {
            if (!__hasProp.call(results, key)) continue;
            value = results[key];
            results[key] = decodeError(value);
          }
          return results;
        }).then(omegaTarget.refresh);
      },
      getMessage: chrome.i18n.getMessage.bind(chrome.i18n),
      openOptions: function(hash) {
        var d, options_url;
        d = $q['defer']();
        options_url = chrome.extension.getURL('options.html');
        chrome.tabs.query({
          url: options_url
        }, function(tabs) {
          var props, url, _ref;
          url = hash ? (urlParser.href = ((_ref = tabs[0]) != null ? _ref.url : void 0) || options_url, urlParser.hash = hash, urlParser.href) : options_url;
          if (tabs.length > 0) {
            props = {
              active: true
            };
            if (hash) {
              props.url = url;
            }
            chrome.tabs.update(tabs[0].id, props);
          } else {
            chrome.tabs.create({
              url: url
            });
          }
          return d.resolve();
        });
        return d.promise;
      },
      applyProfile: function(name) {
        return callBackground('applyProfile', name);
      },
      applyProfileNoReply: function(name) {
        return callBackgroundNoReply('applyProfile', name);
      },
      addTempRule: function(domain, profileName) {
        return callBackground('addTempRule', domain, profileName);
      },
      getTempRules: function() {
        return callBackground('getTempRules');
      },
      removeTempRule: function(domain) {
        return callBackground('removeTempRule', domain);
      },
      clearTempRules: function() {
        return callBackground('clearTempRules');
      },
      addCondition: function(condition, profileName) {
        return callBackground('addCondition', condition, profileName);
      },
      addProfile: function(profile) {
        return callBackground('addProfile', profile).then(omegaTarget.refresh);
      },
      setDefaultProfile: function(profileName, defaultProfileName) {
        return callBackground('setDefaultProfile', profileName, defaultProfileName);
      },
      getActivePageInfo: function() {
        var clearBadge, d;
        clearBadge = true;
        d = $q['defer']();
        chrome.tabs.query({
          active: true,
          lastFocusedWindow: true
        }, function(tabs) {
          var args, _ref;
          if (!((_ref = tabs[0]) != null ? _ref.url : void 0)) {
            d.resolve(null);
            return;
          }
          args = {
            tabId: tabs[0].id,
            url: tabs[0].url
          };
          if (tabs[0].id && requestInfoCallback) {
            connectBackground('tabRequestInfo', args, requestInfoCallback);
          }
          return d.resolve(callBackground('getPageInfo', args));
        });
        return d.promise.then(function(info) {
          if (info != null ? info.url : void 0) {
            return info;
          } else {
            return null;
          }
        });
      },
      refreshActivePage: function() {
        var d;
        d = $q['defer']();
        chrome.tabs.query({
          active: true,
          lastFocusedWindow: true
        }, function(tabs) {
          if (tabs[0].url && !isChromeUrl(tabs[0].url)) {
            chrome.tabs.reload(tabs[0].id, {
              bypassCache: true
            });
          }
          return d.resolve();
        });
        return d.promise;
      },
      openManage: function() {
        return chrome.tabs.create({
          url: 'chrome://extensions/?id=' + chrome.runtime.id
        });
      },
      openShortcutConfig: function() {
        return chrome.tabs.create({
          url: 'chrome://extensions/configureCommands'
        });
      },
      setOptionsSync: function(enabled, args) {
        return callBackground('setOptionsSync', enabled, args);
      },
      resetOptionsSync: function(enabled, args) {
        return callBackground('resetOptionsSync');
      },
      setRequestInfoCallback: function(callback) {
        return requestInfoCallback = callback;
      }
    };
    return omegaTarget;
  });

}).call(this);
