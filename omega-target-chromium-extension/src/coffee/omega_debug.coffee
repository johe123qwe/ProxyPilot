globalObj = if typeof window != 'undefined' then window else self
globalObj.OmegaDebug =
  getProjectVersion: ->
    chrome.runtime.getManifest().version
  getExtensionVersion: ->
    chrome.runtime.getManifest().version
  downloadLog: ->
    chrome.storage.local.get 'log', (res) ->
      log = res.log || ''
      filename = "OmegaLog_#{Date.now()}.txt"

      hasBlob = typeof Blob != 'undefined'
      hasURL = typeof URL != 'undefined'
      if hasBlob and hasURL and URL.createObjectURL?
        blob = new Blob [log], {type: "text/plain;charset=utf-8"}
        api = browser?.downloads || chrome?.downloads
        if api?.download?
          url = URL.createObjectURL(blob)
          api.download({url: url, filename: filename})
        else if typeof saveAs != 'undefined'
          saveAs(blob, filename)
      else
        url = "data:text/plain;charset=utf-8," + encodeURIComponent(log)
        if chrome?.downloads?.download?
          chrome.downloads.download({url: url, filename: filename})
        else if chrome?.tabs?.create?
          chrome.tabs.create({url: url})
  resetOptions: ->
    localStorage?.clear()
    chrome.storage.local.clear ->
      chrome.storage.local.set {'omega.local.syncOptions': '"conflict"'}, ->
        chrome.runtime.reload()
  reportIssue: ->
    url = 'https://github.com/johe123qwe/ProxyPilot/issues/new?title=&body='
    finalUrl = url
    try
      projectVersion = OmegaDebug.getProjectVersion()
      extensionVersion = OmegaDebug.getExtensionVersion()
      env =
        extensionVersion: extensionVersion
        projectVersion: extensionVersion
        userAgent: navigator.userAgent
      body = chrome.i18n.getMessage('popup_issueTemplate', [
        env.projectVersion, env.userAgent
      ])
      body ||= """
        \n\n
        <!-- Please write your comment ABOVE this line. -->
        ProxyPilot #{env.projectVersion}
        #{env.userAgent}
      """
      finalUrl = url + encodeURIComponent(body)
      chrome.storage.local.get 'logLastError', (res) ->
        err = res.logLastError
        if err
          body += "\n```\n#{err}\n```"
          finalUrl = (url + encodeURIComponent(body)).substr(0, 2000)
        chrome.tabs.create(url: finalUrl)
    catch e
      chrome.tabs.create(url: finalUrl)
