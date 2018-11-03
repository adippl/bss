#!/bin/bash
#btrfs-bin=btrfs

btrfsbin=$(whereis btrfs |awk '{print $2}')
if [[ -z $btrfsbin  ]] ;then
	echo "!! Couldn't find btrfs-progs binary on the system"
	echo "!! Exiting...."
	exit
fi
pvbin=$(whereis pv |awk '{print $2}')
if [[ -z $pvbin  ]] ;then
	echo "!~ Couldn't find pv binary on the system"
	exit
fi

delsubvol () {
	echo == deleting snapshot $snapdir/$subnd
	echo $btrfs sub $subnd
}
doesexist_ossh (){
	detemp=$(ssh -i $sshid $sshuh "btrfs sub show $snapsendloc/$subn} ")
	if [[ -e $detemp  ]] ; then
		echo == snapshot exists
		if [[ -e $(detemp|grep readonly) ]] ; then
			echo == snapshot read only, probably fine
			return 0
		else
			echo !! snapshot incomplete
	#		delsubvol()
		fi
	echo !! snapshot trasnfer failed
	#subvoldel()

	fi
}

transp () {
	case $transp in
		ssh)
			btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| ssh -i $sshid $sshuh btrfs receive $snapsendloc
		;;
		nc)
			ssh -i $sshid -f root@10.0.6.11 'nc -l -p 9999 -w 5 |btrfs receive '$snapsendloc
			sleep 1
			btrfs send -p $snapdir/$snapp $snapdir/$snapf |pv| nc $ip 9999 -q 0

		;;
		local)
			btrfs send -p $snapdir/$snapp  $snapdir/$snapf |pv| ssh -i $sshid sshuh btrfs
		
		
		;;
		*)
		echo '!! network option unhandled'
		;;
	esac
	
}


#s='foo bar baz'
#a=( $s )
#echo ${a[0]}
#echo ${a[1]}

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

if [[ $2 == 'debug' ]] ; then 
	echo ------------------------------------
	echo subn		$subn
	echo snapfs		$snapfs
	echo snapdir		$snapdir
	echo snapsendloc	$snapsendloc
	echo sshuh		$sshuh
	echo sshid		$sshid
	echo subkeep		$subkeep
	echo trans		$trans
	echo 'ip(from sshuh)'	$ip
	echo subnd		$subnd
	echo ------------------------------------
	echo
	echo
	echo
	echo
fi


#if [[ ! -d $snapdir/$subd ]]; then #doesn't work and I don't know why :/
if [[ -z $( ls -1 $snapdir | grep $subnd ) ]]; then

	echo == creating snapshot $snapdir/$subnd
	btrfs sub snap -r $snapfs $snapdir/$subnd
	snapp=$(ls $snapdir -1|grep $subn|sort -r|sed -n 2p)
	snapf=$(ls $snapdir -1|grep $subn|sort -r|sed -n 1p)
	echo	snapp	$snapp
	echo	snapf	$snapf

	transp

else
	echo ==  snapshot already exists!
	
fi


for x in $(ls -1 $snapdir |grep $subn|sort -r|sed -n $subkeep',$p'); do 

	echo --	btrfs sub del $snapdir/$x
done

IFS='
'
done

