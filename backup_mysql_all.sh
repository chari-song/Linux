#!/bin/bash
# 全备方式，一般在从机上执行，适用于小中型mysql数据库

source /etc/profile # 加载系统环境变量
source ~/.bash_profile # 加载用户环境变量

# 定义全局变量
user="root"
password="123"
host="localhost"
port="3306"
db=("zabbix")
local="--single-transaction"
mysql_path="/usr/share/mysql"
backup_path="/data/backup/mysqlbak"
date=$(date +%Y%m%d_%H:%M:%S)
day=30
backup_log="/data/backup/mysqlbak/backup.log"

# 判断是否存在目录,不存在则创建目录
if [ ! -e $backup_path ];then
  mkdir -p $backup_path
fi

# 删除30天以前备份
find $backup_path -type f -mtime +$day -exec rm -rf {} \; > /dev/null 2>&1

echo "开始备份数据库: ${db[*]}"

# 备份数据库后压缩
backup_sql(){
  dbname=$1
  backup_name="${dbname}_${date}.sql"
  mysqldump -h $host -P $port -u $user -p$password $lock --default-character-set=utf8 --flush-logs -R $dbname > $backup_path/$backup_name
  if [[ $? == 0 ]];then
    cd $backup_path
	# tar --force-local参数,压缩带有冒号的压缩包
    tar czvf $backup_name.tar.gz $backup_name --force-local
    size=$(du $backup_name.tar.gz -sh | awk '{print $1}')
    rm -rf $backup_name
    echo "$date 备份 $dbname($size) 成功"
  else
    cd $backup_path
    rm -rf $backup_name
    echo "$date 备份 $dbname 失败"
  fi
}

# 多个库循环备份
length=${#db[@]}
for ((i=0;i<$length;i++));do
  backup_sql ${db[i]} >> $backup_log 2>&1
done

echo "备份结束,结果查看 $backup_log"
du $backup_path/*$date* -sh | awk '{print "文件:" $2 ",大小:" $1}
