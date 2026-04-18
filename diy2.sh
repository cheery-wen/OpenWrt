#!/bin/bash
# ============================================
# DIY 脚本 2 - 在更新 feeds 后、make defconfig 前执行
# 功能：设置默认语言、设置默认主题
# ============================================

# ---------- 1. 设置 LuCI 默认语言为简体中文 ----------
if [ -f "feeds/luci/modules/luci-base/root/etc/config/luci" ]; then
    sed -i "s/option lang auto/option lang zh_cn/g" feeds/luci/modules/luci-base/root/etc/config/luci
fi

# ---------- 2. 设置 Argon 为默认主题 ----------
if [ -f "feeds/luci/collections/luci/Makefile" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
fi

echo "✅ diy2.sh 执行完成"
