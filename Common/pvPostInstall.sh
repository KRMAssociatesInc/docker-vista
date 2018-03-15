csession CACHE -U $instance <<END
 ZR  ZS pvPostInstall
 d \$SYSTEM.Process.SetZEOF(1)
 S F="/opt/vista/Common/pvPostInstall.m" O F U F ZL  ZS pvPostInstall C F
 D ^pvPostInstall
 HALT
END
