#!/bin/bash
echo "========================================="
echo "DIY2 编译收尾清理"
echo "========================================="
rm -rf openwrt/tmp openwrt/build_dir/tmp* 2>/dev/null || true
echo "✅ DIY2 执行完毕"
