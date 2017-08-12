FROM centos

RUN echo "multilib_policy=best" >> /etc/yum.conf
RUN yum  -y update && \
	yum install -y git xinetd perl curl python openssh-server openssh-clients expect man python-argparse sshpass wget make cmake dos2unix which unzip || true && \
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

# OSEHRA VistA
#RUN ./autoInstaller.sh -g -b && \
#	rm -rf /home/osehra/Dashboard

# WorldVistA
#RUN ./autoInstaller.sh -g -b -s -i worldvista -a https://github.com/glilly/wvehr2-dewdrop/archive/master.zip && \
#	rm -rf /usr/local/src/VistA-Source

# vxVistA
#RUN ./autoInstaller.sh -g -b -s -i vxvista -a https://github.com/OSEHRA/vxVistA-M/archive/master.zip && \
#	rm -rf /usr/local/src/VistA-Source

# RPMS
RUN ./autoInstaller.sh -g -b -s -i rpms -a https://github.com/ChristopherEdwards/FOIA-RPMS/archive/foia-2017-02-22-gtm.zip && \
	rm -rf /usr/local/src/VistA-Source
EXPOSE 22 8001 9430 9101 9100

ENTRYPOINT /home/rpms/bin/start.sh
#ENTRYPOINT /home/osehra/bin/start.sh
#ENTRYPOINT /home/worldvista/bin/start.sh
#ENTRYPOINT /home/vxvista/bin/start.sh
