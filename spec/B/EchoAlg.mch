
MACHINE EchoAlg

SETS
 KNOTS  = {KNOTEN1,KNOTEN2,KNOTEN3,KNOTEN4};
 STATES = {WHITE, RED, GREEN}

DEFINITIONS
ASSERT_LTL == "GF{ran(state)={GREEN}}"

VARIABLES neighbours, kanten, state, explorerMsg, echoMsg, counter,
          shortestPathToInit, root

INVARIANT
  neighbours: KNOTS<->KNOTS
 /*neighbours: Ueber Kanten verbundene Knoten*/
 &
 kanten: KNOTS-->NAT
 /*kanten: Speichert fuer jeden Knoten die Anzahl Kanten*/
 &
 state: KNOTS-->STATES
 /*state: Zustand des Knoten (white/red/green).
   jeder Knoten hat genau einen Zustand (init:white)*/
 &
 explorerMsg: KNOTS<->KNOTS
 /*explorerMsg: Explorer messages, die gerade unterwegs von einem Knoten
   zu einem anderen Knoten sind.
   jeder Knoten kann mehrere Nachrichten senden und empfangen*/
 &
 echoMsg: KNOTS<->KNOTS
 /*explorerMsg: Echo messages, die gerade unterwegs von einem Knoten
   zu einem anderen Knoten sind.*/
 &
 counter: KNOTS-->NAT
 /*counter: Speichert fuer jeden Knoten den Zaehlerwert, mit dem eingegangene
    Nachrichten gezaehlt werden*/
 &
 shortestPathToInit: KNOTS+->KNOTS
 /*shortestPathToInit: Speichert für jeden Knoten den Knoten, von dem er zuerst etwas empfaengt.
   Ueber diesen Knoten laeuft der kuerzeste Weg zum Initialknoten.
   (Voreinstellung: undefiniert)*/
 &
 root: KNOTS>+>KNOTS
 /*ein Knoten ist Initialknoten. Wird nur fuer Ueberpruefung der Invarianten benoetigt.
   part.Injektion nur, weil root:KNOTS keine leere Variable root erlaubt,
   gespeichert wird ersatzweise eine Injektion auf sich selbst*/

 &
  /*allgemeine Invarianten*/
 /*sind alle Knoten inaktiv, dann sind auch keine Nachrichten auf den Kanten,
   ebenso wenn alle Knoten gruen sind (nach Terminierung)*/
  (((ran(state)={WHITE})or(ran(state)={GREEN})) <=> ((echoMsg={})&(explorerMsg={})))

 /*nach Terminierung muessen alle kuerzesten Pfade bekannt sein*/
 &((ran(state)={GREEN}) => 
       (  (((dom(shortestPathToInit))\/dom(root))=KNOTS))
       )
 

INITIALISATION
 neighbours:={KNOTEN1|->KNOTEN2}\/{KNOTEN1|->KNOTEN3}\/
            {KNOTEN2|->KNOTEN3}\/{KNOTEN3|->KNOTEN4}
 ||
 kanten:={KNOTEN1|->2}\/{KNOTEN2|->2}\/{KNOTEN3|->3}\/{KNOTEN4|->1}
 ||
 state:={KNOTEN1|->WHITE}\/{KNOTEN2|->WHITE}\/{KNOTEN3|->WHITE}
        \/{KNOTEN4|->WHITE}
 ||
 explorerMsg := {}
 ||
 echoMsg := {}
 ||
 counter := KNOTS*{0}
 ||
 shortestPathToInit:={}
 ||
 root := {}


OPERATIONS
 InitEchoAlg(initknoten) =
   PRE initknoten:KNOTS & RED/:ran(state) & GREEN/:ran(state) THEN
     state(initknoten):=RED /*Initialknoten rot markieren*/
     || root:={initknoten|->initknoten} /*Initialknoten merken (fuer Invariant)*/
     || /*Explorer-Nachrichten versenden an ueber alle Kanten*/
     explorerMsg := {initknoten}*ran({initknoten}<|neighbours)    
                 \/ {initknoten}*ran({initknoten}<|(neighbours~))
         /*weil die Kanten nur in eine Richtung in neighbours eingetragen werden*/
 END;

 GetExplorerMsg(sender,knoten) =
   PRE knoten:KNOTS & knoten:ran(explorerMsg) & sender:dom(explorerMsg)
       & {sender|->knoten}<:explorerMsg THEN
     IF (((counter(knoten))=0)&(state(knoten)=WHITE)&
          (kanten(knoten)>1)) THEN 
           /*erstmaliger Nachrichtenempfang; weitere Kanten vorhanden*/
       state(knoten):=RED /*Knoten rot markieren*/
      /*Explorer-Nachrichten versenden an ueber alle Kanten ohne Empfangskante
          und empfangene Nachricht aus explorerMsg herausnehmen*/
       ||explorerMsg := (explorerMsg - {sender|->knoten})
                   \/ {knoten}*(ran({knoten}<|neighbours)-{sender})
                   \/ {knoten}*(ran({knoten}<|(neighbours~))-{sender})
       ||shortestPathToInit(knoten):=sender
     ELSIF (((counter(knoten))=0)&(state(knoten)=WHITE)&
          (kanten(knoten)=1)) THEN 
           /*erstmaliger Nachrichtenempfang; KEINE weitere Kanten vorhanden*/
       state(knoten):=GREEN /*Knoten gruen markieren*/
       ||explorerMsg := (explorerMsg - {sender|->knoten})
       ||echoMsg := echoMsg\/{knoten|->sender} /*Echomsg. direkt an Sender*/
       ||shortestPathToInit(knoten):=sender
     ELSIF (counter(knoten)+1)<kanten(knoten) THEN /*noch nicht von allen was empfangen*/
       explorerMsg := (explorerMsg - {sender|->knoten})
     ELSIF ({knoten}<|shortestPathToInit)={} THEN
          /*knoten ist Initialknoten und hat ueber alle Kanten eine Nachricht empfangen*/
       explorerMsg := (explorerMsg - {sender|->knoten})
       ||state(knoten):=GREEN
     ELSE /*ueber alle Kanten eine Nachricht empfangen*/
       state(knoten):=GREEN /*Knoten gruen markieren*/
       ||explorerMsg := (explorerMsg - {sender|->knoten})
       ||echoMsg := echoMsg\/{knoten|->shortestPathToInit(knoten)}
     END
     ||counter(knoten):=counter(knoten)+1
 END;

 GetEchoMsg(sender,knoten) =
   PRE knoten:KNOTS & knoten:ran(echoMsg) & sender:dom(echoMsg)
       & {sender|->knoten}<:echoMsg THEN
     IF (counter(knoten)+1)<kanten(knoten) THEN /*noch nicht von allen was empfangen*/
       echoMsg := (echoMsg - {sender|->knoten})
     ELSIF ({knoten}<|shortestPathToInit)={} THEN
          /*knoten ist Initialknoten und hat ueber alle Kanten eine Nachricht empfangen*/
       echoMsg := (echoMsg - {sender|->knoten})
       ||state(knoten):=GREEN
     ELSE /*ueber alle Kanten eine Nachricht empfangen*/
       state(knoten):=GREEN /*Knoten gruen markieren*/
       ||echoMsg := (echoMsg - {sender|->knoten})
                  \/{knoten|->shortestPathToInit(knoten)}
     END
     ||counter(knoten):=counter(knoten)+1
 END;
 

 Reset =
   PRE ran(state)={GREEN} THEN
     /*wenn Algorithmus terminiert hat, reset ermoeglichen*/
     state:=dom(state)*{WHITE}
    || counter := KNOTS*{0}
    || shortestPathToInit:={}
   END


END
