MACHINE opMachine

VARIABLES
	x
INVARIANT
	x >= 0 & x <= 3
INITIALISATION
	x :: {1,2,3}
OPERATIONS
	op1 = 
		PRE x < 3 THEN x := x + 1 END;
	op2 = 
		PRE x >= 2 THEN x := x - 2 END
END