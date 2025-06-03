#!/bin/bash
set -eo pipefail  # 增强错误检查

# 参数校验
if [ $# -ne 3 ]; then
    echo "Args invalid"
    echo "Usage: $0 <frequency> <input_tcl> <output_tcl>"
    exit 1
fi

freq=$1
template=$2
out=$3

# 检查输入文件是否存在
if [ ! -f "$template" ]; then
    echo "Error: Template file $template not found!"
    exit 1
fi

# 计算时钟周期（处理bc换行符）
period=$(echo "scale=2; 1000/$freq" | bc | tr -d '\n')

# 创建输出目录
mkdir -p "$(dirname "$out")"

# 路径替换（保持syn目录内的相对路径）
sed \
    -e "s/create_clock -period [0-9.]*/create_clock -period $period/" \
    -e "s|default|${freq}|g" \
    -e "s|\./rpt|./rpt|g" \
    -e "s|\./mapped|./mapped|g" \
    -e "s|\./unmapped|./unmapped|g" \
    -e "s/slib_name/typical_1v2c25/g" \
    "$template" > "$out"

echo "[INFO] Generated $out"