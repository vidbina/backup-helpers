# Backup Helpers

Rsync facilitates the making of backups in which unchanged files are simply
hard-linked instead of copied.

## Usage

Produce a backup.mk file in the same directory where the
Makefile is stored and specify the `SOURCE` variable therein.

```Makefile
# Example backup.mk
SOURCE=/something/i/need/to/backup
```

Produce a `.ignore` file in the root directory which contains the directories
within `SOURCE` to be ignored.

All of the following commands use the current working directory as the working
context:

 - `make .init` initializes a backup tree
 - `make backup` creates a backup, use the `SOURCE` variable to specify a
 non-`$HOME` directory to be archived such as demonstrated in
 `SOURCE=/directory/to/be/archived make backup`
 - `make nuke` destroys a backup tree. Use with caution! :boom: (has been
 commented to avoid accidental nukes :wink:)

To get started, clone this respository unto the root of the path that you
intent to use as a backup destination.

Start a backup tree by running `make .init`. This should produce a `.init.`
symlink and produce a backup directory with a name that contains a
representation of the time at which this operation was triggered.

Perform subsequent backups by running `make backup`.

The provided Makefile accepts a `SOURCE` variable upon calling the make rules,
which defaults to the user's `$HOME` directory when unspecified, in order to
produce a backup. In case you need another directory backed-up please remember
to specify the `SOURCE` as in `SOURCE=/to/be/archived make init` or
`SOURCE=/to/be/archived make backup`.

> The benefit of using backup.mk is that one no longer needs to think about the
source of the backup upon calling `make backup`. However; mind you that
thinking about the source of the backup is **only** really necessary if the
backup source isn't the home directory of the current user. Since many users,
generally work from their home directories and probably want to backup that
home directory anyways, just sticking to the defaults will suffice. :wink:

## Tree Layout

A backup tree will consist of a `.init` symlink which points to the initial
archive, a `.latest` symlink which points to the last archive and a number of
backup directories depending on how often the user has produced a backup. You
may simply change into any of the directories and start copying files to your
liking back into your home directory for mutation.
