#!/bin/bash
# ============================================
# DIY 脚本 2 - 在更新 feeds 后、make defconfig 前执行
# 功能：（语言和 IP 已在 diy1.sh 中通过 UCI defaults 设置）
# ============================================

# 替换官方 Golang 为 26.x 版本
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

echo "✅ diy2.sh 执行完成（无额外操作）"
