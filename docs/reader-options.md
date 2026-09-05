# Reader options

Research date: 2026-09-05. Goal: a polished Linux reader with a UI similar to
macOS Preview. No applications were installed during this research.

## Shortlist

- [Papers](https://apps.gnome.org/Papers/): document viewer with PDF search and
  annotations. Its official screenshots show a compact toolbar and document
  sidebar. This is the closest visual fit among the candidates inspected.
  Supports PDF, DjVu, TIFF, and comic archives; EPUB is not listed.
- [Readest](https://github.com/readest/readest): cross-platform reader using
  Tauri and Next.js. Lists PDF and EPUB support, notes, highlights, and parallel
  reading. Its official screenshots show a reading-focused interface and theme
  controls, including Gruvbox. It is closer to an ebook application than Preview.
- [Koodo Reader](https://github.com/koodo-reader/koodo-reader): supports Linux,
  PDF, and EPUB. Offers library management and reading customization. The
  official reading screenshot shows minimal controls and a floating annotation
  toolbar. Its website distinguishes Free and Pro offerings; check the current
  terms before choosing it for sync or other services.
- [PDF4QT](https://jakubmelka.github.io/screenshots/): offers PDF editing,
  annotations, forms, page organization, and document comparison. Its feature
  set addresses more editing tasks, but that alone does not establish a match
  for the requested UI.

## Visual evidence

These are upstream screenshots, not locally tested applications:

- [Papers document view](https://static.gnome.org/catalog/app-screenshot/org.gnome.Papers/image-1_orig.png)
- [Readest theme panel](https://raw.githubusercontent.com/readest/readest/main/data/screenshots/theming_dark_mode.png)
- [Koodo reading view](https://dl.koodoreader.com/screenshots/5.png)

The three screenshots above were inspected. Visual similarity is a judgment,
not evidence of matching performance, interactions, or Preview feature parity.

## Nix availability

The repository's pinned nixpkgs contains the following packages. Versions were
read from their `pkgs/by-name` package definitions, not inferred from upstream
release pages:

| Package        | Pinned version |
| -------------- | -------------- |
| `papers`       | 50.2           |
| `readest`      | 0.12.1         |
| `koodo-reader` | 2.3.4          |
| `pdf4qt`       | 1.5.2.0        |

Recommendation: assess Papers for opening PDFs directly and Readest for books
before building a custom interface. Neither is established here as a complete
replacement for Preview's combined image and PDF editing workflow.
