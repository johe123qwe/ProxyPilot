globalObj = if typeof window != 'undefined' then window else self
globalObj.onerror = (message, url, line, col, err) ->
  content = ''
  if err?.stack
    content += err.stack + '\n\n'
  else
    content += "#{url}:#{line}:#{col}:\t#{message}\n\n"

  if typeof chrome != 'undefined' and chrome.storage?.local
    chrome.storage.local.get 'log', (res) ->
      log = (res.log || '') + content
      if log.length > 10000
        log = log.slice(-10000)
      chrome.storage.local.set({log: log})
  return
