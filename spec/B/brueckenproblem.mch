MACHINE brueckenproblem

SETS
 PERSON={P1,P2,P3,P4};
 POSITION={origin,dest}

DEFINITIONS
  GOAL == ran(person_pos)={dest,dest,dest,dest}
   ; SET_PREF_MAX_OPERATIONS == 40
CONSTANTS timeNeeded,maxtime

PROPERTIES timeNeeded:PERSON-->1..8 & maxtime:NATURAL &
           timeNeeded={P1|->1}\/{P2|->2}\/{P3|->5}\/{P4|->8} &
           maxtime=15

VARIABLES person_pos, lamp, time

INVARIANT
 person_pos : PERSON --> POSITION & lamp:POSITION & time:NATURAL & time<=maxtime
 & ((ran(person_pos)={dest,dest,dest,dest}) => (time=maxtime))

INITIALISATION 
  ANY xx WHERE xx:PERSON-->{origin} THEN person_pos:=xx END ||
  lamp := origin ||
  time := 0

OPERATIONS

 st<--GetPos(name) = /*only for simulation*/
   PRE name:PERSON THEN
      st := person_pos(name)
   END;

 oneoverbridge(name) =
   PRE name:PERSON & person_pos(name)=lamp & time+timeNeeded(name)<=maxtime THEN
      IF lamp=origin THEN lamp,person_pos := dest,person_pos<+{name|->dest}
      ELSE lamp,person_pos := origin,person_pos<+{name|->origin}
      END
      || time:=time+timeNeeded(name)
   END;

 twooverbridge(name1,name2) =
   PRE name1:PERSON & name2:PERSON & name1 /= name2 & person_pos(name1)=lamp &
           person_pos(name2)=lamp & time+timeNeeded(name1)<=maxtime & time+timeNeeded(name2)<=maxtime THEN
      IF lamp=origin THEN lamp,person_pos := dest,person_pos <+ ({name1|->dest} \/ {name2|->dest})
      ELSE lamp,person_pos := origin,person_pos<+({name1|->origin}\/{name2|->origin})
      END ||
      time:=time+max({timeNeeded(name1),timeNeeded(name2)})
   END

END


