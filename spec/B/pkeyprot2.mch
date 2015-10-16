MACHINE pkeyprot2

DEFINITIONS
GOAL == statusAlice=s4 & statusBob=s14 & aliceRecName=userBob & bobSenderName=userAlice
/* This goal represents a correct run without intruder.
   (The known attack can be found using temporal model checking
   to find invariant violations) */
   ; SET_PREF_MAX_OPERATIONS == 40

SETS
 MTYPE={nil, userAlice, userBob, pubKeyA, pubKeyB, nonceA, nonceB, initmsg, replymsg, successmsg,
                        userEve, pubKeyEve, nonceEve};
 STATUS={s0,s1,s2,s3,s4,s5,s11,s12,s13,s14}

VARIABLES
  aliceRecName,      /* the name of Alice's partner */
  aliceRecPubKey,    /* the public key of Alice's partner */
  aliceRecNonce,     /* the nonce of Alice's partner */
  bobSenderName,   /* the name of Bob's partner */
  bobSenderPubKey, /* the public key of Bob's partner */
  bobSenderNonce,  /* the nonce of Bob's partner */
  eveStoredNonces, /* contains all the nonces that Eve has stored (except its own nonce) */
  eveStoredPubKeys,/* contains all the public keys that Eve has stored (except its own) */
  eveStoredPacket, /* contains a packet that Eve has stored */
  eveStoredPacketKey,/* contains the encryption key of the packet that Eve has stored */
  eveLasttype,eveLastkey,eveLastreceiver,eveLastpacket, /* the type,key,receiver and packet
                    of the last message that was sended by Eve
                    (to avoid Eve receiving messages sended by itself)*/
  networkMsg,    /* contains the message that is on the network */
  networkMsgType,/* contains the type of the message that is on the network */
  networkReceiver,/*contains the receiver of the message that is on the network */
  networkKey,    /* contains the type of the message that is on the network */
  statusAlice, statusBob          /* status: 0 =start/reset/waiting,
                                       1 =key requested for sending initmsg
                                       2 =init message sended (waiting for reply),
                                       3 =reply message received,
                                       4 =success (success message sended);
                                       11=init message received,
                                       12=key requested for reply message,
                                       13=reply message sended (waiting for success message),
                                       14=success (success message received) */
  /* please note that Alice can only initiate a session with Bob or Eve and Bob can only response to Alice or Eve
     and both Alice and Bob are always honest;
     Eve (the intruder) may do everything at all times (and so no status is needed) */

  /* encrypted content of the messages:
      - initmsg packet contains sender's nonce and sender's name
      - replymsg packet contains the nonce that was recieved with the initmsg and the sender's nonce
      - successmsg packet contains the nonce that was recieved with the replymsg
     Assumption for this model: attacs against encrypted messages are not possible.
  */

INVARIANT
 bobSenderName:MTYPE & bobSenderPubKey:MTYPE & bobSenderNonce:MTYPE &
 aliceRecNonce:MTYPE & aliceRecName:MTYPE & aliceRecPubKey:MTYPE &
 eveStoredNonces <: MTYPE & eveStoredPubKeys: MTYPE+->MTYPE &
 networkMsg:seq(MTYPE) & networkMsgType:MTYPE &
 networkReceiver:MTYPE & networkKey:MTYPE &
 eveStoredPacketKey: MTYPE & eveStoredPacket: seq(MTYPE) &
 eveLasttype:MTYPE&eveLastreceiver:MTYPE&eveLastkey:MTYPE&eveLastpacket:seq(MTYPE) &
 statusAlice:STATUS & statusBob:STATUS
 & ( (statusAlice=s4 & statusBob=s14 & bobSenderName=userAlice)=>(aliceRecName=userBob) )
 & ( (statusAlice=s4 & statusBob=s14 & aliceRecName=userBob)   =>(bobSenderName=userAlice) )
 & ( (statusAlice=s4 & aliceRecName=userBob)   =>(nonceA/:eveStoredNonces) )
 & ( (statusBob=s14& bobSenderName=userAlice)=>(nonceB/:eveStoredNonces) )


INITIALISATION bobSenderName, bobSenderPubKey, bobSenderNonce := nil,nil,nil
 || aliceRecName, aliceRecPubKey, aliceRecNonce := nil,nil,nil
 || eveStoredNonces,eveStoredPubKeys,eveStoredPacket,eveStoredPacketKey := {},{},<>,nil
 || eveLasttype,eveLastreceiver,eveLastkey,eveLastpacket:=nil,nil,nil,<>
 || networkMsg,networkMsgType,networkReceiver,networkKey := <>,nil,nil,nil
 || statusAlice,statusBob := s0,s0

OPERATIONS
 /* handling of key request (and response) messages */
 req,key<--KeyReqMsg(sender,request) =
  PRE ((statusAlice=s0 & sender=userAlice) or (statusBob=s11 & sender=userBob & request=bobSenderName) or 
       (sender=userEve & request/:dom(eveStoredPubKeys))) & sender:MTYPE &
      request:MTYPE & request/=sender & (request=userAlice or request=userBob or request=userEve)
      & (statusAlice/=s4 or statusBob/=s14) /* to avoid deadlocks */
      THEN
        IF sender=userAlice THEN
            statusAlice:=s1 || aliceRecName := request ||
            IF request = userBob THEN req:=request || key:=pubKeyB || aliceRecPubKey:=pubKeyB
            ELSIF request = userEve THEN req:=request || key:=pubKeyEve || aliceRecPubKey:=pubKeyEve END
        ELSIF sender=userBob THEN
            statusBob:=s12 || 
            IF request = userAlice THEN req:=request || key:=pubKeyA || bobSenderPubKey:=pubKeyA
            ELSIF request = userEve THEN req:=request || key:=pubKeyEve || bobSenderPubKey:=pubKeyEve END
        ELSIF sender=userEve THEN
            IF request = userBob THEN req:=request || key:=pubKeyB || 
                                    eveStoredPubKeys := eveStoredPubKeys \/ {userBob |-> pubKeyB}
            ELSIF request = userAlice THEN req:=request || key:=pubKeyA ||
                                    eveStoredPubKeys := eveStoredPubKeys \/ {userAlice |-> pubKeyA}
            END
        END
  END;


 /* Alice */
 ASendInitMsg(type,receiver,key,packet) =
     PRE statusAlice=s1 & receiver=aliceRecName & receiver/=nil & key=aliceRecPubKey & type:MTYPE &
         packet:seq(MTYPE) & packet=[nonceA,userAlice] & type=initmsg THEN
           networkMsgType:=type||networkMsg:=packet /*put the message on the network*/
           ||networkReceiver:=receiver||networkKey:=key
           || statusAlice:=s2
     END;


 ASendSuccMsg(type,receiver,key,packet) =
     PRE statusAlice=s3 & receiver=aliceRecName & receiver/=nil & key=aliceRecPubKey & type:MTYPE &
         packet:seq(MTYPE)&packet=[aliceRecNonce] & packet/=<> & type=successmsg THEN
             networkMsgType:=type||networkMsg:=packet /*put the message on the network*/
             ||networkReceiver:=receiver||networkKey:=key
             ||statusAlice:=s4 /*Alice believes that she's talking to the partner stored in aliceRecName*/
     END;

 AGetsReplyMsg(type,receiver,key,packet) =
     PRE statusAlice=s2 & receiver=userAlice & type=networkMsgType & type=replymsg
         & key=networkKey & receiver=networkReceiver
         & key=pubKeyA & packet=networkMsg & packet/=<>
         & first(packet)=nonceA THEN
              aliceRecNonce:=last(packet)||
              statusAlice:=s3
     END;


 /* Bob */
 BGetsInitMsg(type,receiver,key,packet) =
     PRE statusBob=s0 & receiver=userBob & type=networkMsgType & type=initmsg
         & key=networkKey & receiver=networkReceiver
         & key=pubKeyB & packet=networkMsg & packet/=<> THEN
              bobSenderName:=last(packet)||bobSenderNonce:=first(packet)||
              statusBob:=s11
     END;

 BGetsSuccMsg(type,receiver,key,packet) =
     PRE statusBob=s13 & receiver=userBob & type=networkMsgType
         & type=successmsg & key=pubKeyB
         & key=networkKey & receiver=networkReceiver & packet=networkMsg & packet/=<> 
         & first(packet)=nonceB /*own nonce must be received*/ THEN
              statusBob:=s14 /* Bob believes that he's talking to the partner stored in bobSenderName */
     END;

 BSendReplyMsg(type,receiver,key,packet) =
     PRE statusBob=s12 & receiver=bobSenderName & receiver/=nil & key=bobSenderPubKey &  type:MTYPE&
         key/=nil & packet:seq(MTYPE) & packet=[bobSenderNonce,nonceB] & type=replymsg THEN
             networkMsgType:=type||networkMsg := packet /* put the message on the network */
             ||networkReceiver:=receiver||networkKey:=key
             ||statusBob:=s13
     END;


 /* Eve, the intruder may receive and store everything */
 XGetsMsg(type,receiver,key,packet) =
     PRE type=networkMsgType & type/=nil & packet:seq(MTYPE) & packet=networkMsg & packet/=<>
         & key=networkKey & receiver=networkReceiver
         & (type/=eveLasttype or receiver/=eveLastreceiver or key/=eveLastkey or packet/=eveLastpacket)
         & (statusAlice/=s4 or statusBob/=s14) /* to avoid deadlocks */
         THEN
             /* store the message*/
             eveStoredPacket:=packet||eveStoredPacketKey:=key
             ||
             IF ((key=pubKeyEve)) THEN /* Eve can decrypt the packet */
                 /*store nonces*/
                 IF ((type=initmsg)) THEN 
                     IF ((first(packet)=nonceA)or(first(packet)=nonceB)) THEN
                       eveStoredNonces:=eveStoredNonces\/{first(packet)}
                     END
                 ELSIF type=replymsg THEN
                     IF ((first(packet)=nonceA)or(first(packet)=nonceB)) & ((last(packet)/=nonceA)&(last(packet)/=nonceB)) THEN
                       eveStoredNonces:=eveStoredNonces\/{first(packet)}
                     ELSIF ((first(packet)/=nonceA)&(first(packet)/=nonceB)) & ((last(packet)=nonceA)or(last(packet)=nonceB)) THEN
                       eveStoredNonces:=eveStoredNonces\/{last(packet)}
                     ELSIF ((first(packet)=nonceA)or(first(packet)=nonceB)) & ((last(packet)=nonceA)or(last(packet)=nonceB)) THEN
                           eveStoredNonces:=eveStoredNonces\/{first(packet)}\/{last(packet)} 
                     END
                 ELSIF type=successmsg THEN
                     IF ((first(packet)=nonceA)or(first(packet)=nonceB)) THEN
                       eveStoredNonces:=eveStoredNonces\/{first(packet)}
                     END
                 END
             END
     END;

 XSendsMsg(type,receiver,key,packet) =
     PRE type:MTYPE & (type=initmsg or type=replymsg or type=successmsg)
         & (statusAlice/=s4 or statusBob/=s14) /* to avoid deadlocks */
         & receiver:MTYPE & (receiver=userAlice or receiver=userBob)
         & packet:seq(MTYPE) & key:MTYPE
         & ((eveStoredPacket/=<>&eveStoredPacketKey/=nil & key=eveStoredPacketKey&packet=eveStoredPacket
                                                     & key/=pubKeyEve)
            or( /* assemble a message */
                 (key=pubKeyA <=>(receiver=userAlice)) & (key=pubKeyB <=> (receiver=userBob)) & key:ran(eveStoredPubKeys)
                 & (type=successmsg => ((packet=[nonceA])or(packet=[nonceB])or(packet=[nonceEve])
                                        )
                    )
                 & (type=initmsg => ((packet=[nonceA,userAlice])or(packet=[nonceB,userBob])or(packet=[nonceEve,userEve])
                                        )
                    )
                 & (type=replymsg => ((packet=[nonceA,nonceB])or(packet=[nonceA,nonceEve])or(packet=[nonceB,userAlice])
                                       or(packet=[nonceB,userEve])or(packet=[nonceEve,userAlice])or(packet=[nonceEve,userBob])
                                        )
                    )
                 & (nonceA/:eveStoredNonces => nonceA/:ran(packet))
                 & (nonceB/:eveStoredNonces => nonceB/:ran(packet))
               )
                 )
         THEN
             networkMsgType:=type||networkMsg := packet /* put the message on the network */
             ||networkReceiver:=receiver||networkKey:=key
             ||eveLasttype:=type||eveLastreceiver:=receiver||eveLastkey:=key||eveLastpacket:=packet
     END;


 Reset =
     PRE (statusAlice=s4 & statusBob=s14)
      THEN
       bobSenderName, bobSenderPubKey, bobSenderNonce := nil,nil,nil
       || aliceRecName, aliceRecPubKey, aliceRecNonce := nil,nil,nil
       || eveStoredNonces,eveStoredPubKeys,eveStoredPacket,eveStoredPacketKey := {},{},<>,nil
       || eveLasttype,eveLastreceiver,eveLastkey,eveLastpacket:=nil,nil,nil,<>
       || networkMsg,networkMsgType,networkReceiver,networkKey := <>,nil,nil,nil
       || statusAlice,statusBob := s0,s0
     END

END
