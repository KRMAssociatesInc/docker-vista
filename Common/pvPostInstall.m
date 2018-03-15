pvPostInstall ; Platium VistA Post Install
 N R,STOP S (R,STOP)="DSI"
 N %
 F  S R=$O(^$ROUTINE(R)) Q:R=""  Q:$E(R,1,3)'=STOP  S %=##class(%Routine).Delete(R,2)
 ;
 N R,STOP S (R,STOP)="VEJD"
 N %
 F  S R=$O(^$ROUTINE(R)) Q:R=""  Q:$E(R,1,3)'=STOP  S %=##class(%Routine).Delete(R,2)
 ;
 N R,STOP S (R,STOP)="VEN"
 N %
 F  S R=$O(^$ROUTINE(R)) Q:R=""  Q:$E(R,1,3)'=STOP  S %=##class(%Routine).Delete(R,2)
 QUIT
