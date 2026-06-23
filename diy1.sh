#!/bin/bash
set -e

echo "========================================="
echo "OpenWrt DIY1 (Clean Stable Version)"
echo "========================================="

# Theme
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# Lucky
git clone --depth 1 https://github.com/gdy666/luci-app-lucky.git package/luci-app-lucky

# PassWall
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/openwrt-passwall-packages
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall.git package/luci-app-passwall

# PowerOffDevice
git clone --depth 1 https://github.com/sirpdboy/luci-app-poweroffdevice.git package/luci-app-poweroffdevice

# GHFU
git clone --depth 1 https://github.com/smallprogram/luci-app-ghfu.git package/luci-app-ghfu

# OpenAppFilter (OAF)
git clone --depth 1 https://github.com/destan19/OpenAppFilter.git package/oaf

# Disk Management (third-party)
git clone --depth 1 https://github.com/lisaac/luci-app-diskman.git package/luci-app-diskman

echo "========================================="
echo "DIY1 Finished"
echo "========================================="
