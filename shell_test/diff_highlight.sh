#!/bin/bash

file1="$1"
file2="$2"

# 使用diff命令比较两个文件，并将结果保存到临时文件
diff_output=$(diff -u "$file1" "$file2")
temp_file="/tmp/diff_output.txt"
echo "$diff_output" > "$temp_file"

# 使用grep命令找到不同的行，并添加颜色高亮显示
highlighted_output=$(grep -E '^(\+|\-)' "$temp_file" | sed -e 's/^+/\o033[32m+/;s/^-/\o033[31m-/' -e 's/$/\o033[0m/')
echo "$highlighted_output"

# 删除临时文件
rm "$temp_file"
