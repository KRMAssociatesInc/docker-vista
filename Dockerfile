FROM centos

RUN echo "multilib_policy=best" >> /etc/yum.conf
RUN yum  -y update && \
	yum install -y gcc-c++ git xinetd perl curl python openssh-server openssh-clients expect man python-argparse sshpass wget make cmake dos2unix which unzip lsof net-tools|| true && \
	yum install -y http://libslack.org/daemon/download/daemon-0.6.4-1.i686.rpm > /dev/null && \
	package-cleanup --cleandupes && \
	yum  -y clean all

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa && \
    ssh-keygen -t ecdsa -N "" -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
	echo 'root:docker' | chpasswd

WORKDIR /opt/vista
ADD . /opt/vista/

# OSEHRA VistA (YottaDB, no bootstrap, with QEWD and Panorama)
RUN ./autoInstaller.sh -y -b -e -m && \
	rm -rf /home/osehra/Dashboard
ENTRYPOINT /home/osehra/bin/start.sh

# WorldVistA (GTM, no boostrap, skip testing)
#RUN ./autoInstaller.sh -g -b -s -i worldvista -a https://github.com/glilly/wvehr2-dewdrop/archive/master.zip && \
#	rm -rf /usr/local/src/VistA-Source
#ENTRYPOINT /home/worldvista/bin/start.sh

# vxVistA (YottaDB, no boostrap, skip testing, and do post-install as well)
#RUN ./autoInstaller.sh -y -b -s -i vxvista -a https://github.com/OSEHRA/vxVistA-M/archive/master.zip -p ./Common/vxvistaPostInstall.sh && \
#	rm -rf /usr/local/src/VistA-Source
#ENTRYPOINT /home/vxvista/bin/start.sh

# RPMS (YottaDB, no boostrap, skip testing, and do post-install as well)
#RUN ./autoInstaller.sh -y -b -s -i rpms -a https://github.com/shabiel/FOIA-RPMS/archive/master.zip -p ./Common/rpmsPostInstall.sh && \
#	rm -rf /usr/local/src/VistA-Source
#ENTRYPOINT /home/rpms/bin/start.sh

# Caché Install with local DAT file
#RUN ./autoInstaller.sh -c -b -s -i vehu
#ENTRYPOINT /opt/cachesys/vehu/bin/start.sh
#EXPOSE 22 8001 9430 8080 57772

EXPOSE 22 8001 9430 8080
