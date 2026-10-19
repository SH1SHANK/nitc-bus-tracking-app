# BusTracker Showcase

This is a standalone static site. GitHub Actions publishes the contents of this directory to GitHub Pages; it does not build or modify the Flutter app.

## Add app screenshots

Place genuine screenshots supplied for the showcase in `assets/screens/`, then replace the branded visual panel in the “Inside BusTracker” section of `index.html` with those image references. The directory alone is not an automatic gallery. Do not use screenshots containing personal information or present a static capture as live bus data. The current page uses official branding and labeled feature illustrations until app captures are available.

## GitHub Pages

1. In the repository, open **Settings → Pages**.
2. Under **Build and deployment**, choose **GitHub Actions** as the source.
3. Push a change to `main` or run the **Deploy BusTracker Showcase** workflow manually.
4. The project site is served from `https://sh1shank.github.io/nitc-bus-tracking-app/`.
