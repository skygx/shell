#!/bin/bash
# 设置收件人、主题和正文内容
from="sweet_love2000@126.com"
to="sweet_love2000@126.com"
subject="这是一封测试邮件"
body="这是邮件的正文部分。"
attachment="/root/shell_test/sys_check/check.txt" # 要添加为附件的文件路径
# 构建邮件消息体
message=$(cat <<EOF
From: $from
To: $to
Subject: $subject
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=boundary_string
 
--boundary_string
Content-Disposition: inline
Content-Transfer-Encoding: quoted-printable
$body
 
--boundary_string
Content-Disposition: attachment; filename="$attachment"
Content-Transfer-Encoding: base64
$(base64 -w 78 < "$attachment")
 
--boundary_string--
EOF
)
 
echo "$message" | mail sweet_love2000@126.com
#echo "$message" | /usr/sbin/sendmail -t
