try {
  importScripts(
    "log_error.js",
    "omega_debug.js",
    "background_preload.js",
    "omega_pac.min.js",
    "omega_target.min.js",
    "omega_target_chromium_extension.min.js",
    "../img/icons/draw_omega.js",
    "background.js"
  );
} catch (e) {
  console.error("Failed to load scripts in Service Worker:", e);
}
