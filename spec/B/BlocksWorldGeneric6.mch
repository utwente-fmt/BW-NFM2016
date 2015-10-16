MACHINE BlocksWorldGeneric6
SETS
 Objects={a,b,c,d,e,f}
DEFINITIONS
      GOAL == (on = ongoal);
      ongoal == {a|->b, b|->c, c|->d, d|->e, e|->f};
      DIFF(A,TARGET) == (card(A-TARGET) - card(TARGET /\ A));
      HEURISTIC_FUNCTION == DIFF(on,ongoal);
VARIABLES on
INVARIANT
  on: Objects +-> Objects
INITIALISATION
  on := {a|->b, c|->a}
OPERATIONS
  move_on_table(obj) = PRE obj /: ran(on) & obj : dom(on) THEN
    on := {obj} <<| on
  END;
  move_on_object(obj,onobj) = PRE obj/:ran(on) & onobj /:ran(on) & obj /= onobj THEN
      on(obj) := onobj
  END
END