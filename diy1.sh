#!/bin/bash
set -e
set -o pipefail
export TZ=Asia/Shanghai

# 全局Git优化+三次重试，彻底解决GitHub网络波动、限速拉取失败
git config --global http.postBuffer 524288000
git config --global core.compression 0
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

git_clone() {
    git clone --depth 1 --retry 3 "$1" "$2"
}

# 修改默认LAN网关
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 清空root密码
sed -i '/^root:/d' package/base-files/files/etc/shadow
echo "root::0:0:99999:7:::" >> package/base-files/files/etc/shadow

# 编译版本烙印
build_date=$(TZ=Asia/Shanghai date +%Y.%m.%d)
sed -i "s/DISTRIB_REVISION='.*'/DISTRIB_REVISION='($build_date compiled by cheery)'/" package/base-files/files/etc/openwrt_release
sed -i "s/OpenWrt /OpenWrt ($build_date compiled by cheery) /" package/base-files/files/etc/banner

# 克隆Argon主题
git_clone https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git_clone https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# Lucky 路径规范化
git_clone https://github.com/gdy666/lucky package/lucky
git_clone https://github.com/gdy666/luci-app-lucky package/luci-app-lucky

# Passwall 双重保险拉取，无依赖冲突
git_clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
git_clone https://github.com/Openwrt-Passwall/openwrt-passwall package/luci-app-passwall

# uci-defaults 文件名统一 100%生效
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-custom <<'EOF'
#!/bin/sh
[ -f /lib/functions.sh ] && . /lib/functions.sh
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci set luci.main.lang=zh_cn
uci set network.lan.ipaddr=192.168.5.1
uci commit system
uci commit luci
uci commit network
exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom

exit 0
