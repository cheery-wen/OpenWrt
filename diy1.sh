
#!/bin/bash
set -euo pipefail

echo "========================================="
echo "OpenWrt DIY1"
echo "========================================="

# ==================================================
# 通用克隆函数
# 获取上游最新代码，不固定提交版本
# ==================================================
clone_latest() {
    local repo="$1"
    local target="$2"

    if [ -e "$target" ]; then
        echo "ERROR：目标目录已存在：$target"
        exit 1
    fi

    echo "正在获取：$repo"

    git clone --depth 1 "$repo" "$target"

    if [ ! -d "$target/.git" ]; then
        echo "ERROR：仓库克隆失败：$repo"
        exit 1
    fi
}

# ==================================================
# 1. Argon Theme
# ==================================================
clone_latest \
    https://github.com/jerrykuku/luci-theme-argon.git \
    package/luci-theme-argon

clone_latest \
    https://github.com/jerrykuku/luci-app-argon-config.git \
    package/luci-app-argon-config

# ==================================================
# 2. Lucky
#
# 上游仓库包含两个软件包：
# lucky/Makefile             -> lucky
# luci-app-lucky/Makefile    -> luci-app-lucky
#
# 注意：必须克隆到 package/lucky
# ==================================================
clone_latest \
    https://github.com/gdy666/luci-app-lucky.git \
    package/lucky

# ==================================================
# 3. PassWall
# 保留 PassWall，不替换为 PassWall2
#
# 上游仓库内部目录：
# luci-app-passwall/Makefile
#
# 复制内部软件包内容到标准 package 目录
# ==================================================
clone_latest \
    https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git \
    package/openwrt-passwall-packages

PASSWALL_SRC="package/luci-app-passwall-src"

clone_latest \
    https://github.com/Openwrt-Passwall/openwrt-passwall.git \
    "$PASSWALL_SRC"

mkdir -p package/luci-app-passwall

cp -a \
    "$PASSWALL_SRC/luci-app-passwall/." \
    package/luci-app-passwall/

rm -rf "$PASSWALL_SRC"

echo "PassWall 软件包安装完成"

# ==================================================
# 4. PowerOffDevice
#
# 上游仓库内层目录才是 OpenWrt package：
# luci-app-poweroffdevice/
#
# 复制内部软件包到标准 package 目录
# ==================================================
POWEROFF_SRC="package/luci-app-poweroffdevice-src"

clone_latest \
    https://github.com/sirpdboy/luci-app-poweroffdevice.git \
    "$POWEROFF_SRC"

mkdir -p package/luci-app-poweroffdevice

cp -a \
    "$POWEROFF_SRC/luci-app-poweroffdevice/." \
    package/luci-app-poweroffdevice/

rm -rf "$POWEROFF_SRC"

echo "PowerOffDevice 软件包安装完成"

# ==================================================
# 5. GHFU
#
# 使用上游新仓库：
# smallprogram/openwrt-ghfu
#
# 上游软件包位于：
# luci-app-ghfu/
#
# 复制内部软件包到标准 package 目录
# ==================================================
GHFU_SRC="package/luci-app-ghfu-src"

clone_latest \
    https://github.com/smallprogram/openwrt-ghfu.git \
    "$GHFU_SRC"

mkdir -p package/luci-app-ghfu

cp -a \
    "$GHFU_SRC/luci-app-ghfu/." \
    package/luci-app-ghfu/

rm -rf "$GHFU_SRC"

echo "GHFU 软件包安装完成"

# ==================================================
# 6. OpenAppFilter (OAF)
#
# 一个仓库包含三个软件包：
# oaf/Makefile             -> kmod-oaf
# open-app-filter/Makefile -> appfilter
# luci-app-oaf/Makefile    -> luci-app-oaf
# ==================================================
clone_latest \
    https://github.com/destan19/OpenAppFilter.git \
    package/oaf

# ==================================================
# 7. Disk Management
#
# 上游仓库不是标准单一 package 目录。
# 正确安装：
# applications/luci-app-diskman -> package/luci-app-diskman
# Parted.Makefile               -> package/parted/Makefile
# ==================================================
DISKMAN_SRC="package/luci-app-diskman-src"

clone_latest \
    https://github.com/lisaac/luci-app-diskman.git \
    "$DISKMAN_SRC"

mkdir -p package/luci-app-diskman
mkdir -p package/parted

cp -a \
    "$DISKMAN_SRC/applications/luci-app-diskman/." \
    package/luci-app-diskman/

cp \
    "$DISKMAN_SRC/Parted.Makefile" \
    package/parted/Makefile

rm -rf "$DISKMAN_SRC"

echo "DiskMan 软件包安装完成"

# ==================================================
# 8. TimeControl
#
# 上游仓库内层目录才是 OpenWrt package：
# luci-app-timecontrol/
# ==================================================
TIMECONTROL_SRC="package/luci-app-timecontrol-src"

clone_latest \
    https://github.com/sirpdboy/luci-app-timecontrol.git \
    "$TIMECONTROL_SRC"

mkdir -p package/luci-app-timecontrol

cp -a \
    "$TIMECONTROL_SRC/luci-app-timecontrol/." \
    package/luci-app-timecontrol/

rm -rf "$TIMECONTROL_SRC"

echo "TimeControl 软件包安装完成"

# ==================================================
# 9. SmartDNS
#
# SmartDNS 核心和 WebUI 使用 PassWall packages
# LuCI 管理界面使用 pymumu 官方仓库
# ==================================================
clone_latest \
    https://github.com/pymumu/luci-app-smartdns.git \
    package/luci-app-smartdns

# ==================================================
# DIY1 完成
# 不执行第三方软件包检查
# ==================================================
echo "========================================="
echo "DIY1 Finished"
echo "========================================="
