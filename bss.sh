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


IFS_bk=$IFS

temp_send_on_err_var=1
MAXRETRY=10
#set -e


NC='\033[0m' # No Color
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
DOAS="doas"

#quick hack
if [ "$TERM" != "rxvt-unicode" ] ; then
	unset NC
	unset RED
	unset GREEN
	unset YELLOW
fi
	
msg_white(){
	if is_quiet ; then
		return
	fi
	case "$2" in
		"1")
		printf "*\t$NC$1$NC \n" && return
		;;
		"2")
		printf "\t*\t$NC$1$NC \n" && return
		;;
		*)
		printf "$NC$1$NC \n" && return
		;;
	esac
	}
msg(){
	if is_quiet ; then
		return
	fi
	case "$2" in
		"1")
		printf "*\t$GREEN$1$NC \n" && return
		;;
		"2")
		printf "\t*\t$GREEN$1$NC \n" && return
		;;
		*)
		printf "$GREEN$1$NC \n" && return
		;;
	esac
	}
msg_debug(){
	if [ "$DEBUG" = 1 ] ;then
		warn $1
		fi 
		}
warn(){
	printf "$YELLOW$1$NC \n"
	}
err(){
	printf "$RED$1$NC \n"
	}


ping_test_connection(){
	ping -c 1 $1
	#if [ "$?" = 0 ] ; then 
	return $?
	}

bss_ls_snapdir(){
	if [ "$sendpull" != "pull" ] ; then
		ls $snapdir
	else
		ssh -i $sshid $sshuh ls $snapdir
	fi
}

remoteCheckReadonly(){
	#$1 user@host
	#$2 path
 
	if [ "$sendpull" != "pull" ] && [ "$transp" = "ssh" ] ; then
		if test "$(ssh -i $sshid $sshuh "$DOAS btrfs sub show $snapsendloc/$subnd" | grep Flags | grep -o readonly)" == "readonly"; then
			return 0
		else
			return 1
		fi
	else
		if test "$(btrfs sub show $snapsendloc/$subnd | grep Flags | grep -o readonly)" == "readonly"; then
			return 0
		else
			return 1
		fi
	fi
	}
remoteCheckExist(){
	if [ "$sendpull" != "pull" ] && [ "$transp" = "ssh" ] ; then
		ssh -i $sshid $sshuh "test -d $snapsendloc/$subnd"
		return $?
	else
		test -d $snapsendloc/$subnd
		return $?
	fi
	}

remoteDelete(){
	#$1 user@host
	#$2 path
	ssh -i $sshid $1 "btrfs sub delete $2"
	}


bin_check(){
	btrfsbin=$(whereis btrfs |awk '{print $2}')
	if [[ -z $btrfsbin  ]] ;then
		err "Couldn't find btrfs-progs binary on the system"
		err "Exiting...."
		exit
	fi
	pvbin=$(whereis pv |awk '{print $2}')
	if [[ -z $pvbin  ]] ;then
		err !! "Couldn't find pv binary on the system"
		exit
	fi
}

delsubvol(){
	msg "deleting snapshot $snapdir/$subnd"
	msg "$btrfs sub $subnd"
}

doesexist(){
	ssh -i $sshid $sshuh "btrfs sub show $snapsendloc/$subn}"
	ec=$?
	if test -s $ec
	then
		msg "snapshot exists"
		if [[ -e $(detemp | grep readonly) ]] ; then
			msg snapshot read only, probably fine
			return 0
		else
			err snapshot incomplete
	#		delsubvol()
		fi
	err "snapshot trasnfer failed"
	#subvoldel()
	fi
}

sendSubvol_retry () {
	send_with $1 $2 $3
	ec=$?
	msg_debug "sned exit code $ec"
	if (( $ec == 1 )) ; then
		if remoteCheckExist $sshuh $snapsendloc/$subnd && ! remoteCheckReadonly $sshuh $snapsendloc/$subnd ; then
			msg "failed send, created snapshot is not readonly."
				for x in $(seq 1 $MAXRETRY); do
					remoteDelete $sshuh $snapsendloc/$subnd
					msg "attempting to resend, $x attempt."
					send_with $transp inc $3
					if remoteCheckReadonly $sshuh $snapsendloc/$subnd
						then return 0
						fi
					done	
				err "all attempts to retry failed"
				return 1
			fi
		return 1
		fi

}


function send_with () {
	case $1 in
	ssh)
		if [ "$sendpull" != "pull" ] ; then
			case $2 in
			inc)
				btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc
				ec=${PIPESTATUS[2]}
				return $ec
				;;
			comp)
				btrfs send $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc
				ec=${PIPESTATUS[2]}
				return $ec
				;;
			*)
				err "error"
				;;
			esac
			return $ecMa
		else
			case $2 in
			inc)
				ssh -i $sshid $sshuh btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| btrfs receive $snapsendloc
				ec=${PIPESTATUS[2]}
				return $ec
				;;
			comp)
				ssh -i $sshid $sshuh btrfs send $snapdir/$snapf |pv| btrfs receive $snapsendloc
				ec=${PIPESTATUS[2]}
				return $ec
				;;
			*)
				err "error"
				;;
			esac
			return $ecMa
		fi
	;;
	
	local)
		case $2 in
		inc)
			btrfs send -p $snapdir/$snapp  $snapdir/$snapf |pv| btrfs receive $snapsendloc
			ec=${PIPESTATUS[3]}
			return $ec
			;;
		comp)
			msg "sending complete subvolume"
			btrfs send $snapdir/$snapf |pv| btrfs receive $snapsendloc
			ec=${PIPESTATUS[3]}
			return $ec
			;;
		*)
			err "error"
			return 1
			;;
		esac
		return $ec
		;;
	"snapOnly")
		msg "sendOnly option selected, not sending snapshot"
		;;
	*)
		err "network option unhandled"
		return 2
	;;
	esac
}

is_quiet(){
	[ $QUIET -eq 1 ] && return 0 #return true
}

bin_check
IFS='
'
#test for empty $1 argument

if [ "$1" != "" ] ;then
	conf_f=$1
else
	conf_f="/etc/bsstab"
fi

for x in $(grep -v "^#" $conf_f) ; do
	IFS=' 	' read -r -a linearray <<< $x
	subn=${linearray[0]} 
	snapfs=${linearray[1]}
	snapdir=${linearray[2]}
	snapsendloc=${linearray[3]}
	sshuh=${linearray[4]}
	sshid=${linearray[5]}
	sub_keep=${linearray[6]}
	transp=${linearray[7]}
	sendpull=${linearray[8]}
	sub_keep_remote=${linearray[9]}
	ip=$(cut -d '@' -f 2 <<< "$sshuh" )
	#subnd="$subn-r-$(date +'%y%m%d')"
	subnd="$subn-r-$(date '+%Y%m%d-%H%M')"
	
	if [ "$DEBUG" = 1 ] ; then 
		msg_debug "------------------------------------"
		msg_debug "conf_f		$conf_f"
		msg_debug "subn		$subn"
		msg_debug "snapfs		$snapfs"
		msg_debug "snapdir		$snapdir"
		msg_debug "snapsendloc	$snapsendloc"
		msg_debug "sshuh		$sshuh"
		msg_debug "sshid		$sshid"
		msg_debug "sub_keep		$sub_keep"
		msg_debug "transp		$transp"
		msg_debug "'ip(from sshuh)'	$ip"
		msg_debug "subnd		$subnd"
		msg_debug "sendpull		$sendpull"
		msg_debug "sub_keep_remote	$sub_keep_remote"
		msg_debug ""
		msg_debug "------------------------------------"
	fi
	
	quiet_snapOnly="1"
	#quiet_snapOnly="0"
	[ "$transp" = "snapOnly" ] && [ "$quiet_snapOnly"="1" ] && QUIET=1
	
	if [ -z $( bss_ls_snapdir | grep $subnd ) ] ; then
	msg_white "===================="
		if [ "$sendpull" != "pull" ] ; then
			msg "creating snapshot $snapdir/$subnd"
			if is_quiet ; then 
				btrfs sub snap -r $snapfs $snapdir/$subnd 1>/dev/null
			else
				btrfs sub snap -r $snapfs $snapdir/$subnd
			fi
		else
			msg "creating snapshot $snapdir/$subnd on $sshuh"
			ssh -i $sshid $sshuh $DOAS btrfs sub snap -r $snapfs $snapdir/$subnd
		fi
		snapp=$(bss_ls_snapdir |grep "^$subn-r-" |sort -r |sed -n 2p)
		snapf=$(bss_ls_snapdir |grep "^$subn-r-" |sort -r |sed -n 1p)
		msg_debug "snapp $snapp"
		msg_debug "snapf $snapf"
		
		sendSubvol_retry $transp inc $sendpull
		ec=$?
		msg_debug "sned exit code $ec"
		if [ "$ec" = 1 ] ; then
			
			msg_debug "error while sending subvolume"
			for x in $(seq 3 $sub_keep) ; do
				snapp=$(bss_ls_snapdir |grep "^$subn-r-" |sort -r |sed -n $x'p')
				if [[ "$snapp" == "" ]] ;then
					err "subvolume missing"
					ec=1
					break
				fi
				err "attempting to send using older parent"
				msg_debug  "snapp	$snapp"
				msg_debug  "snapf	$snapf"
				send_with $transp inc
				ec=$?
				echo "ec=$ec"
				if [ $ec = 0 ] ;then break ;fi
			done
			if [ "$ec" == 1 ] ;then
				err "all avalible parent subvolumes failed. Attempting to send complete snapshot"
				send_with $transp comp 
			fi
		fi
	else
		err "snapshot $snapdir/$subnd already exists!"
	fi
	
	if [ "$sendpull" = "pull" ] ; then
		msg "deleting older subvolumes on client"
		for x in $(ssh -i $sshid $sshuh ls -1 $snapdir |grep "^$subn-r-" |sort -r |sed -n $sub_keep',$p'); do
			ssh -i $sshid $sshuh $DOAS btrfs sub del $snapdir/$x
		done
		msg "deleting older local subvolumes"
		for x in $(ls -1 $snapsendloc |grep "^$subn-r-" |sort -r |sed -n $sub_keep_remote',$p'); do
			btrfs sub del $snapsendloc/$x
		done
	else
		msg "deleting older local subvolumes"
		for x in $(ls -1 $snapdir |grep "^$subn-r-" |sort -r |sed -n $sub_keep',$p'); do
			if is_quiet ; then 
				btrfs sub del $snapdir/$x 1>/dev/null
			else
				btrfs sub del $snapdir/$x
			fi
		done
	fi
	
	IFS='
	'
	
	unset subn
	unset snapfs
	unset snapdir
	unset snapsendloc
	unset sub_keep_remote
	unset sshuh
	unset sshid
	unset sub_keep
	unset trans
	unset ip
	unset subnd
	unset ec
done

IFS=$IFS_bk

# vim :ts=4:
