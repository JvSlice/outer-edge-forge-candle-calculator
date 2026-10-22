if ('serviceWorker' in navigator) {
  const hadController = Boolean(navigator.serviceWorker.controller);
  let reloading = false;

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (hadController && !reloading) {
      reloading = true;
      window.location.reload();
    }
  });

  window.addEventListener('load', async () => {
    const base = new URL(document.baseURI);
    try {
      const registration = await navigator.serviceWorker.register(
        new URL('sw.js', base),
        { scope: base.pathname, updateViaCache: 'none' },
      );
      await registration.update();
    } catch (error) {
      console.warn('OEF offline setup was not completed:', error);
    }
  });
}
