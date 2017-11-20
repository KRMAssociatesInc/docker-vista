vxvistaPostInstall ; OSE/SMH - vxVistAPostInstall ;2017-11-16  3:27 PM
 ;
 D DT^DICRW
 ;
 ; 1. Set vxVistA Indicator on ^%ZOSF
 S ^%ZOSF("ZVX")="VX"
 ;
 ; 2. Set one way hash in the VFD 
 N FDA,ERR
 S FDA(21614,"?+1,",.01)="ONE-WAY HASH"
 S FDA(21614,"?+1,",1)="S X=$$UP^XLFSTR($$RETURN^%ZOSV(""printf ""_X_"" | md5sum| cut -c1-32""))"
 D UPDATE^DIE("E",$NA(FDA),,$NA(ERR))
 I $D(ERR) W "CONFIG FAILED",! QUIT
 ;
 ; 3. Edit XUSHSH to do the one way hash for vxVistA.
 K ^TMP($J)
 S DIF="^TMP($J,",XCNP=0,X="XUSHSH" X ^%ZOSF("LOAD")
 N ENL S ENL=0
 N I F I=1:1 I $E(^TMP($J,I,0),1,2)="EN" S ENL=I QUIT
 I 'ENL W "CONFIG FAILED",! QUIT
 S ^TMP($J,ENL+1,0)=" D X^VFDXTX(""ONE-WAY HASH"") Q X"
 S DIE=DIF,XCN=0,X="XUSHSH" X ^%ZOSF("SAVE")
 QUIT
