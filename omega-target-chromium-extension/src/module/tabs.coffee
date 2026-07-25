class ChromeTabs
  _defaultAction: null
  _badgeTab: null

  constructor: (@actionForUrl) ->
    @_dirtyTabs = {}
    return

  ignoreError: ->
    chrome.runtime.lastError
    return

  watch: ->
    chrome.tabs.onUpdated.addListener @onUpdated.bind(this)
    chrome.tabs.onActivated.addListener (info) =>
      chrome.tabs.get info.tabId, (tab) =>
        return if chrome.runtime.lastError
        if @_dirtyTabs.hasOwnProperty(info.tabId)
          @onUpdated tab.id, {}, tab

  resetAll: (action) ->
    @_defaultAction = action
    chrome.tabs.query {}, (tabs) =>
      @_dirtyTabs = {}
      tabs.forEach (tab) =>
        @_dirtyTabs[tab.id] = tab.id
        @onUpdated tab.id, {}, tab if tab.active
    actionApi = chrome.browserAction || chrome.action
    if actionApi?.setPopup?
      actionApi.setTitle({title: action.title})
    else
      actionApi?.setTitle?({title: action.shortTitle})
    @setIcon(action.icon)

  onUpdated: (tabId, changeInfo, tab) ->
    if @_dirtyTabs.hasOwnProperty(tab.id)
      delete @_dirtyTabs[tab.id]
    else if not changeInfo.url?
      if changeInfo.status? and changeInfo.status != 'loading'
        return
    @processTab(tab, changeInfo)

  processTab: (tab, changeInfo) ->
    if @_badgeTab
      for own id of @_badgeTab
        try
          actionApi = chrome.browserAction || chrome.action
          actionApi?.setBadgeText?(text: '', tabId: id)
        @_badgeTab = null

    if not tab.url? or tab.url.indexOf("chrome") == 0
      if @_defaultAction
        (chrome.browserAction || chrome.action)?.setTitle({
          title: @_defaultAction.title
          tabId: tab.id
        })
        @clearIcon tab.id
      return
    @actionForUrl(tab.url).then (action) =>
      if not action
        @clearIcon tab.id
        return
      @setIcon(action.icon, tab.id)
      actionApi = chrome.browserAction || chrome.action
      if actionApi?.setPopup?
        actionApi.setTitle({title: action.title, tabId: tab.id})
      else
        actionApi?.setTitle?({title: action.shortTitle, tabId: tab.id})

  setTabBadge: (tab, badge) ->
    @_badgeTab ?= {}
    @_badgeTab[tab.id] = true
    actionApi = chrome.browserAction || chrome.action
    actionApi?.setBadgeText?(text: badge.text, tabId: tab.id)
    actionApi?.setBadgeBackgroundColor?(
      color: badge.color
      tabId: tab.id
    )

  setIcon: (icon, tabId) ->
    return unless icon?
    if tabId?
      params = {
        imageData: icon
        tabId: tabId
      }
    else
      params = {
        imageData: icon
      }
    @_chromeSetIcon(params)

  _chromeSetIcon: (params) ->
    try
      (chrome.browserAction || chrome.action)?.setIcon?(params, @ignoreError)
    catch _
      # Some legacy Chrome versions will panic if there are other icon sizes.
      params.imageData = {19: params.imageData[19], 38: params.imageData[38]}
      (chrome.browserAction || chrome.action)?.setIcon?(params, @ignoreError)

  clearIcon: (tabId) ->
    return unless @_defaultAction?.icon?
    @_chromeSetIcon({
      imageData: @_defaultAction.icon
      tabId: tabId
    }, @ignoreError)

module.exports = ChromeTabs
