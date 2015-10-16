MACHINE opMachine2

VARIABLES
	x, y
INVARIANT
	x >= 0 & x <= 3 & y:{3,4,5}
INITIALISATION
	x :: {1,2,3} || y := 3
OPERATIONS
	op1 = 
		PRE x < 3 THEN x := x + 1 || y := 4 END;
	op2 = 
		PRE x >= 2 THEN x := x - 2 || y := 5 END
END
