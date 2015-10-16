#!/bin/bash

errcho() { echo "$@" 1>&2; }

if [ "$#" -ne 1 ]; then
  errcho "Usage: $0 <dir>"
  exit 1
fi

echo \"type\",\"language\",\"filename\",\"graph\",\"reordering\",\"NES\",\"NWES\",\"time\",\"bandwidth\",\"profile\",\"span\",\"avgwavefront\",\"RMSwavefront\"

for i in $(find $1 -type f)
do
	# skip if exit status is not 0
	grep "Exit \[0\]" "$i" > /dev/null
	proper_exit=$?
	grep "Stopped LTSMin Server." "$i" > /dev/null
	prob_exit=$?
	if [ $proper_exit != 0 -a $prob_exit != 0 ]
	then
		errcho $i failed, continuing
		continue
	fi
	
	grep "performance run" "$i" > /dev/null
	if [ $? = 0 ]
	then
		echo -n "performance" 
	else
		grep "statistics run" "$i" > /dev/null
		if [ $? = 0 ]
		then
			echo -n "statistics"
		else
			errcho "do not know what type of run this is"
		fi		
	fi	
	echo -n ,
	
	# print language
	frontend=$(grep "[^2]*2lts-seq" $i -m1 -o)
	case $frontend in
		"pnml2lts-seq")
		echo -n \"PNML\",
		;;
		"lps2lts-seq")
		echo -n \"mCRL2\",
		;;
		"prob2lts-seq")
		echo -n \"B\",
		;;
		"dve2lts-seq")
		echo -n \"DVE\",
		;;
		"prom2lts-seq")
		echo -n \"Promela\",
		;;
		*)
		errcho "dont know frontend \"$frontend\" in file $i"
		exit 1
		;;
	esac
	
	# print filename (we can assume file names have no spaces (I checked that)
	# for B we have to parse a little different, since we work with sockets
	grep "prob2lts-seq" $i > /dev/null
	if [ $? = 0 ]
	then
		# example
		# prob2lts-seq --zocket-prefix=/tmp/ltsmin-112213- --no-close spec/B/RushHour_v2_TLC.mch -rsc,bg,vcm --regroup-exit

		if [ $(grep "prob2lts-seq --zocket-prefix=/tmp/ltsmin-" $i | wc -l) = 1 ]
		then			
			line=$(grep "prob2lts-seq --zocket-prefix=/tmp/ltsmin-" $i)			
			echo $line | awk '{
				printf "\"%s\"", $4
			}'
		else
			errcho "could not find prob filename"
			exit 1
		fi		
	else
		if [ $(grep "Loading model from" $i | wc -l) = 1 ]
		then
			awk '{
				if ($2" "$3" "$4 == "Loading model from") printf "\"%s\"", $5
			}' $i		
		fi	
	fi
	echo -n ,
	
	# check if Noack
	has_noack=0
	grep "Noack" $i > /dev/null
	if [ $? = 0 -a $frontend = "pnml2lts-seq" ]
	then
		has_noack=1
	fi
	
	# print graph
	if [ $(grep "Regroup Bipartite Graph" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4 == "Regroup Bipartite Graph") printf "\"bipartite\""
		}' $i
	elif [ $(grep "Regroup Total graph" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4 == "Regroup Total graph") printf "\"total\""
		}' $i
	else
		if [ $has_noack = 1 -o $(grep "Regroup FORCE" $i | wc -l) = 1 ]
		then
			echo -n \"bipartite\"
		else
			echo -n \"none\"
		fi
	fi	
	echo -n ,
	
	# print reordering
	has_reordering=1
	if [ $(grep "Regroup Boost's Cuthill McKee" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4" "$5 == "Regroup Boost\x27s Cuthill McKee") printf "\"bcm\""
		}' $i
	elif [ $(grep "Regroup Boost's Sloan" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4 == "Regroup Boost\x27s Sloan") printf "\"bs\""
		}' $i
	elif [ $(grep "Regroup Boost's King" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4 == "Regroup Boost\x27s King") printf "\"bk\""
		}' $i
	elif [ $(grep "Regroup ViennaCL's Cuthill McKee" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4" "$5 == "Regroup ViennaCL\x27s Cuthill McKee") printf "\"vcm\""
		}' $i
	elif [ $(grep "Regroup ViennaCL's Advanced Cuthill McKee" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4" "$5" "$6 == "Regroup ViennaCL\x27s Advanced Cuthill McKee") printf "\"vacm\""
		}' $i
	elif [ $(grep "Regroup ViennaCL's Gibbs Poole Stockmeyer" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3" "$4" "$5" "$6 == "Regroup ViennaCL\x27s Gibbs Poole Stockmeyer") printf "\"vgps\""
		}' $i
	elif [ $(grep "Regroup FORCE" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3 == "Regroup FORCE") printf "\"f\""
		}' $i
	else
		has_reordering=0
		if [ $has_noack = 1 ]
		then
			grep "Noack1" $i > /dev/null
			if [ $? = 0 ]
			then
				echo -n \"Noack1\"
			else
				grep "Noack2" $i > /dev/null
				if [ $? = 0 ]
				then
					echo -n \"Noack2\"
				else
					errcho "unknown ordering"
					exit 1
				fi
			fi
		else
			echo -n \"none\"
		fi
	fi	
	echo -n ,

	# print NES
	if [ $(grep "Normalized Event Span:" $i | wc -l) = 1 ]
	then
		awk '{
			if ($1" "$2" "$3 == "Normalized Event Span:") printf "\"%s\"", $4
		}' $i
	fi	
	echo -n ,

	# print NWES
	if [ $(grep "Normalized Weighted Event Span," $i | wc -l) = 1 ]
	then
		awk '{
			if ($1" "$2" "$3" "$4 == "Normalized Weighted Event Span,") printf "\"%s\"", $7
		}' $i
	fi	
	echo -n ,

	# print time
	if [ $has_reordering = 0 ]
	then
		if [ $(grep "Computing Noack. order took" $i | wc -l) = 1 ]
		then
			awk '{
				if ($2" "$3" "$4" "$5 == "Computing Noack1 order took" || $2" "$3" "$4" "$5 == "Computing Noack2 order took") printf "\"%s\"", $6
			}' $i
		else
			echo -n 0
		fi
	else
		if [ $(grep "Regrouping took" $i | wc -l) = 1 ]
		then
			awk '{
				if ($2" "$3 == "Regrouping took") printf "\"%s\"", $6
			}' $i
		else
			errcho bug
			exit 1			
		fi
	fi
	echo -n ,
	
	# print bandwidth
	if [ $(grep "bandwidth:" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2 == "bandwidth:") printf "\"%s\"", $3
		}' $i
	fi	
	echo -n ,
	
	# print profile
	if [ $(grep "profile:" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2 == "profile:") printf "\"%s\"", $3
		}' $i
	fi	
	echo -n ,
	
	# print span
	if [ $(grep "span:" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2 == "span:") printf "\"%s\"", $3
		}' $i
	fi	
	echo -n ,
	
	# print average wavefront
	if [ $(grep "average wavefront:" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3 == "average wavefront:") printf "\"%s\"", $4
		}' $i
	fi	
	echo -n ,
	
	# print Root Mean Square wavefront
	if [ $(grep "RMS wavefront:" $i | wc -l) = 1 ]
	then
		awk '{
			if ($2" "$3 == "RMS wavefront:") printf "\"%s\"", $4
		}' $i
	fi
	
	# print new line
	echo ""
done