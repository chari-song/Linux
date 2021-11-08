#!/bin/bash
#--------------------------------------
# 功能：                               
# 1、初始化网卡，自动获取手动获取                          
# 2、本地yum源及epel源            
# 3、时钟同步                 
# 4、安装基础工具    
# 5、优化内核                      
# 6、修改文件句柄及远程连接dns设置            
# 7、设置历史记录命令行
# 8、取消终端声音及邮件提示
# 9、时间：2019/11/29                  
#--------------------------------------
function network_config(){
    # 配置服务器网卡等信息
    read -p "请输入网卡配置是否为自动获取IP地址[y/n]: " auto_ip
    if [ $auto_ip == 'y' ];then
        network_name=`ip a|grep ^2|awk -F ":" '{print $2}'|awk '{print $1}'`
        cd /etc/sysconfig/network-scripts/
        echo "DNS1=114.114.114.114" ifcfg-$network_name
        sed -i 's@ONBOOT=no@ONBOOT=yes@g' ifcfg-$network_name
        systemctl restart network
        cd
    else
        network_name=`ip a|grep ^2|awk -F ":" '{print $2}'|awk '{print $1}'`
        read -p "请输入配置得IP地址: " ip_addr
        read -p "请输入配置IP地址掩码: " ip_mask
        read -p "请输入配置IP地址得网关: " ip_gateway
        cd /etc/sysconfig/network-scripts/
        sed -i 's@ONBOOT=no@ONBOOT=yes@g' ifcfg-$network_name
        sed -i 's@BOOTPROTO=dhcp@BOOTPROTO=static@g' ifcfg-$network_name
        echo "IPADDR=$ip_addr" ifcfg-$network_name
        echo "NETMASK=$ip_mask" ifcfg-$network_name
        echo "GATEWAY=$ip_gateway" ifcfg-$network_name
        echo "DNS1=114.114.114.114" ifcfg-$network_name
        systemctl restart network
        cd
    fi
}

function system_yumrepo(){
    # 优化本地yum源
    # 安装外部yum源
    # 安装服务器基础工具
    # 设置时钟同步
    sys_time=`date +%Y%m%d`
    cd /etc/yum.repos.d/
    mv CentOS-Base.repo CentOS-Base.repo."$sys_timebak"
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
    yum clean all > /dev/null 2>&1
    yum makecache > /dev/null 2>&1
    yum update > /dev/null 2>&1
    yum -y install epel-release > /dev/null 2>&1
    yum -y install gcc gcc-c++ vim-enhanced unzip unrar sysstat bind-utils > /dev/null 2>&1
    yum -y install ntpdate > /dev/null 2>&1
    echo "01 01 * * * /usr/sbin/ntpdate ntp.api.bz	>> /dev/null 2>&1" >> /etc/crontab
    ntpdate ntp.api.bz
    systemctl restart crond
    cd
}

function system_kennel(){
    # 设置内核参数
    # 优化文件句柄数
    # 关闭防火墙及开机自启
    # 设置远程登录连接DNS反向查询取消
    ulimit -SHn 65535
    echo "*		 soft	 nofile		65535" >> /etc/security/limits.conf
    echo "*		 hard	 nofile		65535" >> /etc/security/limits.conf
    echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_syn_retries = 1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_fin_timeout = 1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_keepalive_time = 1200" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_max_syn_backlog = 16384" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_max_tw_buckets = 36000" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.disable_ipv6 =1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 =1" >> /etc/sysctl.conf
    systemctl stop firewalld
    systemctl disable firewalld
    sysctl -p
    sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/sysconfig/selinux
    sed -i 's@#UseDNS yes@UseDNS no@g' /etc/ssh/sshd_config
    systemctl restart sshd
}

function system_sys(){
    # 设置终端声音
    # 取消邮件提示
    # 历史命令设置日期时间及保存行数
    echo "unset MAILCHECK">> /etc/profile;
    source /etc/profile
    echo "# history" >> /etc/profile
    echo "export HISTSIZE=100000" >> /etc/profile
    echo "export HISTTIMEFORMAT='[%Y-%m-%d %H:%M:%S]'" >> /etc/profile
    sed -i 's/#set bell-style none/set bell-style none/' /etc/inputrc
    echo "set vb" /etc/inputrc
    source /etc/profile
}

function main(){
    # 主函数，系统初始化的函数
    read -p "请输入优化的模块[network|yum|kennel|sys|all|自定义模块]: " -a Sysctl
    for ((i=0;i<${#Sysctl[@]};i++));do
        sysctl=${Sysctl[i]}
        if [ $sysctl == 'network' ];then
            network_config
        elif [ $sysctl == 'yum' ];then
            system_yumrepo
        elif [ $sysctl == 'kennel' ];then
            system_kennel
        elif [ $sysctl == 'sys' ];then
            system_sys
        elif [ $sysctl == 'all' ];then
            network_config
            system_yumrepo
            system_kennel
            system_sys
        fi
    done
    reboot
}
main
