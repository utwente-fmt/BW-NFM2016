/*
 * PROMELA Validation Model
 * FLOW CONTROL LAYER VALIDATION
 */

#define LOSS		0	/* message loss   */
#define DUPS		0	/* duplicate msgs */
#define QSZ		2	/* queue size     */

mtype = {
	red, white, blue,
	abort, accept, ack, sync_ack, close, connect,
	create, data, eof, open, reject, sync, transfer,
	FATAL, NON_FATAL, COMPLETE
	}

chan ses_to_flow[2] = [QSZ] of { byte, byte };
chan flow_to_ses[2] = [QSZ] of { byte, byte };
chan dll_to_flow[2] = [QSZ] of { byte, byte };

#include "App.F.flow_cl.h"
#include "p327.upper.h"

init
{
	atomic {
	  run fc(0); run fc(1);
	  run upper()
	}
}

#define __instances_fc 2
#define __instances_upper 1
