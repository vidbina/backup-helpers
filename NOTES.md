# Btrfs Housekeeping

## Docker btrfs volumes cleanup
Somehow, I ran into the situation where my btrfs subvolumes for Docker have
hogged my disk space again. A `docker system prune` was useless in cleaning up
this issue because of some permission-related problems, however; I was able to
list all the btrfs subvolumes at the path where my docker assets are stored. By
default this path would be `/var/lib/docker` but on my setup this is different
(my docker-related assets are on a `/mnt/store` btrfs volume) so bear with me
 
```
# list btrfs subvolumes as a table (-T)
btrfs subvolumes list /mnt/store -T
```

and subsequently remove all subvolumes by sudo calling the following script

```sh
#! /bin/sh
for subvolume in /mnt/store/docker/btrfs/subvolumes/*; do
  btrfs subvolume delete $subvolume
done
```

I managed to produce rsync backups of my setup to an external disk which serves
me quite well as a backup strategy, however; snapshotting could fit somewhere
in my personal data hygiene toolbox to make my data-loss issues truly a thing
of the past.

The deal with btrfs is that snapshots are made on the same volume that they are
snapshotting. Notice how in the following example, I basically snapshot the
entire `/mnt/store` volume to `/mnt/store/snapshot_*`.

```
sudo btrfs subvolume snapshot /mnt/store /mnt/store/snapshot_$(date '+%Y%m%d_%H%M')
```

A user can cd into the snapshot and observe the files therein. Conversely, one
can also just mount a snapshot :wink:.

## Moving btrfs snapshot between drives (or volumes)

Moving a snapshot between volumes requires a `btrfs send` from the sending
volume and a `btrfs receive` from the receiving volume. One cannot simply copy
a btrfs subvolume directory around because the representation of the files may
not be complete (cached writes that aren't persisted) and some metadata could
be missing.

Sending using

```
btrfs send current
```

will send the snapshot, `current`, in its entirity to stdout, whereas 

```
btrfs send -i previous current
```

will perform an incremental send in which the diff from `previous` to `current`
is send to stdout.

Attempting to run

```
btrfs send /mnt/store/snapshot_x | btrfs receive /mnt/backup
```

will fail with

```
ERROR: check if we support uuid tree fails - Operation not permitted
ERROR: subvolume /mnt/store/snapshot_x is not read-only
```

if the snapshot to be sent isn't read-only. Produce a read-only snapshot by
executing

```
btrfs subvolume snapshot -r /mnt/store /mnt/store/snapshot_x
```

or, when `snapshot_x` already exists, executing

```
btrfs property set -ts /mnt/store/snapshot_x ro true
```

should make `snapshot_x` read-only.


The error

```
ERROR: check if we support uuid tree fails - Operation not permitted
ERROR: failed to determine mount point for /mnt/store/snapshot_x: Operation not permitted

```

may be a result of forgetting to sudo both the `btrfs send` as well as the
`btrfs receive` commands. :wink:

The correct command for sending data from `/mnt/store` to `/mnt/backup` is

```
btrfs send /mnt/store/snapshot_x | btrfs receive /mnt/backup
```

## Links

 - https://lwn.net/Articles/579009/
 - https://gist.github.com/hopeseekr/cd2058e71d01deca5bae9f4e5a555440
 - https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
 - https://superuser.com/questions/607363/how-to-copy-a-btrfs-filesystem
 - https://lwn.net/Articles/506244/
 - https://ramsdenj.com/2016/04/05/using-btrfs-for-easy-backup-and-rollback.html
 - https://unix.stackexchange.com/questions/149932/how-to-make-a-btrfs-snapshot-writable
