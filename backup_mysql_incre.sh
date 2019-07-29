#!/bin/bash
# 增量备份方式,在从机上执行,适用于中大型mysql数据库

source /etc/profile # 加载系统环境变量
source ~/.bash_profile # 加载用户环境变量

# 定义全局变量
backup_path="/data/backup/mysqlbak"
mysqlbin_path="/var/lib/mysql"
backup_log="/data/backup/mysqlbak/backup.log"
mysqlbinfile="/var/lib/mysql/mysql-bin.index"
date=$(date +%Y%m%d_%H:%M:%S)
day=30

# 刷新新的mysql-bin.0000*文件
mysqladmin -uroot -p123 flush-logs

counter=`cat $mysqlbinfile|wc -l`
nextnum=0
# 判断是否存在目录,不存在则创建目录
if [ ! -e $backup_path ];then
  mkdir -p $backup_path
fi

# 删除30天以前备份
find $backup_path -type f -mtime +$day -exec rm -rf {} \; > /dev/null 2>&1

# for循环对比是否存在或是否为最新的文件
echo "开始备份数据库: ..."
for file in `cat $mysqlbinfile`
do 
	# basename用于截取mysql-bin.0000*文件名,去掉./mysql-bin.0000*前面的./
    backup_name=`basename $file`
    nextnum=`expr $nextnum + 1`
	cd $backup_path
	if [ $nextnum -eq $counter ];then
        echo "$backup_name 备份 $backup_name 失败" >> $backup_log
    else
        dest=$backup_path/$backup_name
		# test -e 检测文件是否存在
        if (test -e $dest);then
            echo "$backup_name 备份 $backup_name 失败" >> $backup_log
        else
            cp $mysqlbin_path/$backup_name $backup_path/
			tar czvf $backup_name_$date.tar.gz $backup_name --force-local
			size=$(du $backup_name.tar.gz -sh | awk '{print $1}')
			rm -rf $backup_name
            echo "$backup_name 备份 $backup_name($size) 成功" >> $backup_log
        fi
    fi
done
 
echo "备份结束,结果查看 $backup_log"
du $backup_path/*$date* -sh | awk '{print "文件:" $2 ",大小:" $1}




