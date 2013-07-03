#!/bin/bash
#==================================
# add cron like this
# > crontab -e
#
# daily:1 1 * * * /path/to/script/rsync-backup.sh
#===================================

Backupdate="`date '+%Y%m%d.%H%M'`"

#Define rmt location
RmtUser=root
RmtHost=203.207.99.196
RmtPath=/home/backup/
BackupSource="${RmtUser}@${RmtHost}:${RmtPath}"
#BackupSource="/home/"

#Define location of backup
BackupRoot="/home/chehaojia/Backups/$RmtHost/"
#BackupRoot="/home/Backups/localhost/"

LogFile="${BackupRoot}backup.log"
ExcludeList="/home/chehaojia/Backups/backup-exclude-list.txt"

BackupName="${RmtHost}-backup"
BackupNum="7"
#BackupNum="31"

#======== !!! Do not modify the code below !!! =======

#Check if dir exists
checkDir(){
	if [ ! -d "${BackupRoot}/$1" ] ; then
		mkdir -p "${BackupRoot}/$1"
	fi
}

#Dir rotate
#$1 -> backup path
#$2 -> backup name
#$3 -> backup num
rotateDir(){
	for i in `seq $(($3 -1)) -1 1`
	do
		if [ -d "$1/$2.$i" ];then
			/bin/rm -rf "$1/$2.$((i + 1))"
			mv "$1/$2.$i" "$1/$2.$((i + 1))"
		fi
	done
}

#check dir 
checkDir "archive"
checkDir "daily"

#=========== Backup Begin =================
# step 1: Rotate daily.

rotateDir "${BackupRoot}/daily" "$BackupName" "$BackupNum"

checkDir "daily/${BackupName}.0/"
checkDir "daily/${BackupName}.1/"

mv ${LogFile} ${BackupRoot}/daily/${BackupName}.1/

cat >> ${LogFile} <<_EOF
===========================================
    Backup done on: $mydate
===========================================
_EOF

# step 2: Do the backup an save difference in ${BackupName}.1

rsync -av --delete \
	-b --backup-dir=${BackupRoot}/daily/${BackupName}.1 \
	--exclude-from=${ExcludeList} \
	$BackupSource ${BackupRoot}/daily/${BackupName}.0 \
	1>> ${LogFile} 2>&1

# step 3: Create an archive backup every week

cd ${BackupRoot}/daily/${BackupName}.0 
tar -cjf ${BackupRoot}/archive/${BackupName}-${Backupdate}.tar.bz2 \
	 .

#if [ `date +%w` == "2" ] # archive every week
#if [ `date +%d` == "01" ] # archive every first day of the month

#then
#tar -cjf ${BackupRoot}/archive/${BackupName}-${Backupdate}.tar.bz2 \
#	-C ${BackupRoot}/daily/${BackupName}.0 .
#fi

