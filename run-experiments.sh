#!/bin/bash

#GRAPHS="bg tg"
#ALGS="bcm bk bs vcm vacm vgps"

GRAPHS="bg tg"
ALGS="bcm bk bs vcm vacm vgps"

MAXMEM=4000000
MAXTIME=3600

PARTITION=r415
SRUN="srun -p$PARTITION -n1 -t$(($MAXTIME / 60 + 1)) $SRUNOPTS"
MEMTIME="memtime -c$MAXTIME -m$MAXMEM"

MAXQUEUELEN=2000
USER="meijerjjg"

wait_for_queue() { 
	while [ $(squeue -u$USER -h -o "%i" | wc -l) -gt $MAXQUEUELEN ]
	do
		sleep 3
	done
}

get_binary() {		
		case $1 in	
			"pnml")
			binary="pnml2lts-seq"
			;;
			"mcrl2")
			binary=""
			;;
			"lps")
			binary="lps2lts-seq --mcrl2-rewriter=jitty"
			;;
			"mch")
			binary="prob2lts-seq --zocket-prefix=/tmp/ltsmin-$2- --no-close"
			;;
			"dve")
			binary="dve2lts-seq"
			;;
			"pm"|"pr"|"promela"|"prom"|"prm"|"pml"|"c")
			binary=""
			;;
			"spins")
			binary="prom2lts-seq"
			;;
			*)
			errcho "I do not know what to do with $fullfile"
			exit 1
			;;
		esac
		echo $binary
}

errcho() { echo "$@" 1>&2; }

iterations=0
experiments=0

to_print=0

print_status() {
	errcho "#############################"
	errcho "# iterations: " $iterations
	errcho "# experiments: " $experiments
	errcho "#############################"
}

# run for statistics
for arg in "$@"
do
	for fullfile in $(find "$arg" -type f)
	do
		filename=$(basename "$fullfile")
		extension="${filename##*.}"
		filename="${filename%.*}"
		
		binary=$(get_binary "$extension" "$experiments")
		if [ ${#binary} = 0 ]
		then
			continue
		fi
		
		# run without reordering
		command="$binary $fullfile -rsc,bn,mm --regroup-exit --graph-metrics"
		if [ ${#SRUNOPTS} -gt 0 ]
	  	then
	  		echo '#!/bin/bash' > "command-$experiments"
	  		echo "echo statistics run" >> "command-$experiments" 
	  		echo "echo $command" >> "command-$experiments"
	  		echo hostname >> "command-$experiments"
			  		
	  		if [ "$extension" = "mch" ]; then
	  			echo "probcli $fullfile -ltsmin2 /tmp/ltsmin-$experiments.probz &" >> "command-$experiments"
	  			echo 'probid=$!' >> "command-$experiments"
	  			echo 'sleep 3' >> "command-$experiments"
				command="$binary /tmp/ltsmin-$experiments.probz -rsc,bn,mm --regroup-exit --graph-metrics"
	  		fi
	  		
	  		echo "$MEMTIME $command" >> "command-$experiments"
			  		
	  		if [ "$extension" = "mch" ]; then
	  			echo 'kill -9 $probid' >> "command-$experiments"
	  		fi
			  		
	  		echo "rm command-$experiments" >> "command-$experiments"
	  		chmod +x "command-$experiments"
	  		eval "$SRUN command-$experiments &"
	  		wait_for_queue
		else
			eval $command
		fi
		
		experiments=$(($experiments + 1))
		print_status
		
		# run with FORCE reordering
		command="$binary $fullfile -rsc,f,mm --regroup-exit"
		if [ ${#SRUNOPTS} -gt 0 ]
	  	then
	  		echo '#!/bin/bash' > "command-$experiments"
	  		echo "echo statistics run" >> "command-$experiments" 
	  		echo "echo $command" >> "command-$experiments"
	  		echo hostname >> "command-$experiments"
			  		
	  		if [ "$extension" = "mch" ]; then
	  			echo "probcli $fullfile -ltsmin2 /tmp/ltsmin-$experiments.probz &" >> "command-$experiments"
	  			echo 'probid=$!' >> "command-$experiments"
	  			echo 'sleep 3' >> "command-$experiments"
				command="$binary /tmp/ltsmin-$experiments.probz -rsc,f,mm --regroup-exit --graph-metrics"
	  		fi
	  		
	  		echo "$MEMTIME $command" >> "command-$experiments"
			  		
	  		if [ "$extension" = "mch" ]; then
	  			echo 'kill -9 $probid' >> "command-$experiments"
	  		fi
			  		
	  		echo "rm command-$experiments" >> "command-$experiments"
	  		chmod +x "command-$experiments"
	  		eval "$SRUN command-$experiments &"
	  		wait_for_queue
		else
			eval $command
		fi
		
		experiments=$(($experiments + 1))
		print_status
		
		# run with Noack
		if [ "$extension" = "pnml" ]
 		then 
 			# Noack1
			command="$binary $fullfile -rsc,bn,mm --noack=1 --regroup-exit --graph-metrics"
			if [ ${#SRUNOPTS} -gt 0 ]
		  	then
		  		echo '#!/bin/bash' > "command-$experiments"
		  		echo "echo statistics run" >> "command-$experiments" 
		  		echo "echo $command" >> "command-$experiments"
		  		echo hostname >> "command-$experiments"		  		
		  		echo "$MEMTIME $command" >> "command-$experiments"				  		
		  		echo "rm command-$experiments" >> "command-$experiments"
		  		chmod +x "command-$experiments"
		  		eval "$SRUN command-$experiments &"
		  		wait_for_queue
			else
				eval $command
			fi
			
			experiments=$(($experiments + 1))
			print_status
			
			# Noack2
			command="$binary $fullfile -rsc,bn,mm --noack=2 --regroup-exit --graph-metrics"
			if [ ${#SRUNOPTS} -gt 0 ]
		  	then
		  		echo '#!/bin/bash' > "command-$experiments"
		  		echo "echo statistics run" >> "command-$experiments" 
		  		echo "echo $command" >> "command-$experiments"
		  		echo hostname >> "command-$experiments"		  		
		  		echo "$MEMTIME $command" >> "command-$experiments"				  		
		  		echo "rm command-$experiments" >> "command-$experiments"
		  		chmod +x "command-$experiments"
		  		eval "$SRUN command-$experiments &"
		  		wait_for_queue
			else
				eval $command
			fi
			
			experiments=$(($experiments + 1))
			print_status
		fi
		
		# run with reordering
		for graph in $GRAPHS
		do
			for alg in $ALGS
			do
				command="$binary $fullfile -rsc,$graph,$alg,mm --regroup-exit --graph-metrics"
				if [ ${#SRUNOPTS} -gt 0 ]
			  	then
	  				echo '#!/bin/bash' > "command-$experiments"
			  		echo "echo statistics run" >> "command-$experiments" 
			  		echo "echo $command" >> "command-$experiments"
			  		
			  		if [ "$extension" = "mch" ]; then
			  			echo "probcli $fullfile -ltsmin2 /tmp/ltsmin-$experiments.probz &" >> "command-$experiments"
			  			echo 'probid=$!' >> "command-$experiments"
	  					echo 'sleep 3' >> "command-$experiments"
						command="$binary /tmp/ltsmin-$experiments.probz -rsc,$graph,$alg,mm --regroup-exit --graph-metrics"
			  		fi
			  		
			  		echo hostname >> "command-$experiments"
			  		echo "$MEMTIME $command" >> "command-$experiments"
			  		
			  		if [ "$extension" = "mch" ]; then
			  			echo 'kill -9 $probid' >> "command-$experiments"
			  		fi
			  		
	  				echo "rm command-$experiments" >> "command-$experiments"
			  		chmod +x "command-$experiments"
			  		eval "$SRUN command-$experiments &"
			  		wait_for_queue
				else
					eval $command
				fi
				experiments=$(($experiments + 1))
				print_status
			done
		done
	done
done

iterations=$(($iterations + 1))

# run for performance
for i in {1..10}
do
	for arg in "$@"
	do
		for fullfile in $(find "$arg" -type f)
		do
			filename=$(basename "$fullfile")
			extension="${filename##*.}"
			filename="${filename%.*}"
			
			binary=$(get_binary "$extension" "$experiments")
			if [ ${#binary} = 0 ]
			then
				continue
			fi
		
			# run with Noack
			if [ "$extension" = "pnml" ]
	 		then 
	 			# Noack1
				command="$binary $fullfile --noack=1 --regroup-exit"
				if [ ${#SRUNOPTS} -gt 0 ]
			  	then
			  		echo '#!/bin/bash' > "command-$experiments"
			  		echo "echo performance run" >> "command-$experiments" 
			  		echo "echo $command" >> "command-$experiments"
			  		echo hostname >> "command-$experiments"		  		
			  		echo "$MEMTIME $command" >> "command-$experiments"				  		
			  		echo "rm command-$experiments" >> "command-$experiments"
			  		chmod +x "command-$experiments"
			  		eval "$SRUN command-$experiments &"
			  		wait_for_queue
				else
					eval $command
				fi
				
				experiments=$(($experiments + 1))
				print_status
				
				# Noack2
				command="$binary $fullfile --noack=2 --regroup-exit"
				if [ ${#SRUNOPTS} -gt 0 ]
			  	then
			  		echo '#!/bin/bash' > "command-$experiments"
			  		echo "echo performance run" >> "command-$experiments" 
			  		echo "echo $command" >> "command-$experiments"
			  		echo hostname >> "command-$experiments"		  		
			  		echo "$MEMTIME $command" >> "command-$experiments"				  		
			  		echo "rm command-$experiments" >> "command-$experiments"
			  		chmod +x "command-$experiments"
			  		eval "$SRUN command-$experiments &"
			  		wait_for_queue
				else
					eval $command
				fi
				
				experiments=$(($experiments + 1))
				print_status
			fi
			
			# run with FORCE reordering
			command="$binary $fullfile -rsc,f --regroup-exit"
			if [ ${#SRUNOPTS} -gt 0 ]
		  	then
  				echo '#!/bin/bash' > "command-$experiments"
		  		echo "echo performance run" >> "command-$experiments" 
		  		echo "echo $command" >> "command-$experiments"
		  		echo hostname >> "command-$experiments"
		  		
		  		if [ "$extension" = "mch" ]; then
		  			echo "probcli $fullfile -ltsmin2 /tmp/ltsmin-$experiments.probz &" >> "command-$experiments"
		  			echo 'probid=$!' >> "command-$experiments"				  			
  						echo 'sleep 3' >> "command-$experiments"
					command="$binary /tmp/ltsmin-$experiments.probz -rsc,f --regroup-exit"
		  		fi
		  		
		  		echo "$MEMTIME $command" >> "command-$experiments"
	  		
		  		if [ "$extension" = "mch" ]; then
		  			echo 'kill -9 $probid' >> "command-$experiments"
			  		fi
		  		
  					echo "rm command-$experiments" >> "command-$experiments"
		  		chmod +x "command-$experiments"
		  		eval "$SRUN command-$experiments &"
		  		wait_for_queue
			else
				eval $command
			fi
			experiments=$(($experiments + 1))
			print_status
			
			# run with reordering
			for graph in $GRAPHS
			do
				for alg in $ALGS
				do
					command="$binary $fullfile -rsc,$graph,$alg --regroup-exit"
					if [ ${#SRUNOPTS} -gt 0 ]
				  	then
	  					echo '#!/bin/bash' > "command-$experiments"
				  		echo "echo performance run" >> "command-$experiments" 
				  		echo "echo $command" >> "command-$experiments"
				  		echo hostname >> "command-$experiments"
				  		
				  		if [ "$extension" = "mch" ]; then
				  			echo "probcli $fullfile -ltsmin2 /tmp/ltsmin-$experiments.probz &" >> "command-$experiments"
				  			echo 'probid=$!' >> "command-$experiments"				  			
	  						echo 'sleep 3' >> "command-$experiments"
							command="$binary /tmp/ltsmin-$experiments.probz -rsc,$graph,$alg --regroup-exit"
				  		fi
				  		
				  		echo "$MEMTIME $command" >> "command-$experiments"
			  		
				  		if [ "$extension" = "mch" ]; then
				  			echo 'kill -9 $probid' >> "command-$experiments"
				  		fi
			  		
	  					echo "rm command-$experiments" >> "command-$experiments"
				  		chmod +x "command-$experiments"
				  		eval "$SRUN command-$experiments &"
				  		wait_for_queue
					else
						eval $command
					fi
					experiments=$(($experiments + 1))
					print_status
				done
			done
		done
	done
	
	iterations=$(($iterations + 1))
done
