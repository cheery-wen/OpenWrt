#!/bin/bash
# ============================================
# DIY 脚本 2 - 在更新 feeds 后、make defconfig 前执行
# 功能：设置默认语言、设置默认主题
# ============================================

# ---------- 1. 设置 LuCI 默认语言为简体中文 ----------
LUCI_CONFIG="feeds/luci/modules/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CONFIG" ]; then
    # 兼容带引号和不带引号的写法
    sed -i "s/option lang 'auto'/option lang 'zh_cn'/g" "$LUCI_CONFIG"
    sed -i 's/option lang auto/option lang zh_cn/g' "$LUCI_CONFIG"
    echo "✅ 默认语言已设置为简体中文"
else
    echo "⚠️ 未找到 $LUCI_CONFIG，跳过语言设置"
fi

# ---------- 2. 禁用 geoview（避免 Go 版本兼容编译错误）----------
if [ -f ".config" ]; then
    sed -i 's/^CONFIG_PACKAGE_geoview=y$/# CONFIG_PACKAGE_geoview is not set/' .config
    echo "✅ 已禁用 geoview"
fi

echo "✅ diy2.sh 执行完成"
