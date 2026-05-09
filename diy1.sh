#!/bin/sh
set -e

WORKDIR=$(pwd)
OPENWRT_DIR="${WORKDIR}"

LAN_IP="192.168.1.1"
LAN_NETMASK="255.255.255.0"

build_date=$(TZ=Asia/Shanghai date +%Y.%m.%d)

# 版本信息
if [ -f package/base-files/files/etc/openwrt_release ]; then
    sed -i "s/DISTRIB_REVISION='.*'/DISTRIB_REVISION='(${build_date} compiled by cheery)'/" \
        package/base-files/files/etc/openwrt_release
fi

if [ -f package/base-files/files/etc/banner ]; then
    sed -i "s/OpenWrt /OpenWrt (${build_date} compiled by cheery) /" \
        package/base-files/files/etc/banner
fi

# Passwall
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages || true
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall package/luci-app-passwall || true

rm -rf feeds/luci/applications/luci-app-passwall 2>/dev/null || true

# Argon
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon || true
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config || true

# Lucky
git clone --depth 1 https://github.com/gdy666/lucky package/lucky || true
git clone --depth 1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky || true

mkdir -p files/etc/uci-defaults

# network
cat > files/etc/uci-defaults/99-network-fix <<EOF
#!/bin/sh

LAN_IP="${LAN_IP}"
LAN_NETMASK="${LAN_NETMASK}"

uci -q delete network.br_lan
uci -q delete network.@device[0]

uci set network.br_lan='device'
uci set network.br_lan.name='br-lan'
uci set network.br_lan.type='bridge'

for dev in \$(ls /sys/class/net); do
    case "\$dev" in
        lo|br-*|docker*|veth*|tun*|tap*)
            continue
        ;;
    esac

    uci add_list network.br_lan.ports="\$dev"
done

uci set network.lan.proto='static'
uci set network.lan.ipaddr="\$LAN_IP"
uci set network.lan.netmask="\$LAN_NETMASK"
uci set network.lan.device='br-lan'

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

# firewall
cat > files/etc/uci-defaults/99-firewall-fix <<'EOF'
#!/bin/sh

for z in $(uci show firewall | grep "=zone" | cut -d. -f2 | cut -d= -f1); do
    name=$(uci get firewall.$z.name 2>/dev/null)

    [ "$name" = "lan" ] && {
        uci set firewall.$z.input='ACCEPT'
        uci set firewall.$z.output='ACCEPT'
        uci set firewall.$z.forward='ACCEPT'
    }
done

uci -q delete firewall.allow_ping

uci set firewall.allow_ping='rule'
uci set firewall.allow_ping.name='Allow-Ping'
uci set firewall.allow_ping.src='lan'
uci set firewall.allow_ping.proto='icmp'
uci set firewall.allow_ping.target='ACCEPT'

uci commit firewall

exit 0
EOF

chmod +x files/etc/uci-defaults/99-firewall-fix

# uhttpd
cat > files/etc/uci-defaults/99-uhttpd-fix <<'EOF'
#!/bin/sh

uci -q delete uhttpd.main.listen_http
uci add_list uhttpd.main.listen_http='0.0.0.0:80'
uci add_list uhttpd.main.listen_http='[::]:80'

uci -q delete uhttpd.main.listen_https
uci add_list uhttpd.main.listen_https='0.0.0.0:443'
uci add_list uhttpd.main.listen_https='[::]:443'

uci commit uhttpd

exit 0
EOF

chmod +x files/etc/uci-defaults/99-uhttpd-fix

# 中文+时区
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

cp -rf files "${OPENWRT_DIR}/" 2>/dev/null || true

exit 0
