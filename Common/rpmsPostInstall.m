rpmsPostInstall ; OSE/SMH - rpmsPostInstall ;2017-12-08  10:38 AM
 ;
 D DT^DICRW
 ;
 ; 1. Fix %RCR in RPMS which is coded with MSM or Cache in mind
 K ^TMP($J)
 S DIF="^TMP($J,",XCNP=0,X="DIRCR" X ^%ZOSF("LOAD")
 N ENL S ENL=0
 N I F I=1:1 I $E(^TMP($J,I,0),1,8)="STORLIST" S ENL=I QUIT
 I 'ENL W "CONFIG FAILED",! QUIT
 S ^TMP($J,ENL,0)="STORLIST G IHS  ; Changed by OSEHRA RPMS Installer"
 S DIE=DIF,XCN=0,X="DIRCR" X ^%ZOSF("SAVE")
 ; 
 ; 2. Stop Taskman
 D MES^XPDUTL("Stopping Taskman...")
 D GROUP^ZTMKU("SSUB(NODE)")
 D GROUP^ZTMKU("SMAN(NODE)")
 D MES^XPDUTL("Waiting around until Taskman reports it's stopped")              
 F  W "." Q:($$TM^%ZTLOAD=0)  H 1                                               
 ;
 ; 3. Stop all other tasks
 D HALTALL^ZSY
 ;
 ; 4. run KBANTCLN with specific parameters
 D START^KBANTCLN("ROU","RPMS",9999,"FOIA RPMS","FOIA.RPMS.IHS.GOV")
 ;
 ; 5. start Taskman
 D MES^XPDUTL("Starting Taskman...")
 D ^ZTMB
 ;
 ; 6. Fix RPMS Site File for GT.M
 D MES^XPDUTL("Fixing RPMS SITE")
 N FDA,DIERR
 S FDA(9999999.39,"1,",.21)="UNIX" ; OS
 S FDA(9999999.39,"1,",1)="/tmp/"  ; File import path
 S FDA(9999999.39,"1,",2)="/tmp/"  ; File export path
 D FILE^DIE("E",$NA(FDA))
 ;
 I $D(DIERR) ZWRITE ^TMP("DIERR",$J,*)
 ;
 ; 7. Update the exipration date for the verify code of the two demo users
 D MES^XPDUTL("Updating Verify Code expiration dates")
 N I,Z F I=.9:0 S I=$O(^VA(200,I)) Q:'I  S Z=^(I,0) I $P(Z,U,3)]"" S $P(^VA(200,I,.1),U)=$H
 ;
 ; 8. Update Intro Message with Access and Verify codes
 D MES^XPDUTL("Intro Message Update")
 N WP S WP=$$GET1^DIQ(8989.3,1,240,,"WP")
 ;
 N DONE S DONE=0
 N I F I=0:0 S I=$O(WP(I)) Q:'I  I WP(I)["ACCESS CODE" S DONE=1 QUIT
 I DONE QUIT
 ;
 N N S N=$O(WP(" "),-1)+1
 S WP(N)=" ",N=N+1
 S WP(N)=" Login with one of the following users: ",N=N+1
 S WP(N)=" ",N=N+1
 S $E(WP(N),1)="NAME"
 S $E(WP(N),20)="ACCESS CODE"
 S $E(WP(N),35)="VERIFY CODE"
 S N=N+1
 S $E(WP(N),1)="===="
 S $E(WP(N),20)="==========="
 S $E(WP(N),35)="==========="
 S N=N+1
 ;
 N I,Z F I=.9:0 S I=$O(^VA(200,I)) Q:'I  S Z=^(I,0) I $P(Z,U,3)]"" D
 . S $E(WP(N),1)=$P(Z,U)
 . S $E(WP(N),20)=$P(Z,U,3)
 . S $E(WP(N),35)=$P(^VA(200,I,.1),U,2)
 . S N=N+1
 ;
 D WP^DIE(8989.3,"1,",240,"K",$NA(WP))
 QUIT
