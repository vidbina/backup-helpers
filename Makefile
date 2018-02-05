# Used commands
LN=ln
REALPATH=realpath
RM=rm
RSYNC=rsync

# Constants for the duration of this make run
STAMP!=date +"%Y%m%d_%H%M%S"
PREFIX=backup
BACKUP_DIR:=${PREFIX}_${STAMP}

# SOURCE defaults to the home directory
SOURCE?=~
# Expansions, not lazy-loaded
SRC:=`${REALPATH} ${SOURCE}`/
DST:=`${REALPATH} ${BACKUP_DIR}`/
REF:=--link-dest=`${REALPATH} .latest`/

# Initializes a backup tree
.init:
	${RSYNC} -aPh ${SRC} ${DST} \
	&& ${RM} -f .init .latest \
	&& ${LN} -s ${BACKUP_DIR} .init \
	&& ${LN} -s ${BACKUP_DIR} .latest

# Performs a backup
.PHONY: backup
backup:
	${RSYNC} -aPh ${REF} ${SRC} ${DST} \
	&& ${RM} .latest \
	&& ${LN} -s ${BACKUP_DIR} .latest

.PHONY: dry-run
dry-run:
	echo ${RSYNC} -n -aPh ${REF} ${SRC} ${DST}

# Nukes a backup tree
# NOTE: All backups and symlinks will be removed
#.PHONY: nuke
#nuke:
#	${RM} -rf .init .latest ${PREFIX}_*
