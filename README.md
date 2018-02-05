# Backup Helpers

Rsync facilitates the making of backups in which unchanged files are simply
hard-linked instead of copied.

The provided Makefile allows one to specify a `SOURCE` variable, which defaults
to the user's `$HOME` directory when unspecified, in order to produce a backup.

A backup tree will consist of a `.init` symlink which points to the initial
archive, a `.latest` symlink which points to the last archive and a number of
backup directories depending on how often the user has produced a backup. One
may simply change into any of the directories and start copying files whenever
necessary.

All of the following commands use the current working directory as the working
context:

 - `make .init` initializes a backup tree
 - `make backup` creates a backup, use the `SOURCE` variable to specify a
 non-`$HOME` directory to be archived such as demonstrated in
 `SOURCE=/directory/to/be/archived make backup`
 - `make nuke` destroys a backup tree. Use with caution! :boom: (has been
 commented to avoid accidental nukes :wink:)
