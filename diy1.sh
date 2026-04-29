#!/bin/bash
set -e
export TZ=Asia/Shanghai

echo "========================================="
echo "DIY1 前置配置 + 拉取指定插件"
echo "========================================="

# 修改默认LAN地址
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 清空root密码
sed -i 's/root:[^:]*:/root::/g' package/base-files/files/etc/shadow

# 编译日期
BUILD_DATE=$(date "+%Y.%m.%d")
sed -i "s/DISTRIB_REVISION='.*'/DISTRIB_REVISION='(${BUILD_DATE} compiled by cheery)'/" package/base-files/files/etc/openwrt_release
sed -i "s/OpenWrt /OpenWrt (${BUILD_DATE} compiled by cheery) /" package/base-files/files/etc/banner

# 拉取指定插件
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
git clone --depth 1 https://github.com/gdy666/luci-app-lucky.git package/luci-app-lucky
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/openwrt-passwall-packages
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall.git package/luci-app-passwall

# 全局兼容自定义配置
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/999-final-custom <<'EOF'
#!/bin/sh
sleep 1
uci set luci.main.lang="zh_cn"
uci set network.lan.ipaddr="192.168.5.1"
uci commit luci
uci commit network
exit 0
EOF
chmod +x files/etc/uci-defaults/999-final-custom

echo "✅ DIY1 执行完毕"
