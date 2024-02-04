#!/bin/bash

# 监控目录和文件名
dir_path="/root/btop"
HOSTNAME=$(hostname)
HOSTIP=$(hostname -I|cut -d\  -f 1)
filelists=`ls -lS $dir_path | head -n 3 | awk '{print $NF}'`

# webhook 地址
#webhook_url="https://oapi.dingtalk.com/robot/send?access_token=MXidsbEyjm6VzuVugweyvxjTyQcMKC0Sid0tkXc_RDDyYsxe-696Dshk7ropRDMH"
webhook_url="https://oapi.dingtalk.com/robot/send?access_token=ff8139e1497d5d97509a3831184384a1683725156d244adaf27e215b6c8a01c7"
set_payload_file(){
cat  > /opt/payload_result.json << \EOF
{       
"msgtype": "actionCard",
"actionCard": {
"title":"binlog日志文件清理通知",
"text":"
##### 服务器<font color=#67C23A>hostname</font>(<font color=#FF0000>hostip</font> )上MySQL binlog日志文件清理通知 \n
>  ##### <font color=#67C23A> 【文件路径】</font> :<font color=#FF0000> template1 </font> \n
>  ##### <font color=#67C23A> 【文件大小】</font> :<font color=#FF0000> template2</font> \n
>  ##### <font color=#67C23A>  此文件已经完成清理，请知悉</font> \n
"
}
}        
EOF
}
delete_file(){  
cd $dir_path
for file in $filelists; do
    if [[ -f "$file" ]]; then
      # 获取文件大小（单位：字节）
      file_size=$(stat -c "%s" "$file")
      file_size_mb=$((file_size/(1024*1024)))
      #rm -f $file
      # 发送告警到 webhook 机器人
        message1="$dir_path/${file}"
        message2="${file_size_mb} MB"
        set_payload_file
        sed -i "s^template1^$message1^g" /opt/payload_result.json
        sed -i "s^template2^$message2^g" /opt/payload_result.json
        sed -i "s^hostname^$HOSTNAME^g" /opt/payload_result.json
        sed -i "s^hostip^$HOSTIP^g" /opt/payload_result.json
        response=$(curl -sS -H "Content-Type: application/json" -X POST -d @/opt/payload_result.json "${webhook_url}")
        if [ $? -eq 0 ]; then
            echo "Alert sent successfully"
        else
            echo "Failed to send alert: ${response}"
        fi
      fi
done
}
delete_file
