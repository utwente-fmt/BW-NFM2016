MACHINE           Doors

SETS              DOOR; POSITION = {open, closed}

DEFINITIONS
                  scope_DOOR == 1..15
                  
VARIABLES         position

INVARIANT         position : DOOR --> POSITION

INITIALISATION   position := %x.(x : DOOR | closed)

OPERATIONS

  opening(dd) = 
  PRE dd : DOOR THEN position(dd) := open END;

  closedoor(dd) = 
  PRE dd : DOOR THEN position(dd) := closed END

END

