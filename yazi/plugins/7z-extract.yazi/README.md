# 7z Extract Plugin for Yazi

A Yazi plugin that provides robust extraction capabilities for archive files with password support and multi-file handling.

## Features

- 📦 **Multi-archive extraction** - Extract multiple selected archives at once
- 🔐 **Password support** - Automatically detects password-protected archives and prompts for password
- 📁 **Custom output directory** - Choose where to extract files
- 📊 **Progress tracking** - Shows extraction progress for multiple files
- 🖱️ **Selection support** - Works with single selection, hovered file, or multiple selected archives
- ⚡ **Non-blocking** - Uses `echo` to provide input, preventing 7z from hanging on password prompts

## Supported Formats

- `.7z`
- `.zip`
- `.rar`
- `.tar`
- `.gz`
- `.bz2`
- `.xz`
- `.tgz`
- `.tbz2`
- `.txz`
- `.zst`
- `.lz4`
- `.jar`
- `.war`

## Installation

Using `ya pkg`:

```bash
ya pkg add mica520/7z-extract
```

Or manually clone into your Yazi plugins directory:

```bash
git clone https://github.com/mica520/7z-extract.git ~/.config/yazi/plugins/7z-extract
```

## Dependencies

- **7z** (p7zip or p7zip-full) - Must be installed and available in PATH

## Usage

Add a keybinding to your `keymap.toml`:

```toml
[[manager.prepend]]
on = "x"  # or any key you prefer
run = "plugin 7z-extract"
```

### How it works

1. **Select archives** - Hover over an archive file or select multiple archives
2. **Choose destination** - Enter target directory (defaults to archive's parent folder)
3. **Enter password** - If password-protected archives are detected, you'll be prompted for a password
4. **Automatic extraction** - Archives are extracted with progress feedback

### Features in detail

#### Smart Password Detection

- Automatically checks each archive for password protection before extraction
- Only prompts once for password if multiple password-protected archives are selected
- Handles wrong passwords gracefully with error feedback

#### Multi-file Support

- Extracts multiple selected archives in sequence
- Shows progress for each file (e.g., "Progress: 2/5 - archive.7z")
- Reports success/failure summary with detailed file names

#### Flexible Destination

- Defaults to archive's parent directory
- Can specify custom directory
- Auto-creates destination directory if it doesn't exist

## Example Scenarios

### Single archive extraction

```bash
# Hover over document.7z, press your keybinding
# Enter: /path/to/extract/
# Result: Files extracted to specified directory
```

### Multiple archives with passwords

```bash
# Select archive1.7z (password: secret) and archive2.zip (password: secret)
# Enter destination: ./extracted/
# Enter password when prompted: secret
# Result: Both archives extracted with the same password
```

### Mixed archives (some protected, some not)

```bash
# Select archive.7z (no password) and secure.7z (password required)
# Password prompt appears only for secure.7z
# archive.7z extracts without password
```

## Error Handling

The plugin provides clear feedback for various scenarios:

- ✗ **Wrong password** - Indicates which files failed due to incorrect password
- ✗ **Extraction failed** - Shows files that failed for other reasons
- ✓ **Partial success** - Some archives extracted successfully
- ✓ **Complete success** - All archives extracted

## License

MIT License

## Acknowledgments

- Built for [Yazi](https://github.com/sxyazi/yazi) file manager
- Uses [7-Zip](https://www.7-zip.org/) for archive operations
