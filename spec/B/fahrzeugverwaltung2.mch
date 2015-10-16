MACHINE fahrzeugverwaltung2
DEFINITIONS
     SET_PREF_MAX_INITIALISATIONS == 400
   ; SET_PREF_MAX_OPERATIONS == 40
   ; scope_PERSON == 2
   ; scope_KFZ == 2
SETS
 PERSON;
 FAMILIE = {Meier, Mueller, Schulze};
 KFZ;
 MARKE = {VW, BMW, Audi, Volvo};
 ANS = {ja, nein}

VARIABLES
 pers_fam, kfzmarke, kfzbesitz

INVARIANT
 pers_fam: PERSON-->FAMILIE &
 kfzmarke: KFZ-->MARKE &
 kfzbesitz: KFZ+->PERSON

INITIALISATION
 pers_fam::PERSON-->FAMILIE
 || kfzmarke::KFZ-->MARKE
 || kfzbesitz:={}

OPERATIONS

 kfzkauf(pers,kfz) =
  PRE pers:PERSON & kfz:KFZ & kfz/:dom(kfzbesitz) THEN
    kfzbesitz:=kfzbesitz\/{kfz|->pers}
  END;

 kfzverkauf(pers,kfz) =
  PRE pers:PERSON & kfz:KFZ & {kfz|->pers}<:kfzbesitz THEN
    kfzbesitz:=kfzbesitz-{kfz|->pers}
  END;

 allekfzverkaufen(pers,kfz) =
  PRE pers:PERSON & kfz:KFZ & pers:ran(kfzbesitz) THEN
    kfzbesitz:=kfzbesitz|>>{pers}
  END;

 ans<--familienmarke(fam,marke) =
  PRE fam:FAMILIE & marke:MARKE THEN
   IF marke:(pers_fam~;kfzbesitz~;kfzmarke)[{fam}] THEN
     ans:=ja
   ELSE
     ans:=nein
   END
  END;

 ans<--markenbesitzer(pers,marke) =
  PRE pers:PERSON & marke:MARKE THEN
   IF marke:(kfzbesitz~;kfzmarke)[{pers}] THEN
     ans:=ja
   ELSE
     ans:=nein
   END
  END;

 ans<--autobesitzer(pers) =
  PRE pers:PERSON THEN
   IF pers:ran(kfzbesitz) THEN
     ans:=ja
   ELSE
     ans:=nein
   END
  END
END


