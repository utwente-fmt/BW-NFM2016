MACHINE Hanoi6
SETS
 Stakes
DEFINITIONS
 GOAL == (!s.(s:Stakes & s/=dest => on(s) = <>));
/* 2.10 secs with ProB 1.3.2-rc1  
 With Alloy.als: 135,591ms */
 HEURISTIC_FUNCTION1 == card(on[Stakes-{dest}]);
 HEURISTIC_FUNCTION == (SIGMA(z).(z:ran(on(orig))|z) - SIGMA(z).(z:ran(on(dest))|z) );
 SET_PREF_SYMBOLIC == FALSE;
 scope_Stakes == 1..3;

CONSTANTS orig,dest,nrdiscs
PROPERTIES
 orig: Stakes & dest:Stakes & orig /= dest & nrdiscs = 6
VARIABLES on
INVARIANT
 on : Stakes --> seq(INTEGER)
INITIALISATION 
  on := %s.(s:Stakes & s /= orig | <>) \/ {orig |-> %x.(x:1..nrdiscs|x)}
OPERATIONS
  Move(from,to,disc) = PRE from:Stakes & on(from) /= <> &
                           to:Stakes & to /= from &
                           disc:NATURAL1 & disc = first(on(from)) &
                           (on(to) /= <> =>  first(on(to))> disc )
                       THEN
     on := on <+ { from |-> tail(on(from)), to |-> (disc -> on(to)) }
  END
END

