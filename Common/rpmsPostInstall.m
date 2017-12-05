rpmsPostInstall ; OSE/SMH - rpmsPostInstall ;2017-12-05  4:31 PM
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
 S $P(^VA(200,1,.1),U)=$H
 S $P(^VA(200,4,.1),U)=$H
 QUIT
