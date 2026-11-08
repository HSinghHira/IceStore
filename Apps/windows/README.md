---
source: https://github.com/dockur/windows
services:
  - { name: Web Viewer, path: /, icon: monitor }
variables:
  - name: LANGUAGE
    group: Windows setup
    default: "English"
    description: >-
      The Windows language, like French, German or Spanish. Read only when
      Windows installs.
  - name: REGION
    group: Windows setup
    default: ""
    description: >-
      The region and number format, like en-US or en-GB. Leave it out to
      match the language.
  - name: KEYBOARD
    group: Windows setup
    default: ""
    description: >-
      The keyboard layout, like en-US or de-DE. Leave it out to match the
      language.
  - name: EDITION
    group: Windows setup
    default: ""
    description: >-
      A different edition of the chosen version, when it has several. Leave
      it out for the normal one.
  - name: KEY
    group: Windows setup
    default: ""
    description: >-
      Your Windows product key. Leave it out to install without one.
  - name: COMMAND
    group: Windows setup
    default: ""
    description: >-
      One Windows command to run at the end of the install, like a reg add
      line.
  - name: WORKGROUP
    group: Windows setup
    default: ""
    description: >-
      The Windows workgroup name. Leave it out for WORKGROUP.
  - name: DOMAIN
    group: Active Directory
    default: ""
    description: >-
      Join this Active Directory domain while installing, like example.com.
      USERNAME and PASSWORD must then be a domain account.
  - name: DOMAIN_OU
    group: Active Directory
    default: ""
    description: >-
      Where to put the computer in the domain, like
      OU=Computers,DC=example,DC=com.
  - name: AUDIO
    group: Screen and sound
    default: "N"
    description: >-
      Set to Y to hear Windows sound in the web viewer. Then turn on Audio
      under Settings, Advanced in the viewer. Remote Desktop has sound
      without this.
  - name: WIDTH
    group: Screen and sound
    default: ""
    description: >-
      Screen width in pixels, like 1920. Set HEIGHT too.
  - name: HEIGHT
    group: Screen and sound
    default: ""
    description: >-
      Screen height in pixels, like 1080. Set WIDTH too.
  - name: DEBUG
    group: Logs
    default: "N"
    description: >-
      Set to Y for more detail in the app log.
---

# Windows

Run a full Windows computer on your home server. The app downloads Windows from Microsoft and installs it by itself; you watch it in your browser and use it there or with Remote Desktop. Each install gets its own Windows password instead of upstream's shared default "admin".

## Features

- Windows 11, 10, Server, LTSC and older versions back to Windows 95
- Downloads and installs on its own, no ISO or clicks needed
- Near-native speed with KVM
- Choose the memory, processor cores and disk size
- A shared folder between your server and Windows (drive Z)
- Use it in the browser or with any Remote Desktop app

## How to use

1. Open Windows from your dashboard.
2. Watch Windows install itself. It takes 10 to 30 minutes.
3. Use Windows in the browser, or connect a Remote Desktop app to `[ZIMAOS-IP-ADDRESS]:6188` with the user name and password from the app log.

## Before you install

Your server must support KVM (Intel VT-x or AMD-V turned on in the BIOS), and needs at least 32 GB of free space. Pick the Windows you want in `VERSION` before the first start:

| VERSION | Windows | VERSION | Windows |
|---|---|---|---|
| `11` | 11 Pro | `2025` | Server 2025 |
| `11l` | 11 LTSC | `2022` | Server 2022 |
| `11e` | 11 Enterprise | `2019` | Server 2019 |
| `10` | 10 Pro | `tiny11` | Tiny11 |
| `10l` | 10 LTSC | `core11` | Tiny11 Core |
| `10e` | 10 Enterprise | `7u` | 7 Ultimate |
| `8e` | 8.1 Enterprise | `xp` | XP Professional |

Set `RAM_SIZE` (up to 16G) and `CPU_CORES` to what your server can spare. Leave `PASSWORD` blank to get a random one; it is shown in the app log in the box marked CREDENTIALS and saved in the storage folder as `icestore-password.txt`. Windows takes the user name, password, language and the other setup settings only while it installs, so set them first; change the password later inside Windows. More settings, like language and keyboard, are in the Variables tab; add them in the app settings.

The web viewer has no password of its own: anyone on your network who opens port 6187 sees the Windows screen. For daily use, Remote Desktop on port 6188 is faster and has clipboard and sound. This app is for amd64 servers only.
