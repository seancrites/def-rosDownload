# def-rosDownload

A RouterOS v7 global function script for staging a specific RouterOS version (upgrade or downgrade) by downloading the main package and all currently enabled extra packages (e.g., ups) as local .npk files.

Ideal for controlled upgrades/downgrades to specific versions, not just latest. Supports feature preservation and provides contextual next-steps (reboot for upgrades; `/system package downgrade` for downgrades).

## Features

- Individual .npk downloads for main + extras (direct from MikroTik servers)
- Detailed per-package CLI output and accurate staging status
- Contextual guidance: upgrade vs downgrade instructions

## Requirements

- RouterOS v7.1+ (tested on v7.18.x, v7.19.x and v7.20.x stable as of December 2025)
- Outbound HTTPS access to download.mikrotik.com (port 443)

## Quick Start

1. Download `def-rosDownload.rsc` from this repo.
2. Upload to router (e.g., via WinBox Files or SCP).
3. Import and register:

   ```console
   /import file-name=def-rosDownload.rsc
   /system script run def-rosDownload
   ```

4. Make persistent on boot:

   ```console
   /system scheduler add name="load-rosDownload" interval=0 \
      on-event="/system script run def-rosDownload" start-time=startup
   ```

5. Use:

   ```console
   $rosDownload 7.19.4
   ```

## Detailed Deployment Steps

### 1. Transfer the Script to the Router

- **Via WinBox**: Drag-and-drop `def-rosDownload.rsc` into Files tab.
- **Via SCP** (from Linux/macOS):

  ```console
  scp def-rosDownload.rsc admin@router-ip:
  ```

- **Via WebFig**: Files → Upload.

### 2. Import and Register the Global Function

```console
   /import file-name=def-rosDownload.rsc
   /system script run def-rosDownload
```

### 3. Verify Registration

```console
   /system script environment print where name=rosDownload
```

Should show the global function loaded.

### 4. Make Persistent Across Reboots

```console
/system scheduler add name="load-rosDownload" interval=0 \
   on-event="/system script run def-rosDownload" start-time=startup comment="Load rosDownload function"
```

### 5. Usage Examples

- Upgrade:

  ```console
  $rosDownload 7.20.1
  ```

- Downgrade:

  ```console
  $rosDownload 7.18.1
  ```

- LTS downgrade:

  ```console
  $rosDownload 6.49.10
  ```

After successful staging:

- Upgrade: `/system reboot`
- Downgrade: `/system package downgrade` (confirm prompt → auto-reboot)

## Production Notes

- Always export config (`/export file=config-backup`) before staging.
- In HA setups (VRRP clusters), stage on standby unit first.
- Rare unavailable extras (architecture-specific): Manual upload from "Extra packages" ZIP if needed.
- Monitor: `/log print where message~"rosDownload"` | `/file print detail where name~"\.npk$"`

## License

This project is licensed under the BSD 3-Clause License. See the [LICENSE](LICENSE) file for details.

## Author

- **Sean Crites** (<sean.crites@gmail.com>)

December 2025
