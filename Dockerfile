# Base Vagrant box

FROM centos:7

RUN yum -y install deltarpm
RUN yum -y install systemd systemd-libs initscripts sudo wget curl openssh-server openssh-clients

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Create and configure vagrant user
RUN useradd --create-home -s /bin/bash vagrant
WORKDIR /home/vagrant

# Configure SSH access
RUN mkdir -p /home/vagrant/.ssh && \
    wget https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys && \
    chmod 0700 /home/vagrant/.ssh && \
    chmod 0600 /home/vagrant/.ssh/authorized_keys && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \

    mkdir -p /etc/sudoers.d && \
    install -b -m 0440 /dev/null /etc/sudoers.d/vagrant && \
    echo 'vagrant ALL=NOPASSWD: ALL' >> /etc/sudoers.d/vagrant && \
    sed -i 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers && \
    sed -i -e 's/\(UsePAM \)yes/\1 no/' /etc/ssh/sshd_config && \
    systemctl enable sshd.service && \

    gpasswd -a vagrant wheel && \
    echo -n 'vagrant:vagrant' | chpasswd

# Install Puppet
RUN wget http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm -O /tmp/puppetlabs-release-pc1.rpm && \
    rpm -i /tmp/puppetlabs-release-pc1.rpm && \
    rm -f /tmp/*.rpm && \
    yum clean all && \
    yum -y install puppet-agent

VOLUME [ "/sys/fs/cgroup" ]

# Expose port 22 for ssh
EXPOSE 22
EXPOSE 80

#leave the ssh daemon (and container) running
CMD ["/usr/sbin/init"]
