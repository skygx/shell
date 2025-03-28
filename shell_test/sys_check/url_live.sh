#!/bin/bash
fun_url() {   #定义函数
url_list=(192.168.226.20:81 192.168.226.20:88 192.168.226.20:80 192.168.226.20:85 ) #数组
for i in ${url_list[@]} #循环
do
   os=`curl -I -m 3 -s -o /dev/null -w %{http_code} ${i}`  #curl命令
    #echo "$os"
   if [ $os == 200 ] #判断
   then
      echo "${i} is ok" 
   else
      echo "${i} 这个网址状态码不是200"
fi
done
}

fun_url
