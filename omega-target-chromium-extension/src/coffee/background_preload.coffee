globalObj = if typeof window != 'undefined' then window else self
globalObj.UglifyJS_NoUnsafeEval = true

globalObj.OmegaContextMenuQuickSwitchHandler = -> null

if chrome.contextMenus?
  # We don't need this API. However its presence indicates that Chrome >= 35
  # which provides info.checked we need in contextMenu callback.
  # https://developer.chrome.com/extensions/contextMenus
  if chrome.i18n.getUILanguage?
    # We must create the menu item here before others to make it first in menu.
    chrome.contextMenus.create({
      id: 'enableQuickSwitch'
      title: chrome.i18n.getMessage('contextMenu_enableQuickSwitch')
      type: 'checkbox'
      checked: false
      contexts: ["action"]
    })

  chrome.contextMenus.create({
    id: 'reportIssues'
    title: chrome.i18n.getMessage('popup_reportIssues')
    contexts: ["action"]
  })

  chrome.contextMenus.create({
    id: 'errorLog'
    title: chrome.i18n.getMessage('popup_errorLog')
    contexts: ["action"]
  })

  chrome.contextMenus.onClicked.addListener (info, tab) ->
    switch info.menuItemId
      when 'enableQuickSwitch'
        globalObj.OmegaContextMenuQuickSwitchHandler(info)
      when 'reportIssues'
        globalObj.OmegaDebug?.reportIssue()
      when 'errorLog'
        globalObj.OmegaDebug?.downloadLog()
