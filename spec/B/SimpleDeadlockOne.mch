MACHINE SimpleDeadlockOne
VARIABLES
n, m
INVARIANT
n : NAT &
m : 0..100
INITIALISATION
n :=0 || m := 0
OPERATIONS
on = PRE n = 1  or m < 100 THEN n:=0 || m := m+1 END
END
