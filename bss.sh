#!/bin/bash
#btrfs-bin=btrfs

IFS_bk=$IFS


echo_msg(){
	if [ DEBUG == "-1" ] ;then 
		echo $@
	fi
	case $1 in
		"==")
			echo $@
		;;
		"~~")
			if [ DEBUG == "1" ] ;then
				echo $@
			fi
		;;
		"!!")
			echo $@
		;;
	esac
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
doesexist_ossh (){
	detemp=$(ssh -i $sshid $sshuh "btrfs sub show $snapsendloc/$subn} ")
	if [[ -e $detemp  ]] ; then
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

transp () {
	case $transp in
		ssh)
			btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc
		;;
		nc)
			ssh -i $sshid -f $sshuh 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc
			sleep 1
			btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| nc $ip 9999 -q 0

		;;
		local)
			btrfs send -p $snapdir/$snapp  $snapdir/$snapf |pv| ssh -i $sshid sshuh btrfs
		
		
		;;
		*)
		echo_msg !! "network option unhandled"
		;;
	esac
	
}


#s='foo bar baz'
#a=( $s )
#echo ${a[0]}
#echo ${a[1]}

bin_check
mount /mnt/a/
IFS='
'
#if [[ -e $1 ]]

for x in $(cat /etc/bss.conf) ; do
	IFS=' 	' read -r -a linearray <<< $x
	subn=${linearray[0]} 
	snapfs=${linearray[1]}
	snapdir=${linearray[2]}
	snapsendloc=${linearray[3]}
	sshuh=${linearray[4]}
	sshid=${linearray[5]}
	subkeep=${linearray[6]}
	transp=${linearray[7]}
	ip=$(echo $sshuh | cut -d '@' -f 2)
	subnd="$subn-r-$(date +'%y%m%d')"

	if [ "DEBUG" == '1' ] ; then 
		echo_msg ~~ "------------------------------------"
		echo_msg ~~ "subn		"$subn
		echo_msg ~~ "snapfs		"$snapfs
		echo_msg ~~ "snapdir		"$snapdir
		echo_msg ~~ "snapsendloc	"$snapsendloc
		echo_msg ~~ "sshuh		"$sshuh
		echo_msg ~~ "sshid		"$sshid
		echo_msg ~~ "subkeep		"$subkeep
		echo_msg ~~ "trans		"$trans
		echo_msg ~~ "'ip(from sshuh)'	"$ip
		echo_msg ~~ "subnd		"$subnd
		echo_msg ~~ "------------------------------------"
	fi
	
	
	#if [[ ! -d $snapdir/$subd ]]; then #doesn't work and I don't know why :/
	if [[ -z $( ls -1 $snapdir | grep $subnd ) ]]; then
	
		echo == "creating snapshot "$snapdir'/'$subnd
		btrfs sub snap -r $snapfs $snapdir/$subnd
		snapp=$(ls $snapdir -1|grep $subn|sort -r|sed -n 2p)
		snapf=$(ls $snapdir -1|grep $subn|sort -r|sed -n 1p)
		echo_msg 	~~ "snapp	"$snapp
		echo_msg 	~~ "snapf	"$snapf
		#transp($transp)
		transp
	else
		echo ==  snapshot already exists!
		
	fi
	
	
	for x in $(ls -1 $snapdir |grep $subn|sort -r|sed -n $subkeep',$p'); do 
	
		echo_msg ~~ "btrfs sub del "$snapdir'/'$x
		btrfs sub del $snapdir/$x
	done
	
	IFS='
	'
done

IFS=$IFS_bk
