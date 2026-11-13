
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
# ==================================================
clone_latest \
    https://github.com/gdy666/luci-app-lucky.git \
    package/luci-app-lucky

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
# ==================================================
clone_latest \
    https://github.com/destan19/OpenAppFilter.git \
    package/oaf

# ==================================================
# 7. Disk Management
# ==================================================
clone_latest \
    https://github.com/lisaac/luci-app-diskman.git \
    package/luci-app-diskman

# ==================================================
# 8. SmartDNS
# SmartDNS 核心和 WebUI 使用 PassWall packages
# LuCI 管理界面使用 pymumu 官方仓库
# ==================================================
clone_latest \
    https://github.com/pymumu/luci-app-smartdns.git \
    package/luci-app-smartdns

# ==================================================
# 9. 完成检查
# ==================================================
echo "========================================="
echo "DIY1 仓库检查"
echo "========================================="

required_dirs=(
    "package/luci-theme-argon"
    "package/luci-app-argon-config"
    "package/luci-app-lucky"
    "package/openwrt-passwall-packages"
    "package/luci-app-passwall"
    "package/luci-app-poweroffdevice"
    "package/luci-app-ghfu"
    "package/oaf"
    "package/luci-app-diskman"
    "package/luci-app-smartdns"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "ERROR：缺少插件目录：$dir"
        exit 1
    fi
done

echo "所有第三方插件仓库检查通过"

echo "========================================="
echo "DIY1 Finished"
echo "========================================="
