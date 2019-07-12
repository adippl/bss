#!/bin/bash
#btrfs-bin=btrfs

IFS_bk=$IFS

temp_send_on_err_var=1

echo_msg(){
	if [[ $DEBUG == "-1" ]] ;then 
		echo $@
	fi
	case $1 in
		"==")
			echo $@
		;;
		"~~")
			if [[ $DEBUG == "1" ]] ;then
				echo $@
			fi
		;;
		"!!")
			echo $@
		;;
	esac
}
exec_wrap(){	#doesn't work
	if [ DEBUG = "1" ] ;then
		echo_msg "!! DEBUG MODE is on, if it wasn't this command ↓↓↓↓↓ would have been executed"
		echo_msg "!! $@"
	else
		bash -c "$@"
	fi
}


bin_check(){
	btrfsbin=$(whereis btrfs |awk '{print $2}')
	if [[ -z $btrfsbin  ]] ;then
		echo_msg !! "Couldn't find btrfs-progs binary on the system"
		echo_msg !! "Exiting...."
		exit
	fi
	pvbin=$(whereis pv |awk '{print $2}')
	if [[ -z $pvbin  ]] ;then
		echo_msg !! "Couldn't find pv binary on the system"
		exit
	fi
}


delsubvol () {
	echo_msg == deleting snapshot $snapdir/$subnd
	echo_msg $btrfs sub $subnd
}

doesexist (){
	ssh -i $sshid $sshuh "btrfs sub show $snapsendloc/$subn}"
	ec=$?
	#if [[ -e $detemp  ]] ; then
	if test -s $ec
	then
		echo_msg == snapshot exists
		if [[ -e $(detemp|grep readonly) ]] ; then
			echo_msg == snapshot read only, probably fine
			return 0
		else
			echo_msg !! snapshot incomplete
	#		delsubvol()
		fi
	echo_msg !! "snapshot trasnfer failed"
	#subvoldel()
	fi
}

#transp () { #unused
#	case $transp in
#		ssh)
#			btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc
#		;;
#		nc)
#			ssh -i $sshid -f $sshuh 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc
#			sleep 1
#			btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| nc $ip 9999 -q 0
#
#		;;
#		local)
#			btrfs send -p $snapdir/$snapp  $snapdir/$snapf |pv| ssh -i $sshid sshuh btrfs
#		
#		
#		;;
#		*)
#		echo_msg !! "network option unhandled"
#		;;
#	esac
#	
#}

send_with () {
	case $1 in
		ssh)
			case $2 in
				inc)
					echo_msg ~~ "btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc"
					btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc
#echo_msg ~~ DEBUG EC 1-${PIPESTATUS[1]} 2-${PIPESTATUS[2]} 3-${PIPESTATUS[3]} 4-${PIPESTATUS[4]}
					ec=${PIPESTATUS[2]}
					return $ec
					;;
				comp)
					echo_msg ~~ "btrfs send $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc"
					btrfs send $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc
					ec=${PIPESTATUS[2]}
					return $ec
					;;
				*)
					echo_msg !! "error"
					;;
			esac
			#case $ec in
			#	0)
			#	return 0
			#	;;
			#	1)
			#	return 1
			#	;;
			#esac
			return $ec

		;;
		nc)
			case $2 in
				inc)
					echo_msg ~~ "ssh -i $sshid -f $sshuh 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc"
					#ssh -i $sshid -f $sshuh 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc
					ssh -i $sshid  $sshuh 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc &
					bc=$!
					sleep 1
					echo_msg ~~ "btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| nc $ip 9999 -q 0"
					btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| nc $ip 9999 -q 0
					wait $bc
					ec=$?
					return $ec
					;;
				comp)
					echo_msg ~~ "ssh -i $sshid -f $sshuh 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc"
					ssh -i $sshid $sshuh 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc &
					bc=$!
					sleep 1
					echo_msg ~~ "btrfs send $snapdir/$snapf |pv| nc $ip 9999 -q 0"
					btrfs send $snapdir/$snapf |pv| nc $ip 9999 -q 0
					wait $bc
					ec=$?
					return $ec
					;;
				*)
					echo_msg !! "error"
					;;
			esac

			return $ec
		;;
		local)
			#btrfs send -p $snapdir/$snapp  $snapdir/$snapf |pv| btrfs receive $snapsendloc
			case $2 in
				inc)
					echo_msg ~~ "btrfs send -p $snapdir/$snapp  $snapdir/$snapf |pv| btrfs receive $snapsendloc"
					btrfs send -p $snapdir/$snapp  $snapdir/$snapf |pv| btrfs receive $snapsendloc
					ec=${PIPESTATUS[3]}
					return $ec
					;;
				comp)
					echo_msg !! "sending complete subvolume"
					echo_msg ~~ "btrfs send $snapdir/$snapf |pv| btrfs receive $snapsendloc"
					btrfs send $snapdir/$snapf |pv| btrfs receive $snapsendloc
					ec=${PIPESTATUS[3]}
					return $ec
					;;
				*)
					echo_msg !! "error"
					return 1
					;;
			esac
			return $ec
			;;
		*)
			echo_msg !! "network option unhandled"
			return 2
		;;
	esac
}

bin_check
mount /mnt/a/		## this will be fixed, filesystem needs to be mouned on my particural machine
IFS='
'

#if test $1==""	#test for empty $1 argument
#then
#	conf_f="/etc/bss.conf"
#else
#	conf_f=$1
#fi
	conf_f=$1

for x in $(grep -v "#" $conf_f) ; do
	IFS=' 	' read -r -a linearray <<< $x
	subn=${linearray[0]} 
	snapfs=${linearray[1]}
	snapdir=${linearray[2]}
	snapsendloc=${linearray[3]}
	sshuh=${linearray[4]}
	sshid=${linearray[5]}
	subkeep=${linearray[6]}
	transp=${linearray[7]}
#	cmprs=${linearray[8]}
	ip=$(echo $sshuh | cut -d '@' -f 2)
	subnd="$subn-r-$(date +'%y%m%d')"

	if [[ $DEBUG == '1' ]] ; then 
		echo_msg ~~ "------------------------------------"
		echo_msg ~~ "conf_f		"$conf_f
		echo_msg ~~ "subn		"$subn
		echo_msg ~~ "snapfs		"$snapfs
		echo_msg ~~ "snapdir		"$snapdir
		echo_msg ~~ "snapsendloc	"$snapsendloc
		echo_msg ~~ "sshuh		"$sshuh
		echo_msg ~~ "sshid		"$sshid
		echo_msg ~~ "subkeep		"$subkeep
		echo_msg ~~ "transp		"$transp
		echo_msg ~~ "'ip(from sshuh)'	"$ip
		echo_msg ~~ "subnd		"$subnd
		echo_msg ~~ "------------------------------------"
	fi
	
#	if ! [[ $cmprs == "" ]]		#unfinished
#	then
#		if [[ $cmprs == "lzma" ]] || [[ test $cmprs == "xz" ]] || [[ test $cmprs == "pxz" ]]
#		then
#			echo_msg !!
#	fi
	
#	cmprs="${linearray[8]} -z "
#	cmprs_de="${linearray[8]} -d "
	
	if [[ -z $( ls -1 $snapdir | grep $subnd ) ]]; then
	
		echo == "creating snapshot "$snapdir'/'$subnd
		btrfs sub snap -r $snapfs $snapdir/$subnd
		snapp=$(ls $snapdir -1|grep $subn|sort -r|sed -n 2p)
		snapf=$(ls $snapdir -1|grep $subn|sort -r|sed -n 1p)
		echo_msg 	~~ "snapp	"$snapp
		echo_msg 	~~ "snapf	"$snapf

		send_with $transp inc
		ec=$?
		echo_msg ~~ sned exit code $ec
		if (( $ec == 1 )) ; then
			echo_msg !! "error while sending subvolume"
			for x in $(seq 3 $subkeep) ; do
				snapp=$(ls $snapdir -1|grep $subn|sort -r|sed -n $x'p')
				if [[ $snapp == "" ]] ;then
					echo !! "subvolume missing"
					ec=1
					break
				fi
				echo_msg !! "attempting to send using older parent"
				echo_msg 	~~ "snapp	"$snapp
				echo_msg 	~~ "snapf	"$snapf
				send_with $transp inc
				ec=$?
				if (( $ec == 0)) ;then break ;fi
			done
			if (( $ec == 1)) ;then
				echo_msg !! "all avalible parent subvolumes failed. Attempting to send complete snapshot"
				send_with $transp comp 
			fi
		fi
	else
		echo_msg !! "snapshot already exists!"
	fi
	
	for x in $(ls -1 $snapdir |grep $subn|sort -r|sed -n $subkeep',$p'); do 
		echo_msg ~~ "btrfs sub del "$snapdir'/'$x
		btrfs sub del $snapdir/$x
	done
	
	IFS='
	'

	unset subn
	unset snapfs
	unset snapdir
	unset snapsendloc
	unset sshuh
	unset sshid
	unset subkeep
	unset trans
	unset ip
	unset subnd
	unset ec
done

IFS=$IFS_bk
