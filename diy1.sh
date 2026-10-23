#!/bin/bash
set -e

echo "========================================="
echo "OpenWrt DIY1 (Clean Stable Version)"
echo "========================================="

# ==================================================
# 1. Argon Theme
# ==================================================
git clone --depth 1 \
    https://github.com/jerrykuku/luci-theme-argon.git \
    package/luci-theme-argon

git clone --depth 1 \
    https://github.com/jerrykuku/luci-app-argon-config.git \
    package/luci-app-argon-config

# ==================================================
# 2. Lucky
# ==================================================
git clone --depth 1 \
    https://github.com/gdy666/luci-app-lucky.git \
    package/luci-app-lucky

# ==================================================
# 3. PassWall
# ==================================================
git clone --depth 1 \
    https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git \
    package/openwrt-passwall-packages

git clone --depth 1 \
    https://github.com/Openwrt-Passwall/openwrt-passwall.git \
    package/luci-app-passwall

# ==================================================
# 4. PowerOffDevice
# ==================================================
git clone --depth 1 \
    https://github.com/sirpdboy/luci-app-poweroffdevice.git \
    package/luci-app-poweroffdevice

# ==================================================
# 5. GHFU
# ==================================================
git clone --depth 1 \
    https://github.com/smallprogram/luci-app-ghfu.git \
    package/luci-app-ghfu

# ==================================================
# 6. OpenAppFilter (OAF)
# ==================================================
git clone --depth 1 \
    https://github.com/destan19/OpenAppFilter.git \
    package/oaf

# ==================================================
# 7. Disk Management
# ==================================================
git clone --depth 1 \
    https://github.com/lisaac/luci-app-diskman.git \
    package/luci-app-diskman

# ==================================================
# 8. SmartDNS
# SmartDNS core and smartdns-ui use PassWall packages.
# LuCI uses the official pymumu repository.
# ==================================================
git clone --depth 1 \
    https://github.com/pymumu/luci-app-smartdns.git \
    package/luci-app-smartdns

echo "========================================="
echo "DIY1 Finished"
echo "========================================="
