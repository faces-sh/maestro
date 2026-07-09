# maestro
The Many-Faced Agent

## Install

Download the latest [Maestro.dmg](https://github.com/faces-sh/maestro/releases/latest/download/Maestro.dmg) and drag Maestro to Applications. The app updates itself from there.

## Upgrading from an old "Faced" install (0.3.x or earlier)

Old versions predate the auto-updater and store data in old locations. One command installs the
latest Maestro, removes the old app and its data (your Faces sign-in is kept), and repairs the
local faces catalog:

```
curl -fsSL https://raw.githubusercontent.com/faces-sh/maestro/main/upgrade-from-faced.sh | bash
```
