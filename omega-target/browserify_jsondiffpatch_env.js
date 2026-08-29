// Browserify transform that keeps jsondiffpatch on its browser code path
// inside an MV3 service worker.
//
// jsondiffpatch decides whether it is in a browser by looking for a global
// `window`. A service worker has none, so jsondiffpatch takes its Node
// branch and calls `require('../package.json')` through a computed name that
// browserify cannot resolve. That throws "Cannot find module
// '../package.json'" at import time, which aborts the importScripts() chain
// in background_sw.js and leaves the entire background script unloaded - the
// extension then does nothing at all.
//
// A worker that has importScripts is a browser for jsondiffpatch's purposes,
// so widen the check. This used to be patched by hand in the built bundle,
// which meant any rebuild from source silently reintroduced the breakage.

var stream = require('stream');

var TARGET = /jsondiffpatch[\/\\]src[\/\\]environment\.js$/;

var REPLACEMENT = "exports.isBrowser = typeof window !== 'undefined' || " +
  "(typeof self !== 'undefined' && " +
  "typeof self.importScripts !== 'undefined');\n";

module.exports = function (file) {
  if (!TARGET.test(file)) {
    return new stream.PassThrough();
  }
  return new stream.Transform({
    transform: function (chunk, encoding, callback) {
      callback();
    },
    flush: function (callback) {
      this.push(REPLACEMENT);
      callback();
    }
  });
};
