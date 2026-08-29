// Right after a cold start (browser/profile launch), the service worker may
// still be waking up, or Chrome may have failed to start it and marked it
// invalid, refusing to wake it again for a short while - sendMessage then
// fails with "Receiving end does not exist" and, without a retry, whatever
// we tried to tell the background page (e.g. the profile the user just
// picked) is silently dropped. Retry a few times with a small backoff to
// ride out the ordinary wake-up race, and retry that specific error for
// much longer with an exponential backoff before giving up.
var SEND_MESSAGE_MAX_ATTEMPTS = 5;
var SEND_MESSAGE_MAX_WORKER_DOWN_ATTEMPTS = 9;

function sendMessageWithRetry(message, attempt, cb) {
  chrome.runtime.sendMessage(message, function(response) {
    var err = chrome.runtime.lastError;
    if (err != null) {
      var workerDown =
        err.message && err.message.indexOf('Receiving end does not exist') >= 0;
      var maxAttempts =
        workerDown ? SEND_MESSAGE_MAX_WORKER_DOWN_ATTEMPTS :
          SEND_MESSAGE_MAX_ATTEMPTS;
      if (attempt < maxAttempts) {
        var delay = (workerDown && attempt > SEND_MESSAGE_MAX_ATTEMPTS) ?
          2000 * Math.pow(2, attempt - SEND_MESSAGE_MAX_ATTEMPTS - 1) :
          100 * attempt;
        setTimeout(function() {
          sendMessageWithRetry(message, attempt + 1, cb);
        }, delay);
        return;
      }
      return cb(err);
    }
    return cb(null, response);
  });
}

function callBackgroundNoReply(method, args, cb) {
  // Fire-and-forget messages don't wait for background processing, so keep
  // closing the popup etc. immediately as before - but still retry the
  // delivery itself in the background, so a cold-start service worker
  // doesn't silently swallow the action.
  sendMessageWithRetry({
    method: method,
    args: args,
    noReply: true,
    refreshActivePage: true,
  }, 1, function() {});
  if (cb) return cb();
}

function callBackground(method, args, cb) {
  sendMessageWithRetry({
    method: method,
    args: args,
  }, 1, function(err, response) {
    if (err != null) return cb && cb(err)
    if (response.error) return cb && cb(response.error)
    return cb && cb(null, response.result)
  });
}

var requestInfoCallback = null;

OmegaTargetPopup = {
  getState: function (keys, cb) {
    // In MV3, the Service Worker writes state to chrome.storage.local,
    // not localStorage. Always go through callBackground to read from
    // chrome.storage.local via the Service Worker.
    callBackground('getState', [keys], cb);
  },
  applyProfile: function (name, cb) {
    callBackgroundNoReply('applyProfile', [name], cb);
  },
  openOptions: function (hash, cb) {
    var options_url = chrome.runtime.getURL('options.html');

    chrome.tabs.query({
      url: options_url
    }, function(tabs) {
      if (!chrome.runtime.lastError && tabs && tabs.length > 0) {
        var props = {
          active: true
        };
        if (hash) {
          var url = options_url + hash;
          props.url = url;
        }
        chrome.tabs.update(tabs[0].id, props);
      } else {
        chrome.tabs.create({
          url: options_url
        });
      }
      if (cb) return cb();
    });
  },
  getActivePageInfo: function(cb) {
    chrome.tabs.query({active: true, lastFocusedWindow: true}, function (tabs) {
      if (tabs.length === 0 || !tabs[0].url) return cb();
      var args = {tabId: tabs[0].id, url: tabs[0].url};
      callBackground('getPageInfo', [args], cb)
    });
  },
  setDefaultProfile: function(profileName, defaultProfileName, cb) {
    callBackgroundNoReply('setDefaultProfile',
      [profileName, defaultProfileName], cb);
  },
  addTempRule: function(domain, profileName, cb) {
    callBackgroundNoReply('addTempRule', [domain, profileName], cb);
  },
  openManage: function(domain, profileName, cb) {
    chrome.tabs.create({
      url: 'chrome://extensions/?id=' + chrome.runtime.id,
    }, cb);
  },
  getMessage: chrome.i18n.getMessage.bind(chrome.i18n),
};
