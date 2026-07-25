(function() {
  var globalObj;

  globalObj = typeof window !== 'undefined' ? window : self;

  globalObj.UglifyJS_NoUnsafeEval = true;

  globalObj.OmegaContextMenuQuickSwitchHandler = function() {
    return null;
  };

  if (chrome.contextMenus != null) {
    if (chrome.i18n.getUILanguage != null) {
      chrome.contextMenus.create({
        id: 'enableQuickSwitch',
        title: chrome.i18n.getMessage('contextMenu_enableQuickSwitch'),
        type: 'checkbox',
        checked: false,
        contexts: ["action"]
      });
    }
    chrome.contextMenus.create({
      id: 'reportIssues',
      title: chrome.i18n.getMessage('popup_reportIssues'),
      contexts: ["action"]
    });
    chrome.contextMenus.create({
      id: 'errorLog',
      title: chrome.i18n.getMessage('popup_errorLog'),
      contexts: ["action"]
    });
    chrome.contextMenus.onClicked.addListener(function(info, tab) {
      var _ref, _ref1;
      switch (info.menuItemId) {
        case 'enableQuickSwitch':
          return globalObj.OmegaContextMenuQuickSwitchHandler(info);
        case 'reportIssues':
          return (_ref = globalObj.OmegaDebug) != null ? _ref.reportIssue() : void 0;
        case 'errorLog':
          return (_ref1 = globalObj.OmegaDebug) != null ? _ref1.downloadLog() : void 0;
      }
    });
  }

}).call(this);
