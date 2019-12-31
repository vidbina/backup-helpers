# Used commands
LN = ln
REALPATH = realpath
RM = rm
RSYNC ?= rsync

-include backup.mk

# Constants for the duration of this make run
STAMP != date +"%Y%m%d_%H%M%S"
PREFIX = backup
BACKUP_DIR := ${PREFIX}_${STAMP}

# SOURCE defaults to the home directory
SOURCE ?=~
# Expansions, not lazy-loaded
SRC := `${REALPATH} ${SOURCE}`/
DST := `${REALPATH} ${BACKUP_DIR}`/
REF := --link-dest=`${REALPATH} .latest`/

# The following Rsync arguments are used:
#  -a archive mode; equals -rlptgoD
#    -r recurse into directories
#    -l copy symlinks as symlinks
#    -p preserve permissions
#    -t preserve modification times
#    -g preserve group
#    -o preserve owner (super-user only)
#    -D same as --devices --specials
#      --devices preserve device files (super-user only)
#      --specials preserve special files
#  -P same as --partial --progress
#    --partial keep partially transferred files
#    --progress show progress during transfer
#  -h output numbers in a human-readable format
#  -n perform a trial run with no changes made
#  -v increase verbosity
#  --stats prints a verbose set of statistics to provide extra insight into deltra-tranfer alg
RSYNC_ARGS = -aPh

# The following Rsync arguments provide more control in symlink handling:
# --copy-links            transform symlink into referent file/dir
# --copy-unsafe-links     only "unsafe" symlinks are transformed
# --safe-links            ignore symlinks that point outside the tree
# --munge-links           munge symlinks to make them safer
#RSYNC_ARGS+=--copy-unsafe-links
# Copying unsafe links makes sense from the perspective of obtaining "complete
# backups". Otherwise, we risk getting unusable artefacts. One example would be
# the case in which a directory in the backup path symlinks to a file on a
# mounted drive. This would be outside of the backup tree but if the backup is
# to be complete, it should contain at least a copy of the files symlinked to
# in order to grant the user the convenience of "full use" when referring to a
# backup.

# --exclude-from=FILE     read exclude patterns from FILE
# --exclude-from=FILE
#        This option is related to the --exclude option, but it  specifies
#        a  FILE  that  contains  exclude  patterns (one per line).  Blank
#        lines in the file and lines starting with ’;’ or ’#’ are ignored.
#        If FILE is -, the list will be read from standard input.
RSYNC_DEBUG_ARGS ?= -vv
RSYNC_ARGS += --exclude-from=.ignore

# Initialize a backup tree in the current working directory by archiving the
# SRC into DST.
INIT_CMD = ${RSYNC} ${RSYNC_ARGS} ${SRC} ${DST}

# Backup SRC into DST while keeping REF as a reference for hardlinking.  REF is
# generally the last backup. The the delta-transfer algorithm would basically
# just need to compare the source (SRC) to the reference (REF) and hardlink
# non-changed files into the destination (DST) while simultaneously copying
# changed files into the destination (DST).
BACKUP_CMD = ${RSYNC} ${RSYNC_ARGS} ${REF} ${SRC} ${DST}

# Initializes the backup tree and saves the log of the operation along with
# some statistics into a file.
.init:
	${INIT_CMD} ${RSYNC_DEBUG_ARGS} --stats > ${PREFIX}_${STAMP}.log \
	&& ${RM} -f .init .latest \
	&& ${LN} -s ${BACKUP_DIR} .init \
	&& ${LN} -s ${BACKUP_DIR} .latest

# Dry-run of .init
.PHONY: .init-test
.init-test:
	${INIT_CMD} ${RSYNC_DEBUG_ARGS} -n --stats > ${PREFIX}_${STAMP}.dry.log

# Performs a backup and saves the log of the operation along with some
# statistics into a file.
.PHONY: backup
backup:
	${BACKUP_CMD} ${RSYNC_DEBUG_ARGS} --stats > ${PREFIX}_${STAMP}.log \
	&& ${RM} .latest \
	&& ${LN} -s ${BACKUP_DIR} .latest

# Dry-run of backup
.PHONY: backup-test
backup-test:
	${BACKUP_CMD} ${RSYNC_DEBUG_ARGS} -n --stats > ${PREFIX}_${STAMP}.dry.log

# Nukes a backup tree
# NOTE: All backups and symlinks will be removed
#.PHONY: nuke
#nuke:
#	${RM} -rf .init .latest ${PREFIX}_*
