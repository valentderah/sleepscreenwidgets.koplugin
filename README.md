English | [Русский](README.ru.md)

# Sleepscreen widgets

A [KOReader](https://github.com/koreader/koreader) plugin that enhances the standard sleep screen with a customisable grid of iOS-style widgets.

![Sleep screen grid on an e-reader: date and time, current book, quote, calendar, and activity widgets](assets/screenshot-sleep-grid.png)

## Features

### Widget types

- **Date & time** — Shows the current date and time; the date is frozen at the moment the device goes to sleep.
- **Clock** — Digital or analog dial.
- **Battery** — Card with battery charge level.
- **Current book** — Title, author, progress, and estimated reading time remaining.
- **Random quote** — A random saved quote from the current book.
- **Calendar** — Month grid or today-only day view.

## Configuring KOReader

1. Enable **Settings** → **Screen** → **Sleep screen** → **Sleep screen message** → **Add custom message to sleep screen**.

2. Open **Container and position** and choose **Banner**, not **Box**.

If any of this is not set up, KOReader will show the usual sleep message instead of the grid.

## Configuring the plugin

After enabling the plugin in **Plugin management**, you can configure it under **Screen → Screensaver → Sleepscreen widgets**.

### Available options

- **Free placement and width** — You can choose both the row and how wide each widget is.
- **Light and dark themes** — Many widgets include **Card theme**: **Light** or **Dark**, so cards stay readable on different sleep-screen backgrounds.
- **Global settings** — Corner radius, spacing between grid cells, and how the grid is positioned relative to the screen edges.

## Installation

1. Copy the plugin folder into KOReader’s `plugins` directory, for example:  
   `koreader/plugins/sleepscreenwidgets.koplugin/`
2. Restart KOReader and enable the plugin in the menu.
