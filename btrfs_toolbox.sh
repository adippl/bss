#!/bin/bash
#	bss.sh btrfs incremental backup script
#	Copyright (C) 2021  Adam Prycki (email: <-REDACTED-> )
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>
#
#	Niniejszy program jest wolnym oprogramowaniem; możesz go
#	rozprowadzać dalej i/lub modyfikować na warunkach Powszechnej
#	Licencji Publicznej GNU, wydanej przez Fundację Wolnego
#	Oprogramowania - według wersji 2 tej Licencji lub (według twojego
#	wyboru) którejś z późniejszych wersji.
#
#	Niniejszy program rozpowszechniany jest z nadzieją, iż będzie on
#	użyteczny - jednak BEZ JAKIEJKOLWIEK GWARANCJI, nawet domyślnej
#	gwarancji PRZYDATNOŚCI HANDLOWEJ albo PRZYDATNOŚCI DO OKREŚLONYCH
#	ZASTOSOWAŃ. W celu uzyskania bliższych informacji sięgnij do
#	Powszechnej Licencji Publicznej GNU.
#
#	Z pewnością wraz z niniejszym programem otrzymałeś też egzemplarz
#	Powszechnej Licencji Publicznej GNU (GNU General Public License);
#	jeśli nie - zobacz <http://www.gnu.org/licenses/>.
#


[ "$VERBOSE" = "" ] && VERBOSE=false
btrfs_FSs="$(df -T| awk '$2=="btrfs"'|sort| awk 'BEGIN { OLD_DEV=""} {DEV=$1} ( DEV!=OLD_DEV ) {print $7 } { OLD_DEV=DEV }')"
rc=0

case ${0##*/} in 
	"btrfs_scrub.sh")
		COMMAND=" /sbin/btrfs scrub start -B -c 3 -n 7 " 
		error_msg="btrfs scrub encountered some errors"
		success_msg="btrfs scrub finished successfully"
		;;
	"btrfs_device_stats.sh")
		COMMAND=" /sbin/btrfs device stats -c " 
		error_msg="detected device errors"
		success_msg="btrfs device stats detected no errors"
		;;
	"ceph_status_stats.sh")
		COMMAND=" ceph status " 
		error_msg="Something is wrong with CPEH"
		success_msg="command returned correct error code"
		;;
	"btrfs_trim.sh")
		COMMAND="/sbin/fstrim"
		error_msg="Something is wrong with fstrim"
		success_msg="command returned correct error code"
		;;
	*)
		echo "wrong filename"
		echo "$0"
		echo "available modes:"
		echo " btrfs_device_stats.sh"
		echo " btrfs_trim.sh"
		echo " btrfs_scrub.sh"
		exit 1
esac


if [ "$btrfs_FSs" = "" ] ;then
	#empty
	$VERBOSE && echo "no btrfs filesystems found"
	exit 0
fi

for x in $btrfs_FSs ; do
	$VERBOSE && echo && echo "== running on $x filesystem =="
	out="$( $COMMAND $x )"
	ec=$?
	if [ $ec != 0 ] ;then
		echo "ERROR command returned non-zero exit code $ec" 
		echo "$error_msg"
		echo "$out"
		rc=1
	else
		if $VERBOSE ; then
			echo "$success_msg"
			echo "$out"
		fi
	fi
done

exit $rc
