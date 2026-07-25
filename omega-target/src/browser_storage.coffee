Storage = require('./storage')
Promise = require('bluebird')

class BrowserStorage extends Storage
  constructor: (@storage, @prefix = '') ->
    # unused storage as we use chrome.storage.local now
    undefined

  get: (keys) ->
    new Promise (resolve) =>
      chrome.storage.local.get null, (items) =>
        map = {}
        if typeof keys == 'string'
          keysMap = {}
          keysMap[keys] = undefined
          keys = keysMap
        else if Array.isArray(keys)
          keysMap = {}
          for key in keys
            keysMap[key] = undefined
          keys = keysMap
        else if typeof keys != 'object'
          keys = {}
        
        for own key of keys
          raw = items[@prefix + key]
          if typeof raw == 'string'
            try
              value = JSON.parse(raw)
            catch
              value = raw
          else
            value = raw
          map[key] = value if value?
          if typeof map[key] == 'undefined' and typeof keys[key] != 'undefined'
            map[key] = keys[key]
        resolve map

  set: (items) ->
    new Promise (resolve) =>
      payload = {}
      for own key, value of items
        payload[@prefix + key] = JSON.stringify(value)
      chrome.storage.local.set payload, ->
        resolve items

  remove: (keys) ->
    new Promise (resolve) =>
      if not keys?
        if not @prefix
          chrome.storage.local.clear -> resolve()
        else
          chrome.storage.local.get null, (items) =>
            toRemove = []
            for own key of items
              if key.indexOf(@prefix) == 0
                toRemove.push(key)
            chrome.storage.local.remove toRemove, -> resolve()
      else
        if typeof keys == 'string'
          keys = [keys]
        toRemove = (@prefix + key for key in keys)
        chrome.storage.local.remove toRemove, -> resolve()

module.exports = BrowserStorage
