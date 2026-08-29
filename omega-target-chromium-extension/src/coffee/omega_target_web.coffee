angular.module('omegaTarget', []).factory 'omegaTarget', ($q) ->
  decodeError = (obj) ->
    if obj._error == 'error'
      err = new Error(obj.message)
      err.name = obj.name
      err.stack = obj.stack
      err.original = obj.original
      err
    else
      obj
  # Right after a cold start, the service worker may still be waking up, or
  # Chrome may have failed to start it and marked it invalid, refusing to
  # wake it again for a short while - sendMessage then fails with "Receiving
  # end does not exist" and, without a retry, the options page would hang
  # forever waiting for a response that never comes. Retry a few times with
  # a small backoff to ride out the ordinary wake-up race, and retry that
  # specific error for much longer with an exponential backoff before
  # giving up.
  maxAttempts = 5
  maxWorkerDownAttempts = 9
  sendMessageWithRetry = (message, attempt, cb) ->
    chrome.runtime.sendMessage message, (response) ->
      err = chrome.runtime.lastError
      if err?
        workerDown = err.message?.indexOf('Receiving end does not exist') >= 0
        max = if workerDown then maxWorkerDownAttempts else maxAttempts
        if attempt < max
          delay = if workerDown and attempt > maxAttempts
            2000 * Math.pow(2, attempt - maxAttempts - 1)
          else
            100 * attempt
          setTimeout((-> sendMessageWithRetry(message, attempt + 1, cb)),
            delay)
          return
        cb?(err)
        return
      cb?(null, response)

  callBackgroundNoReply = (method, args...) ->
    sendMessageWithRetry({
      method: method
      args: args
      noReply: true
    }, 1, null)
  callBackground = (method, args...) ->
    d = $q['defer']()
    sendMessageWithRetry({
      method: method
      args: args
    }, 1, (err, response) ->
      if err?
        d.reject(err)
        return
      if response.error
        d.reject(decodeError(response.error))
      else
        d.resolve(response.result)
    )
    return d.promise
  connectBackground = (name, message, callback) ->
    port = chrome.runtime.connect({name: name})
    onDisconnect = ->
      port.onDisconnect.removeListener(onDisconnect)
      port.onMessage.removeListener(callback)
    port.onDisconnect.addListener(onDisconnect)

    port.postMessage(message)
    port.onMessage.addListener(callback)
    return

  isChromeUrl = (url) -> url.substr(0, 6) == 'chrome' or
    url.substr(0, 4) == 'moz-' or url.substr(0, 6) == 'about:'

  optionsChangeCallback = []
  requestInfoCallback = null
  prefix = 'omega.local.'
  urlParser = document.createElement('a')
  omegaTarget =
    options: null
    state: (name, value) ->
      d = $q['defer']()
      if arguments.length == 1
        chrome.storage.local.get null, (items) ->
          getValue = (key) ->
            raw = items[prefix + key]
            try JSON.parse(raw) catch then raw
          if Array.isArray(name)
            d.resolve(name.map(getValue))
          else
            d.resolve(getValue(name))
      else
        payload = {}
        payload[prefix + name] = JSON.stringify(value)
        chrome.storage.local.set payload, ->
          d.resolve(value)
      return d.promise
    lastUrl: (url) ->
      name = 'web.last_url'
      if url
        localStorage[prefix + name] = JSON.stringify(url)
        url
      else
        try JSON.parse(localStorage[prefix + name])
    addOptionsChangeCallback: (callback) ->
      optionsChangeCallback.push(callback)
    refresh: (args) ->
      return callBackground('getAll').then (opt) ->
        omegaTarget.options = opt
        for callback in optionsChangeCallback
          callback(omegaTarget.options)
        return args
    renameProfile: (fromName, toName) ->
      callBackground('renameProfile', fromName, toName).then omegaTarget.refresh
    replaceRef: (fromName, toName) ->
      callBackground('replaceRef', fromName, toName).then omegaTarget.refresh
    optionsPatch: (patch) ->
      callBackground('patch', patch).then omegaTarget.refresh
    resetOptions: (opt) ->
      callBackground('reset', opt).then omegaTarget.refresh
    updateProfile: (name, opt_bypass_cache) ->
      callBackground('updateProfile', name, opt_bypass_cache).then((results) ->
        for own key, value of results
          results[key] = decodeError(value)
        results
      ).then omegaTarget.refresh
    getMessage: chrome.i18n.getMessage.bind(chrome.i18n)
    openOptions: (hash) ->
      d = $q['defer']()
      options_url = chrome.extension.getURL('options.html')
      chrome.tabs.query url: options_url, (tabs) ->
        url = if hash
          urlParser.href = tabs[0]?.url || options_url
          urlParser.hash = hash
          urlParser.href
        else
          options_url
        if tabs.length > 0
          props = {active: true}
          if hash
            props.url = url
          chrome.tabs.update(tabs[0].id, props)
        else
          chrome.tabs.create({url: url})
        d.resolve()
      return d.promise
    applyProfile: (name) ->
      callBackground('applyProfile', name)
    applyProfileNoReply: (name) ->
      callBackgroundNoReply('applyProfile', name)
    addTempRule: (domain, profileName) ->
      callBackground('addTempRule', domain, profileName)
    getTempRules: ->
      callBackground('getTempRules')
    removeTempRule: (domain) ->
      callBackground('removeTempRule', domain)
    clearTempRules: ->
      callBackground('clearTempRules')
    addCondition: (condition, profileName) ->
      callBackground('addCondition', condition, profileName)
    addProfile: (profile) ->
      callBackground('addProfile', profile).then omegaTarget.refresh
    setDefaultProfile: (profileName, defaultProfileName) ->
      callBackground('setDefaultProfile', profileName, defaultProfileName)
    getActivePageInfo: ->
      clearBadge = true
      d = $q['defer']()
      chrome.tabs.query {active: true, lastFocusedWindow: true}, (tabs) ->
        if not tabs[0]?.url
          d.resolve(null)
          return
        args = {tabId: tabs[0].id, url: tabs[0].url}
        if tabs[0].id and requestInfoCallback
          connectBackground('tabRequestInfo', args,
            requestInfoCallback)
        d.resolve(callBackground('getPageInfo', args))
      return d.promise.then (info) -> if info?.url then info else null
    refreshActivePage: ->
      d = $q['defer']()
      chrome.tabs.query {active: true, lastFocusedWindow: true}, (tabs) ->
        if tabs[0].url and not isChromeUrl(tabs[0].url)
          chrome.tabs.reload(tabs[0].id, {bypassCache: true})
        d.resolve()
      return d.promise
    openManage: ->
      chrome.tabs.create url: 'chrome://extensions/?id=' + chrome.runtime.id
    openShortcutConfig: ->
      chrome.tabs.create url: 'chrome://extensions/configureCommands'
    setOptionsSync: (enabled, args) ->
      callBackground('setOptionsSync', enabled, args)
    resetOptionsSync: (enabled, args) -> callBackground('resetOptionsSync')
    setRequestInfoCallback: (callback) ->
      requestInfoCallback = callback

  return omegaTarget
