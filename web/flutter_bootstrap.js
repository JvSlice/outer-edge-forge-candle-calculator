{{flutter_js}}
{{flutter_build_config}}

// Keep CanvasKit and Skwasm on this app's origin so offline launches work.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href,
  },
});
