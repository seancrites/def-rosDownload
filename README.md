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

## Super Quick Start

1. Fetch def-rosDownload.rsc from GitHub

   ```console
   /tool fetch url="https://raw.githubusercontent.com/seancrites/def-rosDownload/refs/heads/master/def-rosDownload.rsc" mode=https dst-path="def-rosDownload.rsc" output=file
   ```

2. Load the file as a script

   ```console
   /system script add name=def-rosDownload source=[:file get def-rosDownload.rsc contents]
   ```

3. Run to load global function

   ```console
   /system script run def-rosDownload
   ```

4. Verify Registration

   ```console
   /system script environment print where name=rosDownload
   ```

5. Make persistent on boot:

   ```console
   /system scheduler add name="load-rosDownload" interval=0 \
      on-event="/system script run def-rosDownload" start-time=startup
   ```

6. Use:

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

## Quick Start

1. Download `def-rosDownload.rsc` from this repo.
2. Open WinBox/WebFig, create a new script "def-rosDownload" and paste the contents.
3. Run to load global function:

   ```console
   /system script run def-rosDownload
   ```

4. Verify registration:

   ```console
   /system script environment print where name=rosDownload
   ```

5. Make function persistent on boot:

   ```console
   /system scheduler add name="load-rosDownload" interval=0 \
      on-event="/system script run def-rosDownload" start-time=startup
   ```

6. Use:

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

## After successful staging

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
