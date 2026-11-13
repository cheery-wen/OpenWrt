
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
# ==================================================
clone_latest \
    https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git \
    package/openwrt-passwall-packages

clone_latest \
    https://github.com/Openwrt-Passwall/openwrt-passwall.git \
    package/luci-app-passwall

# ==================================================
# 4. PowerOffDevice
# ==================================================
clone_latest \
    https://github.com/sirpdboy/luci-app-poweroffdevice.git \
    package/luci-app-poweroffdevice

# ==================================================
# 5. GHFU
# ==================================================
clone_latest \
    https://github.com/smallprogram/luci-app-ghfu.git \
    package/luci-app-ghfu

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

if [ ! -f "$DISKMAN_SRC/applications/luci-app-diskman/Makefile" ]; then
    echo "ERROR：DiskMan 上游目录结构不符合预期"
    exit 1
fi

if [ ! -f "$DISKMAN_SRC/Parted.Makefile" ]; then
    echo "ERROR：DiskMan 缺少 Parted.Makefile"
    exit 1
fi

mkdir -p package/luci-app-diskman
mkdir -p package/parted

cp -a \
    "$DISKMAN_SRC/applications/luci-app-diskman/." \
    package/luci-app-diskman/

cp \
    "$DISKMAN_SRC/Parted.Makefile" \
    package/parted/Makefile

rm -rf "$DISKMAN_SRC"

# ==================================================
# 8. TimeControl
#
# 上游仓库内层目录才是 OpenWrt package：
# luci-app-timecontrol/Makefile
# ==================================================
TIMECONTROL_SRC="package/luci-app-timecontrol-src"

clone_latest \
    https://github.com/sirpdboy/luci-app-timecontrol.git \
    "$TIMECONTROL_SRC"

if [ ! -f "$TIMECONTROL_SRC/luci-app-timecontrol/Makefile" ]; then
    echo "ERROR：TimeControl 上游目录结构不符合预期"
    exit 1
fi

mkdir -p package/luci-app-timecontrol

cp -a \
    "$TIMECONTROL_SRC/luci-app-timecontrol/." \
    package/luci-app-timecontrol/

rm -rf "$TIMECONTROL_SRC"

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
# 10. 第三方软件包检查
# ==================================================
echo "========================================="
echo "DIY1 软件包检查"
echo "========================================="

required_files=(
    "package/luci-theme-argon/Makefile"
    "package/luci-app-argon-config/Makefile"

    # Lucky：核心和 LuCI 界面
    "package/lucky/lucky/Makefile"
    "package/lucky/luci-app-lucky/Makefile"

    # PassWall
    "package/openwrt-passwall-packages"
    "package/luci-app-passwall/Makefile"

    # 其他插件
    "package/luci-app-poweroffdevice/Makefile"
    "package/luci-app-ghfu/Makefile"

    # OpenAppFilter
    "package/oaf/oaf/Makefile"
    "package/oaf/open-app-filter/Makefile"
    "package/oaf/luci-app-oaf/Makefile"

    # DiskMan
    "package/luci-app-diskman/Makefile"
    "package/parted/Makefile"

    # TimeControl
    "package/luci-app-timecontrol/Makefile"

    # SmartDNS LuCI
    "package/luci-app-smartdns/Makefile"
)

for file in "${required_files[@]}"; do
    if [ ! -e "$file" ]; then
        echo "ERROR：缺少插件文件：$file"
        exit 1
    fi
done

# ==================================================
# 11. SmartDNS 核心检查
# ==================================================
if [ ! -f "package/openwrt-passwall-packages/smartdns/Makefile" ]; then
    echo "ERROR：未找到 PassWall packages 中的 SmartDNS"
    exit 1
fi

echo "所有第三方插件源码检查通过"

echo "========================================="
echo "DIY1 Finished"
echo "========================================="
