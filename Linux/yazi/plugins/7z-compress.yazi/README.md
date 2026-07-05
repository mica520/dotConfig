# 7z Plugin for Yazi

A comprehensive plugin for Yazi that adds 7z archive support for both **peeking** (viewing archive contents) and **creating** compressed archives.

## Features

- 📦 **View archive contents** - Peek inside 7z, zip, and tar archives without extracting
- 🔐 **Password protection** - Create password-protected 7z and zip archives with AES-256 encryption
- 📊 **Compression levels** - Choose compression ratios (0-9) for 7z and zip formats
- 📁 **Multiple formats** - Supports 7z, zip, and tar archive creation
- 🖱️ **Selection support** - Compress single files, directories, or multiple selected items

## Installation

using `ya pkg`:

```bash
ya pkg add mica520/7z-compress
```

## Dependencies

- **7z** (p7zip or p7zip-full) - Must be installed and available in PATH

## Usage

### Peeking into Archives

When you hover over an archive file (`.7z`, `.zip`, `.tar`), the preview pane will automatically show its contents using `7z l`.

### Creating Archives

The plugin provides an interactive archive creation wizard. To use it, add a keybinding to your `keymap.toml`:

```toml
[[manager.prepend]]
on = "c"  # or any key you prefer
run = "plugin 7z-compress"
```

## License

MIT License

## Acknowledgments

- Built for [Yazi](https://github.com/sxyazi/yazi) file manager
- Uses [7-Zip](https://www.7-zip.org/) for archive operations
