{{flutter_js}}
{{flutter_build_config}}

// Remove the instant CSS splash screen once Flutter has initialized its engine
const splash = document.getElementById("pin-splash");

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      if (splash) {
        splash.classList.add("pin-splash-fade-out");
        setTimeout(function() {
          if (splash && splash.parentNode) {
            splash.parentNode.removeChild(splash);
          }
        }, 350);
      }
      await appRunner.runApp();
    } catch (err) {
      console.error("Flutter engine initialization error:", err);
      if (splash) {
        const errorText = document.getElementById("pin-splash-error");
        if (errorText) {
          errorText.style.display = "block";
          errorText.textContent = "Failed to load board. Please refresh the page.";
        }
      }
    }
  }
});
