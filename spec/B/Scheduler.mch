MODEL Scheduler
SETS
 PROCESSES; STATE = {idle, ready, active}
VARIABLES state, queue
INVARIANT
state : PROCESSES +-> STATE
& queue : iseq(PROCESSES)
& card(state~[{active}]) <= 1
& !x.(x : ran(queue) => state(x) = ready)   
INITIALISATION state := {} || queue := []
OPERATIONS
  new(p) = 
	PRE 	p /: dom(state) 
	THEN 
		state := state \/ {(p,idle)}
	END;

  del(p) = 
	PRE 
		p : dom(state)
		& state(p) = idle 
	THEN 
		state := {p} <<| state 
	END;

  addToQueue(p) = 
	PRE 
		p : dom(state) & state(p) = idle
	THEN 
		state(p) := ready	
		|| queue := queue <- p 
	END;

 enter = 
	PRE
		queue /= []
		& state~[{active}] = {}
	THEN
		state(first(queue)) := active
		|| queue := tail(queue)	
	END;

 leave(p) =
	PRE
		p : dom(state)
		& state(p) = active			
	THEN
		state(p) := idle
	END
END

