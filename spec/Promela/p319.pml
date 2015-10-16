#define true	1
#define false	0

bool busy[3];

chan   up0 = [1] of { byte };
chan   up1 = [1] of { byte };
chan   up2 = [1] of { byte };
chan down0 = [1] of { byte };
chan down1 = [1] of { byte };
chan down2 = [1] of { byte };

mtype = { start, attention, data, stop }

proctype station1(byte id; chan inp, out)
{	do
	:: inp?start ->
		atomic { !busy[id] -> busy[id] = true };
		out!attention;
		do
		:: inp?data -> out!data
		:: inp?stop -> break
		od;
		out!stop;
		busy[id] = false
	:: atomic { !busy[id] -> busy[id] = true };
		out!start;
		inp?attention;
		do
		:: out!data -> inp?data
		:: out!stop -> break
		od;
		inp?stop;
		busy[id] = false
	od
}
proctype station2(byte id; chan inp, out)
{   do
    :: inp?start ->
        atomic { !busy[id] -> busy[id] = true };
        out!attention;
        do
        :: inp?data -> out!data
        :: inp?stop -> break
        od;
        out!stop;
        busy[id] = false
    :: atomic { !busy[id] -> busy[id] = true };
        out!start;
        inp?attention;
        do
        :: out!data -> inp?data
        :: out!stop -> break
        od;
        inp?stop;
        busy[id] = false
    od
}
proctype station3(byte id; chan inp, out)
{   do
    :: inp?start ->
        atomic { !busy[id] -> busy[id] = true };
        out!attention;
        do
        :: inp?data -> out!data
        :: inp?stop -> break
        od;
        out!stop;
        busy[id] = false
    :: atomic { !busy[id] -> busy[id] = true };
        out!start;
        inp?attention;
        do
        :: out!data -> inp?data
        :: out!stop -> break
        od;
        inp?stop;
        busy[id] = false
    od
}
proctype station4(byte id; chan inp, out)
{   do
    :: inp?start ->
        atomic { !busy[id] -> busy[id] = true };
        out!attention;
        do
        :: inp?data -> out!data
        :: inp?stop -> break
        od;
        out!stop;
        busy[id] = false
    :: atomic { !busy[id] -> busy[id] = true };
        out!start;
        inp?attention;
        do
        :: out!data -> inp?data
        :: out!stop -> break
        od;
        inp?stop;
        busy[id] = false
    od
}
proctype station5(byte id; chan inp, out)
{   do
    :: inp?start ->
        atomic { !busy[id] -> busy[id] = true };
        out!attention;
        do
        :: inp?data -> out!data
        :: inp?stop -> break
        od;
        out!stop;
        busy[id] = false
    :: atomic { !busy[id] -> busy[id] = true };
        out!start;
        inp?attention;
        do
        :: out!data -> inp?data
        :: out!stop -> break
        od;
        inp?stop;
        busy[id] = false
    od
}
proctype station6(byte id; chan inp, out)
{   do
    :: inp?start ->
        atomic { !busy[id] -> busy[id] = true };
        out!attention;
        do
        :: inp?data -> out!data
        :: inp?stop -> break
        od;
        out!stop;
        busy[id] = false
    :: atomic { !busy[id] -> busy[id] = true };
        out!start;
        inp?attention;
        do
        :: out!data -> inp?data
        :: out!stop -> break
        od;
        inp?stop;
        busy[id] = false
    od
}


init {
	atomic {
		run station1(0, up2, down2);
		run station2(1, up0, down0);
		run station3(2, up1, down1);

		run station4(0, down0, up0);
		run station5(1, down1, up1);
		run station6(2, down1, up1)
	}
}

#define __instances_station1 1
#define __instances_station2 1
#define __instances_station3 1
#define __instances_station4 1
#define __instances_station5 1
#define __instances_station6 1
