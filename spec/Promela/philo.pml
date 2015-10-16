mtype = { Fork };

#define N	9

chan fork[N] = [1] of {mtype};

active [N] proctype philosopher()
{
	fork[_pid]!Fork;	/* place one of the forks */
	nempty(fork[N-1]);	/* wait for last fork to be on table */
thinking:
	do
	:: fork[_pid]?Fork ->
		if
		:: fork[(_pid+1)%N]?Fork -> break
		:: fork[_pid]!Fork
		fi
	:: fork[(_pid+1)%N]?Fork ->
		if
		:: fork[_pid]?Fork -> break
		:: fork[(_pid+1)%N]!Fork
		fi
	od;
eating:
	atomic {
		fork[(_pid+1)%N]!Fork;
		fork[_pid]!Fork
	}
	goto thinking;
}

#if 0
	N=10
	cc -O2 -o pan -DNOREDUCE -DSAFETY -DMEMLIM=1600 pan.c
	time ./pan -m78000
	8.20364M states
	109.296s utime
	496.825M mem

	cc -O2 -o pan -DNOREDUCE -DSAFETY -DMEMLIM=1600 -DDUAL_CORE -DDUAL_STATE -DVMAX=100 -DCYGWIN pan.c
	8.2039M states (WHY IS THIS DIFFERENT? -- in part because of missing cs, but there's more)
	99.124s utime (WHY SO HIGH? -- swapping)
	635.310M mem	(two 32Mb queues are extra)

	N=9
	1.64088M states
	11.874s utime
	94.911M mem
	depth 26294

	cc -O2 -o pan -DNOREDUCE -DSAFETY -DMEMLIM=160 -DDUAL_CORE -DDUAL_STATE -DVMAX=100 -DCYGWIN pan.c
	time ./pan -m27000 -z16
	1.64092M states (Different!)
	12.515s utime (Longer!)
	232.020 M (both cpu's combined -- each separately is below 160Mb)
	depth 24020
#endif
