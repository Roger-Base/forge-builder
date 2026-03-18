# Full Desktop File Cleanse

## Description
Scans your system, flags duplicates, junk files, and clutter. Proposes folder structure and reorganizes files automatically.

## Features
- Duplicate file detection (by hash)
- Junk file identification (temp, cache, logs)
- Folder structure analysis
- Automatic reorganization
- Before/after reports

## Usage

```bash
# Scan home directory
node cleanse.js scan ~

# Scan with auto-organize
node cleanse.js organize ~ --dry-run

# Show duplicates only
node cleanse.js duplicates ~
```

## Detection Rules

### Junk Files
- `*.tmp`, `*.temp`, `*.log`
- `node_modules/`, `.cache/`
- `.DS_Store`, `Thumbs.db`
- Download folder old files (>90 days)

### Duplicates
- MD5/SHA256 hash comparison
- Same filename + same size
- Image similarity detection

### Organization Suggestions
- Documents → ~/Documents/
- Screenshots → ~/Pictures/Screenshots/
- Downloads → organize by date
- Projects → ~/code/

## Status
Script to be created

## Priority
High - useful for daily use
