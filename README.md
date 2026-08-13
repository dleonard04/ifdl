# ifdl

Switch a Debian machine between named network "locations" — home, work, cafe —
with a single command.

`ifdl` is a small wrapper around Debian's `ifup`/`ifdown` for laptops that move
between networks needing genuinely different configuration: a different
`/etc/network/interfaces`, different DNS, a different `/etc/hosts`. You keep one
suffixed copy of each config file per location, and `ifdl` copies the right set
into place before bringing the interface up.

```sh
ifdl eth0 work     # install the "work" config, then ifup eth0
ifset cafe         # install the "cafe" config, don't touch the interface
ifdl -l            # list the locations you've defined
```

## Status

This is a 2004-era tool, imported from CVS and still maintained for machines
that run `ifupdown` directly. If you're on a desktop running NetworkManager,
its own connection profiles already solve this problem and you don't need
`ifdl`. This is for the `/etc/network/interfaces` world.

Pure POSIX `/bin/sh`. No dependencies beyond `ifupdown`.

## How it works

There's no state file and no database. A "location" is just a filename suffix.

For each config file listed in `/etc/network/ifdl.conf`, you create a copy per
location by appending `.<location>`:

```
/etc/network/interfaces          <- the live file ifup actually reads
/etc/network/interfaces.home
/etc/network/interfaces.work
/etc/resolv.conf                 <- live
/etc/resolv.conf.home
/etc/resolv.conf.work
```

Running `ifdl eth0 work` copies every `*.work` variant over its live
counterpart, then runs `ifup eth0`. Files with no variant for that location are
left alone, so you only need to create the ones that actually differ.

Because the live file is overwritten in place, edit the **suffixed** copies, not
the live one — see [Known limitations](#known-limitations).

## Installation

### From the Debian package

```sh
./build.sh
sudo dpkg -i ../ifdl_*_all.deb
```

This installs `/sbin/ifdl`, `/sbin/ifset` and `/etc/network/ifdl.conf`.

## Configuration

`/etc/network/ifdl.conf` is sourced by both tools:

```sh
IFUP="/sbin/ifup"
IFDOWN="/sbin/ifdown"

NETWORK="/etc/network"

FILES="$NETWORK/interfaces \
       /etc/hosts \
       /etc/pcmcia/wlan-ng.opts \
       /etc/resolv.conf \
       /etc/ssh/ssh_config \
       /etc/wlan/wlan.conf"
```

`FILES` is the whole mechanism: it's the list of files that get the per-location
suffix treatment. Trim it to the files you actually vary, and add any others you
want switched. The shipped list is from 2004 and mentions `pcmcia` and
`wlan-ng`, which almost certainly don't exist on a modern system — harmless,
since missing variants are skipped, but worth cleaning up.

The **first** entry in `FILES` is special: `--list` globs it to discover which
locations exist, so it should be a file you define a variant of for every
location.

`IFDOWN` is read from the config but not currently used by either script.

## Usage

Both tools write to `/etc` and need root.

### `ifdl` — switch location and bring the interface up

```
Usage: ifdl [-b] [-f] [-h] [-l] [-v] <interface> [network location]
```

| Flag | Meaning |
| --- | --- |
| `-b`, `--backup` | Copy each live file to `<file>.bak` before overwriting |
| `-f`, `--force` | Pass `cp -f`: if a live file can't be opened for writing, remove and recreate it |
| `-h`, `--help` | Usage summary |
| `-l`, `--list` | List defined locations and exit |
| `-v`, `--verbose` | Pass `--verbose` through to `ifup` |

`<interface>` is a single interface name, or `-a` for all of them. The location
argument is optional; without it, no files are copied and `ifdl` is a plain
`ifup`.

### `ifset` — switch location only

```
Usage: ifset [-b] [-f] [-h] [-l] [network location]
```

Same file-copying behavior, but it never calls `ifup`. This exists for wireless,
where you usually need the configuration in place *before* association is
attempted, and bringing the interface up is a separate step.

Unlike `ifdl`, the location argument is required.

## Example

Set up two locations — DHCP at a cafe, static at the office:

```sh
# start from your current working config
sudo cp /etc/network/interfaces /etc/network/interfaces.cafe
sudo cp /etc/resolv.conf        /etc/resolv.conf.cafe

sudo cp /etc/network/interfaces /etc/network/interfaces.work
sudo cp /etc/resolv.conf        /etc/resolv.conf.work

# edit the .work pair for the static office setup
sudoedit /etc/network/interfaces.work
sudoedit /etc/resolv.conf.work
```

Then switch:

```sh
$ sudo ifdl -l
Network locations found:
cafe
work

$ sudo ifdown eth0
$ sudo ifdl -b eth0 work
```

For wireless, set the config first and associate afterwards:

```sh
$ sudo ifset work
Current configured network [work]
$ sudo ifup wlan0
```

## Known limitations

These are longstanding behaviors of the scripts, listed so they don't surprise
you. Both tools use a hand-rolled argument loop rather than `getopt`.

- **Copy failures are not detected.** Neither tool checks whether the `cp`
  calls succeeded, and `ifdl` runs `ifup` regardless — so if a live file can't
  be written, the interface comes up on the *previous* location's config with
  only a `cp:` message on stderr to warn you. `-f` avoids the most common cause
  (an unwritable live file), but watch stderr when switching.
- **A lone positional argument is always the interface, never a location.**
  `ifdl work` runs `ifup work`; it does not switch to the `work` location. The
  location is only recognized as the second positional, so you always need
  both: `ifdl eth0 work`.
- **Location names cannot contain a `-`.** Any argument containing a dash is
  treated as an option, so `ifdl eth0 coffee-shop` prints the help text instead
  of switching. Note `-l` will happily *list* such a location, so it can look
  defined while being unreachable. Use `coffeeshop`.
- **Arguments cannot contain whitespace**, and combined short flags (`-bv`) are
  not supported. Pass flags separately.
- **No rollback if `ifup` fails.** Config files are copied first, so a failed
  `ifup` leaves you switched to the new location's files regardless.
- **The live file is overwritten, not symlinked.** Any edit you make to a live
  file is lost at the next switch unless you copy it back to the suffixed
  variant. `-b` gives you one level of `.bak` safety net.
- **No dry-run.** There is no way to preview which files a switch would replace.

## Building

`./build.sh` runs `dpkg-buildpackage -b -us -uc` and drops the `.deb` in the
parent directory. `-b` is required rather than `-B`, since the package is
`Architecture: all`.

The committed source directory is `src/`. During a build the Makefile's `pre`
target renames it to `ifdl_<version>/` and `post` renames it back — if a build
dies partway and leaves the versioned name behind, rename it to `src/` rather
than committing it.

See [CLAUDE.md](CLAUDE.md) for the packaging details and the guards in the
`Makefile` that keep the build from recursing.

## License

GPL-2.0. See [LICENSE](LICENSE) and [debian/copyright](debian/copyright).

Copyright (C) 2004-2026 Douglas Leonard &lt;dleonard@dleonard.net&gt;
