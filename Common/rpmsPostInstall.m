rpmsPostInstall ; OSE/SMH - rpmsPostInstall ;2017-12-20  4:41 PM
 ;
 D DT^DICRW
 ;
 ; 1. Fix %RCR in RPMS which is coded with MSM or Cache in mind
 D MES^XPDUTL("Fix %RCR in RPMS which is coded with MSM or Cache in mind")
 K ^TMP($J)
 S DIF="^TMP($J,",XCNP=0,X="DIRCR" X ^%ZOSF("LOAD")
 N ENL S ENL=0
 N I F I=1:1 I $E(^TMP($J,I,0),1,8)="STORLIST" S ENL=I QUIT
 I 'ENL W "CONFIG FAILED",! QUIT
 S ^TMP($J,ENL,0)="STORLIST G IHS  ; Changed by OSEHRA RPMS Installer"
 S DIE=DIF,XCN=0,X="DIRCR" X ^%ZOSF("SAVE")
 ; 
 ; 2. Stop Taskman
 D MES^XPDUTL("Stopping Taskman")
 D GROUP^ZTMKU("SSUB(NODE)")
 D GROUP^ZTMKU("SMAN(NODE)")
 D MES^XPDUTL("Waiting around until Taskman reports it's stopped")              
 F  W "." Q:($$TM^%ZTLOAD=0)  H 1                                               
 ;
 ; 3. Stop all other tasks
 D MES^XPDUTL("Stopping all other tasks")
 D HALTALL^ZSY
 ;
 ; 4. run KBANTCLN with specific parameters
 D MES^XPDUTL("Running KBANTCLN")
 D START^KBANTCLN("ROU","RPMS",9999,"FOIA RPMS","FOIA.RPMS.IHS.GOV")
 ;
 ; 5. start Taskman
 D MES^XPDUTL("Starting Taskman")
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
 ;
 I 'DONE DO
 . N N S N=$O(WP(" "),-1)+1
 . S WP(N)=" ",N=N+1
 . S WP(N)=" Login with one of the following users: ",N=N+1
 . S WP(N)=" ",N=N+1
 . S $E(WP(N),1)="NAME"
 . S $E(WP(N),20)="ACCESS CODE"
 . S $E(WP(N),35)="VERIFY CODE"
 . S N=N+1
 . S $E(WP(N),1)="===="
 . S $E(WP(N),20)="==========="
 . S $E(WP(N),35)="==========="
 . S N=N+1
 . ;
 . N I,Z F I=.9:0 S I=$O(^VA(200,I)) Q:'I  S Z=^(I,0) I $P(Z,U,3)]"" D
 . . S $E(WP(N),1)=$P(Z,U)
 . . S $E(WP(N),20)=$P(Z,U,3)
 . . S $E(WP(N),35)=$P(^VA(200,I,.1),U,2)
 . . S N=N+1
 . ;
 . D WP^DIE(8989.3,"1,",240,"K",$NA(WP))
 ;
 ; 9. Install VueCentric Template
 D MES^XPDUTL("Install VueCentric Template")
 K ^TMP($J)
 D FTG^%ZISH("$HOME/tmp/vuecentric_files","OSEHRA_P23_2017.vtr",$NA(^TMP($J,1)),2)
 N MYDATA M MYDATA=^TMP($J)
 K ^TMP($J)
 N RETURN
 D SETTEMPL^CIAVMCFG(.RETURN,"%OSEHRA_DEFAULT",$O(MYDATA(" "),-1),.MYDATA)
 D CHG^XPAR("SYS","CIAVM DEFAULT TEMPLATE",1,"%OSEHRA_DEFAULT",.ERR)
 I ERR D EN^DDIOL("BOO... CIAVM DEFAULT TEMPLATE") K ERR
 ;
 ; 10. Set default source to be the lib folder a level down from the bin folder.
 ; MUST run VueCentric from the bin folder
 D MES^XPDUTL("Set CIAVM DEFAULT SOURCE")
 D PUT^XPAR("SYS","CIAVM DEFAULT SOURCE",1,"../lib/",.ERR)
 I ERR D EN^DDIOL("BOO... CIAVM DEFAULT SOURCE") K ERR
 ;
 ; 11. Fix the CIANB Broker Config to allow log-in
 D MES^XPDUTL("Set CIANB AUTHENTICATION")
 D NDEL^XPAR("PKG.CIA NETWORK COMPONENTS","CIANB AUTHENTICATION")
 D NDEL^XPAR("SYS","CIANB AUTHENTICATION")
 N Y D GETENV^%ZOSV ; Get UCI and put it in (1st piece of Y)
 D PUT^XPAR("SYS","CIANB AUTHENTICATION",$P(Y,U),0,.ERR)
 I ERR D EN^DDIOL("BOO... CIANB AUTHENTICATION") K ERR
 ; ; 12. Allow creation of visits for all users D MES^XPDUTL("Allowing creation of visits by all users")
 D CHG^XPAR("SYS","BEHOENCX CREATE VISIT",1,"YES",.ERR)
 I ERR D EN^DDIOL("BOO... BEHOENCX CREATE VISIT") K ERR
 ;
 ; 13. Deallocate ORELSE, OREMAS, BGOZ VIEW ONLY from default users
 D MES^XPDUTL("Deleting View Only keys")
 N C S C=","
 N FDA
 N I F I=.9:0 S I=$O(^VA(200,I)) Q:'I  D
 . n find1iens s find1iens=C_I_C
 . n key f key="ORELSE","OREMAS","BGOZ VIEW ONLY" d
 .. n keyallien s keyallien=$$FIND1^DIC(200.051,find1iens,"X",key)
 .. i keyallien S FDA(200.051,keyallien_find1iens,.01)="@"
 N DIERR D:$D(FDA) FILE^DIE("","FDA")
 I $G(DIERR) D EN^DDIOL("BOO... FDA1") ZWRITE ^TMP("DIERR",$J,*)
 ;
 ; 14. Add provider users to Provider USR Class
 D MES^XPDUTL("Add Providers to PROVIDER USR Class")
 N FDA,DIERR
 N I F I=.9:0 S I=$O(^VA(200,I)) Q:'I  D
 . Q:'$D(^XUSEC("PROVIDER",I))
 . S FDA(8930.3,"?+"_I_",",.01)=I
 . S FDA(8930.3,"?+"_I_",",.02)=$$FIND1^DIC(8930,,"QX","PROVIDER","B")
 . S FDA(8930.3,"?+"_I_",",.03)=$$FMADD^XLFDT(DT,-1)
 D UPDATE^DIE(,"FDA")
 I $G(DIERR) D EN^DDIOL("BOO... FDA2") ZWRITE ^TMP("DIERR",$J,*)
 ;
 ; 15. Change Suicide Form version to zero (no clue why... it just is!)
 D MES^XPDUTL("Change Suicide Form version to zero")
 N FDA,DIERR
 S FDA(19930.2,"?+1,",.01)="INDIANHEALTHSERVICE.BEH.IBH.SUICIDE.CONTROLS.CTLSUICIDE_FORM"
 S FDA(19930.2,"?+1,",2)=0
 D UPDATE^DIE(,"FDA")
 I $G(DIERR) D EN^DDIOL("BOO... FDA3") ZWRITE ^TMP("DIERR",$J,*)
 ;
 ; 16. Allow multiple instances for the Reproductive History form we are using
 D MES^XPDUTL("Allow multiple instances for the Reproductive History")
 N FDA,DIERR
 S FDA(19930.2,"?+1,",.01)="IHSBGOREPFACTORS.IHSBGOREPFACT"
 S FDA(19930.2,"?+1,",12)=1
 D UPDATE^DIE(,"FDA")
 I $G(DIERR) D EN^DDIOL("BOO... FDA4") ZWRITE ^TMP("DIERR",$J,*)
 ;
 ; 17. Import the two VOR files for RCIS GUI Components and change version to zero (again?!)
 D MES^XPDUTL("Import the two VOR files for RCIS GUI Components")
 D IMPORTVOR("$HOME/tmp/vuecentric_files","IHSReferredCare.Referral.vor")
 D IMPORTVOR("$HOME/tmp/vuecentric_files","IHSReferredCare.PatientReferral.vor")
 ;
 ; 18. Fix routine CIAUOS to get the correct default directory
 ; NB: THIS IS A TOTAL TOTAL TOTAL HACK!!!! We need to create a new routine and till CIAINIT to use it.
 D MES^XPDUTL("Fix Directory delimiter for CIAUOS")
 K ^TMP($J)
 S DIF="^TMP($J,",XCNP=0,X="CIAUOS" X ^%ZOSF("LOAD")
 N ENL S ENL=0
 N I F I=1:1 I $E(^TMP($J,I,0),1,6)="DIRDLM" S ENL=I QUIT
 I 'ENL W "CONFIG FAILED",! QUIT
 S ^TMP($J,ENL+1,0)=" Q ""/"" ; Changed by OSEHRA RPMS Installer"
 S DIE=DIF,XCN=0,X="CIAUOS" X ^%ZOSF("SAVE")
 ;
 ; 19. Change CIAU HFS DEVICE to point to /dev/null rather than NUL
 D MES^XPDUTL("Set CIAU HFS DEVICE $I to /dev/null")
 N IEN S IEN=$$FIND1^DIC(3.5,,"XQ","CIAU HFS DEVICE","B")
 I 'IEN QUIT
 S FDA(3.5,IEN_",",1)="/dev/null"
 D FILE^DIE(,"FDA")
 I $G(DIERR) D EN^DDIOL("BOO... FDA5") ZWRITE ^TMP("DIERR",$J,*)
 QUIT
 ;
IMPORTVOR(PATH,NAME) ; [Private] - VOR files
 ; This is an ini file.
 ;[VUECENTRIC OBJECT REGISTRATION]
 ;PROGID=IHSREFERREDCARE.PATIENTREFERRAL.PATIENTREFERRALVIEW
 ;CLSID={686D0599-841E-43EB-9BF8-52B51D842244}
 K ^TMP($J)
 N POP
 D OPEN^%ZISH("FILE1",PATH,NAME,"R")
 I $G(POP) W "FAIL..." QUIT
 D USE^%ZISUTL("FILE1")
 N CLASS,DATA
 N X F  R X:0 Q:$$STATUS^%ZISH  D
 . I $E(X)="[" S CLASS=$P($P(X,"[",2),"]") QUIT
 . N ID,VALUE
 . S ID=$P(X,"=",1)
 . S VALUE=$P(X,"=",2)
 . S DATA(CLASS,ID)=VALUE
 D CLOSE^%ZISUTL("FILE1")
 N DATUM S DATUM=""
 F  S DATUM=$O(DATA("VUECENTRIC OBJECT REGISTRATION",DATUM)) Q:DATUM=""  D
 . N FIELD S FIELD=$$FLDNUM^DILFD(19930.2,DATUM)
 . I DATUM="MD5" S FIELD=$$FLDNUM^DILFD(19930.2,"MD5 CHECKSUM")
 . S FDA(19930.2,"?+1,",FIELD)=DATA("VUECENTRIC OBJECT REGISTRATION",DATUM)
 . I DATUM="VERSION" S FDA(19930.2,"?+1,",FIELD)=0 ; Like suicide form. No clue why.
 D UPDATE^DIE(,"FDA")
 I $G(DIERR) D EN^DDIOL("BOO... FDA6")
 QUIT
