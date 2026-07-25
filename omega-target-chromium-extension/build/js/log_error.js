(function() {
  var globalObj;

  globalObj = typeof window !== 'undefined' ? window : self;

  globalObj.onerror = function(message, url, line, col, err) {
    var content, _ref;
    content = '';
    if (err != null ? err.stack : void 0) {
      content += err.stack + '\n\n';
    } else {
      content += "" + url + ":" + line + ":" + col + ":\t" + message + "\n\n";
    }
    if (typeof chrome !== 'undefined' && ((_ref = chrome.storage) != null ? _ref.local : void 0)) {
      chrome.storage.local.get('log', function(res) {
        var log;
        log = (res.log || '') + content;
        if (log.length > 10000) {
          log = log.slice(-10000);
        }
        return chrome.storage.local.set({
          log: log
        });
      });
    }
  };

}).call(this);
