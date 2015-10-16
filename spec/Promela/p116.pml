byte state = 1;

proctype A()
{	(state == 1) -> state = state + 1;
	assert(state == 2)
}
proctype B()
{	(state == 1) -> state = state - 1;
	assert(state == 0)
}
init { run A(); run B() }

#define __instances_A 1
#define __instances_B 1
