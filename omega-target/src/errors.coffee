# These classes extend the built-in Error through CoffeeScript's ES5 class
# emulation, which calls `Error.call(this, ...)`. The built-in Error
# constructor ignores the `this` it is given and returns a fresh object, so
# nothing is assigned: every one of these errors used to carry an empty
# `message` and a stack reading "(No stack trace)". That is what ends up in
# the stored log, in the log exported from the context menu, and in the issue
# body pre-filled by "Report issues" - so a failure reported there said only
# which class it was, never what happened.
#
# Assign `message` and a real stack explicitly instead. The options page picks
# its user-facing text from `name` and `statusCode` via localized strings, so
# it is unaffected by what is written here; this is for logs and debugging.

captureStack = (self) ->
  if typeof Error.captureStackTrace == 'function'
    Error.captureStackTrace(self, self.constructor)
  else if not self.stack
    self.stack = "#{self.name}: #{self.message}"
  return

# Build a message from whatever the cause turned out to be. Causes come in
# three shapes here: a real Error (a rejected fetch), a plain object carrying
# the HTTP status (see fetch_url), or nothing at all.
#
# Deliberately does not include the requested URL, even when the cause has
# one: these messages are written to a log that can be exported and pasted
# into a public issue, and the URL of a rule list can be an internal host.
# It stays available on `.cause.url` for callers that want it.
describeError = (self) ->
  parts = []
  parts.push("HTTP #{self.statusCode}") if self.statusCode
  cause = self.cause
  if typeof cause == 'string'
    parts.push(cause) if cause
  else if cause?.message
    parts.push(cause.message)
  return self.name unless parts.length > 0
  return parts.join(': ')

class NetworkError extends Error
  constructor: (err) ->
    super
    this.cause = err
    this.name = 'NetworkError'
    this.message = describeError(this)
    captureStack(this)

class HttpError extends NetworkError
  constructor: ->
    super
    this.statusCode = this.cause?.statusCode
    this.name = 'HttpError'
    this.message = describeError(this)

class HttpNotFoundError extends HttpError
  constructor: ->
    super
    this.name = 'HttpNotFoundError'
    this.message = describeError(this)

class HttpServerError extends HttpError
  constructor: ->
    super
    this.name = 'HttpServerError'
    this.message = describeError(this)

# Raised when a URL carrying custom request headers redirects. Those headers
# usually hold credentials, and the browser forwards everything except
# Authorization across origins, so the redirect is refused rather than
# followed. It gets its own class so the options page can explain that,
# instead of reporting a generic network failure.
class RedirectRefusedError extends NetworkError
  constructor: ->
    super
    this.name = 'RedirectRefusedError'
    this.message = describeError(this)

class ContentTypeRejectedError extends Error
  constructor: (message) ->
    super
    this.name = 'ContentTypeRejectedError'
    this.message = message or this.name
    captureStack(this)

module.exports =
  NetworkError: NetworkError
  HttpError: HttpError
  HttpNotFoundError: HttpNotFoundError
  HttpServerError: HttpServerError
  RedirectRefusedError: RedirectRefusedError
  ContentTypeRejectedError: ContentTypeRejectedError
