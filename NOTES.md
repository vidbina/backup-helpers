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

## Balancing

After removing subvolumes it may appear that the output of `df -H`
a

`btrfs fi show`

The output of `btrfs fi show /mnt/store` should provide some insights as to how
much space there is actually available on the btrfs partition.

```
sudo btrfs balance start -m -v /mnt/store
```

```
vid@bina> sudo btrfs fi show                                                                                            ~
Label: 'base'  uuid: 1623a3d9-cf4c-40d4-94a5-78b166a73982
	Total devices 1 FS bytes used 55.42GiB
	devid    1 size 100.00GiB used 100.00GiB path /dev/mapper/vg-root

Label: none  uuid: c564c85b-918a-4349-8960-083b86af34a2
	Total devices 1 FS bytes used 255.05GiB
	devid    1 size 300.00GiB used 300.00GiB path /dev/mapper/store-store

Label: 'vault'  uuid: ab4608b5-fa82-4136-b9cf-e11116bda80f
	Total devices 1 FS bytes used 271.73GiB
	devid    1 size 518.51GiB used 274.02GiB path /dev/nvme0n1p6

vid@bina> sudo btrfs fi df /store                                                                                       ~
Data, single: total=296.95GiB, used=253.13GiB
System, single: total=32.00MiB, used=48.00KiB
Metadata, single: total=3.01GiB, used=1.92GiB
GlobalReserve, single: total=422.14MiB, used=0.00B
```

## Links

 - https://lwn.net/Articles/579009/
 - https://gist.github.com/hopeseekr/cd2058e71d01deca5bae9f4e5a555440
 - https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
 - https://superuser.com/questions/607363/how-to-copy-a-btrfs-filesystem
 - https://lwn.net/Articles/506244/
 - https://ramsdenj.com/2016/04/05/using-btrfs-for-easy-backup-and-rollback.html
 - https://unix.stackexchange.com/questions/149932/how-to-make-a-btrfs-snapshot-writable
 - http://marc.merlins.org/perso/btrfs/post_2014-05-04_Fixing-Btrfs-Filesystem-Full-Problems.html
 - https://btrfs.wiki.kernel.org/index.php/Balance_Filters#Balancing_to_fix_filesystem_full_errors
