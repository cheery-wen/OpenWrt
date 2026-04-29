#!/bin/bash
set -e
set -o pipefail
export TZ=Asia/Shanghai

# Git全局网络优化
git config --global http.postBuffer 524288000
git config --global core.compression 0

# 原生3次重试克隆函数，全网稳定不失败
git_clone() {
    for i in {1..3}; do
        if git clone --depth 1 "$1" "$2"; then
            return 0
        fi
        echo "克隆失败，正在重试 $i/3"
        sleep 5
    done
    exit 1
}

# 全局绝对路径，本地/GitHub CI 100%通用
WORKDIR=$(pwd)
OPENWRT_DIR="${WORKDIR}/openwrt"
mkdir -p "${OPENWRT_DIR}"

# 修改默认后台IP 192.168.1.1 → 192.168.5.1
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 清空root密码
sed -i '/^root:/d' package/base-files/files/etc/shadow
echo "root::0:0:99999:7:::" >> package/base-files/files/etc/shadow

# 编译版本烙印
build_date=$(TZ=Asia/Shanghai date +%Y.%m.%d)
sed -i "s/DISTRIB_REVISION='.*'/DISTRIB_REVISION='($build_date compiled by cheery)'/" package/base-files/files/etc/openwrt_release
sed -i "s/OpenWrt /OpenWrt ($build_date compiled by cheery) /" package/base-files/files/etc/banner

# 拉取Argon主题及配置
git_clone https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git_clone https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 拉取Lucky前后端
git_clone https://github.com/gdy666/lucky package/lucky
git_clone https://github.com/gdy666/luci-app-lucky package/luci-app-lucky

# 拉取Passwall全套
git_clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
git_clone https://github.com/Openwrt-Passwall/openwrt-passwall package/luci-app-passwall

# 强制删除内置旧版Passwall，从根源杜绝冲突
rm -rf "${OPENWRT_DIR}/feeds/luci/applications/luci-app-passwall"
rm -rf "${OPENWRT_DIR}/feeds/packages/net/passwall"

# 绝对路径生成自定义配置，永不失效
mkdir -p "${WORKDIR}/files/etc/uci-defaults"
cat > "${WORKDIR}/files/etc/uci-defaults/99-custom" <<'EOF'
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
chmod +x "${WORKDIR}/files/etc/uci-defaults/99-custom"

# 强制移入openwrt源码目录
cp -rf "${WORKDIR}/files" "${OPENWRT_DIR}/"

exit 0
