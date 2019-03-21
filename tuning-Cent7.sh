#!/bin/bash
# 配置服务器网卡
cat /etc/sysconfig/network-scripts/ifcfg-ens192 
	TYPE=Ethernet
	PROXY_METHOD=none
	BROWSER_ONLY=no
	BOOTPROTO=static
	IPADDR=192.168.10.170
	NETMASK=255.255.255.0
	GATEWAY=192.168.10.1
	DNS1=8.8.8.8
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=yes
	IPV6_AUTOCONF=yes
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	IPV6_ADDR_GEN_MODE=stable-privacy
	NAME=ens192
	DEVICE=ens192
	ONBOOT=yes
	IPV6INIT=no
# 系统升级基础
mv /etc/yum.d/CentOS-Base.repo /etc/yum.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
yum clean all > /dev/null 2>&1 # 清楚缓存
yum makecache > /dev/null 2>&1 # 建立缓存
yum update > /dev/null 2>&1 #升级系统
# 添加epel外部yum源
yum -y install epel-release > /dev/null 2>&1
# 安装gcc基础库文件及sysstat，bind-utils
yum -y install gcc gcc-c++ vim-enhanced unzip unrar sysstat bind-utils > /dev/null 2>&1
# 配置ntpdate自动对时
yum -y install ntp > /dev/null 2>&1
echo "01 01 * * * /usr/sbin/ntpdate ntp.api.bz	>> /dev/null 2>&1" >> /etc/crontab
ntpdate ntp.api.bz
systemctl restart crond
# 配置文件的ulimit值
ulimit -SHn 65535
cat >> /etc/security/limits.conf << EOF
*		 soft	 nofile		65535
*		 hard	 nofile		65535
EOF

# 基础内核优化
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv6.conf.all.disable_ipv6 =1
net.ipv6.conf.default.disable_ipv6 =1
EOF
sysctl -p
# 关闭seLinux、防火墙及优化ssh登录
systemctl stop firewalld
systemctl disable firewalld
sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/sysconfig/selinux
sed -i 's@#UseDNS no@UseDNS yes no' /etc/ssh/sshd_config
systemctl restart sshd
# 优化历史命令查看
echo "# history" >> /etc/profile
echo "export HISTSIZE=100000" >> /etc/profile
echo "export HISTTIMEFORMAT='[%Y-%m-%d %H:%M:%S]'" >> /etc/profile
source /etc/profile
reboot
