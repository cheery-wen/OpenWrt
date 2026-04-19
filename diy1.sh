#!/bin/bash
# ============================================
# DIY 脚本 1 - 在更新 feeds 前执行
# 功能：修改源码配置、添加第三方插件、创建 UCI 默认设置
# ============================================

# ---------- 1. 修改默认 IP 地址为 192.168.5.1 ----------
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# ---------- 2. 清除登录密码（设置为空）----------
if [ -f "package/base-files/files/etc/shadow" ]; then
    sed -i 's/^root:[^:]*:/root::/' package/base-files/files/etc/shadow
fi

# ---------- 3. 自定义固件版本显示 ----------
sed -i "s/DISTRIB_REVISION='.*'/DISTRIB_REVISION='$(TZ=UTC-8 date "+%Y.%m.%d") compiled by cheery'/g" package/base-files/files/etc/openwrt_release

# ---------- 4. 删除有依赖问题的软件包（消除警告）----------
rm -rf feeds/packages/net/onionshare-cli 2>/dev/null || true

# ---------- 5. 添加第三方插件 ----------
# Argon 主题与配置（仅安装，不设为默认）
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# Lienol 仓库中的特定插件 (control-webrestriction 和 ramfree)
git clone --depth 1 --filter=blob:none --sparse https://github.com/Lienol/openwrt-package.git package/lienol-packages
cd package/lienol-packages
git sparse-checkout set luci-app-control-webrestriction luci-app-ramfree
cd ../..

# 关机按钮
git clone --depth 1 https://github.com/esirplayground/luci-app-poweroff.git package/luci-app-poweroff

# Lucky 大吉
git clone --depth 1 https://github.com/gdy666/luci-app-lucky.git package/luci-app-lucky

# PassWall 依赖包及主程序
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/openwrt-passwall-packages
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall.git package/luci-app-passwall

# ---------- 6. 创建首次启动 UCI 默认设置脚本（仅设置语言和 IP 二次保障，不设置主题）----------
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-custom-settings << 'EOF'
#!/bin/sh
# 设置默认语言为简体中文
uci set luci.main.lang='zh_cn'
# 二次保障默认 IP 地址
uci set network.lan.ipaddr='192.168.5.1'
uci commit luci
uci commit network
exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom-settings

echo "✅ diy1.sh 执行完成（主题保持官方默认 Bootstrap）"
