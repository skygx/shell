#!/bin/bash

read -p "请输入头的数量: " HEAD
read -p "请输入脚的数量: " FOOT
RABBIT=$[FOOT/2-HEAD]
CHOOK=$[HEAD-RABBIT]
echo "兔子: " $RABBIT
echo "鸡: " $CHOOK
