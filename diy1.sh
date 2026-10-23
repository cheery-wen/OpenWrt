#!/bin/bash
set -e

echo "========================================="
echo "OpenWrt DIY1"
echo "========================================="

# ==================================================
# 1. Argon Theme
# ==================================================
echo "🎨 添加 Argon 主题"

git clone --depth 1 \
    https://github.com/jerrykuku/luci-theme-argon.git \
    package/luci-theme-argon

git clone --depth 1 \
    https://github.com/jerrykuku/luci-app-argon-config.git \
    package/luci-app-argon-config

# ==================================================
# 2. Lucky
# ==================================================
echo "🍀 添加 Lucky"

git clone --depth 1 \
    https://github.com/gdy666/luci-app-lucky.git \
    package/luci-app-lucky

# ==================================================
# 3. PassWall packages + PassWall LuCI
# 包含 PassWall 所需依赖，以及 SmartDNS 核心和 WebUI
# ==================================================
echo "🚀 添加 PassWall 软件包"

git clone --depth 1 \
    https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git \
    package/openwrt-passwall-packages

git clone --depth 1 \
    https://github.com/Openwrt-Passwall/openwrt-passwall.git \
    package/luci-app-passwall

# ==================================================
# 4. PowerOffDevice
# ==================================================
echo "🔌 添加 PowerOffDevice"

git clone --depth 1 \
    https://github.com/sirpdboy/luci-app-poweroffdevice.git \
    package/luci-app-poweroffdevice

# ==================================================
# 5. GHFU
# ==================================================
echo "⬆️ 添加 GHFU"

git clone --depth 1 \
    https://github.com/smallprogram/luci-app-ghfu.git \
    package/luci-app-ghfu

# ==================================================
# 6. OpenAppFilter
# ==================================================
echo "🛡️ 添加 OpenAppFilter"

git clone --depth 1 \
    https://github.com/destan19/OpenAppFilter.git \
    package/oaf

# ==================================================
# 7. DiskMan
# ==================================================
echo "💽 添加 DiskMan"

git clone --depth 1 \
    https://github.com/lisaac/luci-app-diskman.git \
    package/luci-app-diskman

# ==================================================
# 8. 官方 SmartDNS LuCI
#
# 注意：
# 不再克隆 pymumu/openwrt-smartdns。
# SmartDNS 核心与 smartdns-ui 统一使用
# openwrt-passwall-packages 中的版本。
# ==================================================
echo "🌐 添加官方 SmartDNS LuCI"

git clone --depth 1 \
    https://github.com/pymumu/luci-app-smartdns.git \
    package/luci-app-smartdns

# ==================================================
# 9. 检查必要目录
# ==================================================
echo
echo "========== DIY1 软件包检查 =========="

for f in \
    package/openwrt-passwall-packages/smartdns/Makefile \
    package/luci-app-smartdns/Makefile \
    package/luci-app-passwall/Makefile \
    package/luci-theme-argon/Makefile \
    package/luci-app-argon-config/Makefile \
    package/luci-app-lucky/Makefile \
    package/luci-app-poweroffdevice/Makefile \
    package/luci-app-ghfu/Makefile \
    package/luci-app-diskman/Makefile
do
    if [ -f "$f" ]; then
        echo "✅ $f"
    else
        echo "❌ 缺少文件：$f"
        exit 1
    fi
done

echo
echo "========================================="
echo "✅ OpenWrt DIY1 执行完成"
echo "========================================="
