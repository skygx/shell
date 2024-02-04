#!/bin/bash
filename="test.txt" # 文件名
line_number=5        # 目标行号
# insert into file content
content=''' \
parseExec session_timeout=50 \
parseExec connection_timeout=50 \
parseExec post_size=50 \
parseExec http_size=50 \
'''                   # 需要追加的多行内容

# 将多行内容转换为单行并进行处理
new_content=$(echo "$content" | tr '\n' ' ')

# 使用sed命令在指定行之前插入新内容
sed -i "${line_number}a ${content}" $filename

# modify file content
sed -i "s/\(parseExec session_timeout=\).*/\1\$SESSION_TIMEOUT/1" $filename
sed -i "s/\(parseExec connection_timeout=\).*/\1\$CONNECTION_TIMEOUT/1" $filename
sed -i "s/\(parseExec post_size=\).*/\1\$POST_SIZE/1" $filename
sed -i "s/\(parseExec http_size=\).*/\1\$HTTP_SIZE/1" $filename
