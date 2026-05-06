#!/bin/sh
set -e

# ======================
# 基础变量
# ======================
WORKDIR=$(pwd)
OPENWRT_DIR="${WORKDIR}/openwrt"

LAN_IP="192.168.1.1"
LAN_NETMASK="255.255.255.0"

# ======================
# 版本信息
# ======================
build_date=$(TZ=Asia/Shanghai date +%Y.%m.%d)

# 注意：这里必须在OpenWrt源码目录执行才有效
if [ -f package/base-files/files/etc/openwrt_release ]; then
    sed -i "s/DISTRIB_REVISION='.*'/DISTRIB_REVISION='(${build_date} compiled by cheery)'/" package/base-files/files/etc/openwrt_release
fi

if [ -f package/base-files/files/etc/banner ]; then
    sed -i "s/OpenWrt /OpenWrt (${build_date} compiled by cheery) /" package/base-files/files/etc/banner
fi

# ======================
# 网络修复（关键：防止进不去后台）
# ======================
mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-network-fix <<EOF
#!/bin/sh

LAN_IP="${LAN_IP}"
LAN_NETMASK="${LAN_NETMASK}"

# LAN 基础配置
uci set network.lan=interface
uci set network.lan.proto='static'
uci set network.lan.ipaddr="\$LAN_IP"
uci set network.lan.netmask="\$LAN_NETMASK"
uci set network.lan.device='br-lan'

# DSA bridge（标准写法）
uci set network.@device[0]=device
uci set network.@device[0].name='br-lan'
uci set network.@device[0].type='bridge'

# 自动加入 LAN 口（DSA安全方式）
for p in lan1 lan2 lan3 lan4 lan5 lan6; do
    uci add_list network.@device[0].ports="\$p"
done

# DHCP
uci set dhcp.lan=dhcp
uci set dhcp.lan.interface='lan'
uci set dhcp.lan.start='100'
uci set dhcp.lan.limit='150'
uci set dhcp.lan.leasetime='12h'

uci commit network
uci commit dhcp

exit 0
EOF

chmod +x files/etc/uci-defaults/99-network-fix

# ======================
# 防火墙修复（避免ping不通）
# ======================
cat > files/etc/uci-defaults/99-firewall-fix <<'EOF'
#!/bin/sh

# 放开LAN zone
for z in $(uci show firewall | grep "=zone" | cut -d. -f2 | cut -d= -f1); do
    name=$(uci get firewall.$z.name 2>/dev/null)
    [ "$name" = "lan" ] && {
        uci set firewall.$z.input='ACCEPT'
        uci set firewall.$z.output='ACCEPT'
        uci set firewall.$z.forward='ACCEPT'
    }
done

# 允许ping
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-Ping'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].proto='icmp'
uci set firewall.@rule[-1].target='ACCEPT'

uci commit firewall
exit 0
EOF

chmod +x files/etc/uci-defaults/99-firewall-fix

# ======================
# LuCI强制监听（防止Web进不去）
# ======================
mkdir -p files/etc/config

cat > files/etc/config/uhttpd <<'EOF'
config uhttpd main
    list listen_http '0.0.0.0:80'
    list listen_https '0.0.0.0:443'
EOF

# ======================
# Argon主题
# ======================
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon || true
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config || true

# ======================
# Lucky
# ======================
git clone --depth 1 https://github.com/gdy666/lucky package/lucky || true
git clone --depth 1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky || true

# ======================
# Passwall（避免冲突）
# ======================
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages || true
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall package/luci-app-passwall || true

# 删除feeds冲突
rm -rf feeds/luci/applications/luci-app-passwall 2>/dev/null || true

# ======================
# 时区 + 中文
# ======================
mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-custom <<'EOF'
#!/bin/sh

uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci set luci.main.lang='zh_cn'

uci commit system
uci commit luci

exit 0
EOF

chmod +x files/etc/uci-defaults/99-custom

# ======================
# 拷贝到OpenWrt目录
# ======================
cp -rf files "${OPENWRT_DIR}/" 2>/dev/null || true

exit 0
