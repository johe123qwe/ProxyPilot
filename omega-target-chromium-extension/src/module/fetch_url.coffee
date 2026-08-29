Promise = OmegaTarget.Promise
Url = require('url')
ContentTypeRejectedError = OmegaTarget.ContentTypeRejectedError

# An MV3 service worker has no XMLHttpRequest, so this uses fetch. Everything
# below still expects the [response, body] pair the old xhr-based transport
# resolved to, with response.headers as a plain lower-cased name-to-value map,
# so adapt fetch's Response to that shape rather than changing every caller.
responseShim = (response) ->
  headers = {}
  response.headers.forEach (value, name) ->
    headers[name.toLowerCase()] = value
  return {
    statusCode: response.status
    headers: headers
  }

# Errors carry only the status and the URL. Deliberately not the request
# headers: those can hold credentials for the rule list, and the error is
# handed to the options page and written to the stored log.
httpErrorCause = (response) ->
  return {statusCode: response.status, url: response.url}

fetchWrapper = (url, headers, opt_bypass_cache) ->
  hasCustomHeaders = headers and Object.keys(headers).length > 0

  init = {method: 'GET'}
  init.cache = 'no-store' if opt_bypass_cache
  init.headers = headers if hasCustomHeaders

  # Custom headers on a rule list or PAC URL are usually credentials. The
  # browser drops Authorization when a redirect crosses origins, but it
  # forwards every other header - so a URL that redirects elsewhere would hand
  # a header like X-Api-Key straight to whoever it points at. Refuse to follow
  # redirects at all while carrying custom headers, rather than leak them.
  init.redirect = if hasCustomHeaders then 'manual' else 'follow'

  Promise.resolve(fetch(url, init)).catch((err) ->
    # No response at all: DNS failure, connection refused, blocked, ...
    throw new OmegaTarget.NetworkError(err)
  ).then (response) ->
    if response.type == 'opaqueredirect' or (300 <= response.status < 400)
      throw redirectRefusedError()
    return fetchWrapperResponse(response)

# These error classes extend Error through CoffeeScript's ES5 class emulation,
# which does not carry `message` through super, so set it directly - here the
# explanation is the whole point of the error.
redirectRefusedError = ->
  message = "This URL redirects, and this profile sends custom request
    headers. Refusing to follow the redirect, so that the headers - which
    usually carry credentials - are not disclosed to the redirect target.
    Point the profile at the final URL instead."
  err = new OmegaTarget.NetworkError(new Error(message))
  err.message = message
  return err

fetchWrapperResponse = (response) ->
  # Not modified: a successful fetch with nothing to apply. Callers treat an
  # empty body as "no update".
  return [responseShim(response), ''] if response.status == 304
  if response.status == 404
    throw new OmegaTarget.HttpNotFoundError(httpErrorCause(response))
  if response.status >= 500 and response.status < 600
    throw new OmegaTarget.HttpServerError(httpErrorCause(response))
  if not response.ok
    throw new OmegaTarget.HttpError(httpErrorCause(response))
  Promise.resolve(response.text()).catch((err) ->
    throw new OmegaTarget.NetworkError(err)
  ).then (body) ->
    return [responseShim(response), body]

fetchUrl = (dest_url, headers, opt_bypass_cache, opt_type_hints) ->
  getResBody = ([response, body]) ->
    # 304 carries no body to sniff; an empty result means "nothing to update".
    return body if response.statusCode == 304
    return body unless opt_type_hints
    contentType = response.headers['content-type']?.toLowerCase()
    for hint in opt_type_hints
      handler = hintHandlers[hint] ? defaultHintHandler
      result = handler(response, body, {contentType, hint})
      return result if result?
    throw new ContentTypeRejectedError(
      'Unrecognized Content-Type: ' + contentType)
    return body

  if opt_bypass_cache and dest_url.indexOf('?') < 0
    parsed = Url.parse(dest_url, true)
    parsed.search = undefined
    parsed.query['_'] = Date.now()
    dest_url_nocache = Url.format(parsed)
    # Try first with the dumb parameter to bypass cache.
    fetchWrapper(dest_url_nocache, headers, opt_bypass_cache)
      .then(getResBody).catch ->
        # If failed, try again with the original URL.
        fetchWrapper(dest_url, headers, opt_bypass_cache).then(getResBody)
  else
    fetchWrapper(dest_url, headers, opt_bypass_cache).then(getResBody)

defaultHintHandler = (response, body, {contentType, hint}) ->
  if '!' + contentType == hint
    throw new ContentTypeRejectedError(
      'Response Content-Type blacklisted: ' + contentType)
  if contentType == hint
    return body

hintHandlers =
  '*': (response, body) ->
    # Allow all contents.
    return body

  '!text/html': (response, body, {contentType, hint}) ->
    if contentType == hint
      # Sometimes other content can also be served with the text/html
      # Content-Type header. So we check if the body actually looks like HTML.
      looksLikeHtml = false
      if body.indexOf('<!DOCTYPE') >= 0 || body.indexOf('<!doctype') >= 0
        looksLikeHtml = true
      else if body.indexOf('</html>') >= 0
        looksLikeHtml = true
      else if body.indexOf('</body>') >= 0
        looksLikeHtml = true

      if looksLikeHtml
        throw new ContentTypeRejectedError('Response must not be HTML.')

  '!application/xhtml+xml': (args...) -> hintHandlers['!text/html'](args...)

  'application/x-ns-proxy-autoconfig': (response, body, {contentType, hint}) ->
    if contentType == hint
      return body
    # Sometimes PAC scripts can also be served using with wrong Content-Type.
    if body.indexOf('FindProxyForURL') >= 0
      return body
    else
      # The content is not a PAC script if it does not contain FindProxyForURL.
      return undefined

module.exports = fetchUrl
