#!/bin/bash
set -Eeuo pipefail

# ============================================================
# OpenWrt 25.12 DIY1
# 官方 OpenWrt x86_64
#
# 功能：
# 1. 添加 Argon 主题及配置
# 2. 添加 Lucky
# 3. 添加 PassWall（不是 PassWall2）
# 4. 添加 poweroffdevice、GHFU、OAF、DiskMan
# 5. 添加官方 luci-app-smartdns
# 6. SmartDNS 核心及 WebUI 使用 PassWall packages 仓库版本
# ============================================================

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

echo "=================================================="
echo "🚀 OpenWrt DIY1 开始"
echo "=================================================="

# 确认当前处于 OpenWrt 源码根目录
if [[ ! -f "include/kernel.mk" || ! -d "package" ]]; then
    echo "❌ 当前目录不是 OpenWrt 源码根目录"
    exit 1
fi

# 统一克隆函数：已存在目标目录时先清理
clone_repo() {
    local repo="$1"
    local branch="$2"
    local dest="$3"

    echo
    echo "➡️ 克隆：${repo}"
    echo "➡️ 分支：${branch}"
    echo "➡️ 目录：${dest}"

    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"

    if ! git clone --depth 1 --single-branch \
        --branch "$branch" "$repo" "$dest"; then
        echo "❌ 克隆失败：$repo"
        exit 1
    fi
}

# ============================================================
# 1. Argon 主题
# ============================================================
echo
echo "========== 1. Argon 主题 =========="

clone_repo \
    "https://github.com/jerrykuku/luci-theme-argon.git" \
    "master" \
    "package/luci-theme-argon"

# Argon 配置插件
clone_repo \
    "https://github.com/jerrykuku/luci-app-argon-config.git" \
    "master" \
    "package/luci-app-argon-config"

# ============================================================
# 2. Lucky
# ============================================================
echo
echo "========== 2. Lucky =========="

clone_repo \
    "https://github.com/gdy666/luci-app-lucky.git" \
    "main" \
    "package/luci-app-lucky"

# ============================================================
# 3. PassWall 软件包
# ============================================================
echo
echo "========== 3. PassWall 软件包 =========="

clone_repo \
    "https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git" \
    "main" \
    "package/openwrt-passwall-packages"

# 检查 PassWall 软件包仓库中的 SmartDNS 核心
if [[ -f "package/openwrt-passwall-packages/smartdns/Makefile" ]]; then
    echo "✅ PassWall packages 中的 SmartDNS 核心存在"
else
    echo "❌ 未找到 PassWall packages 中的 SmartDNS Makefile"
    find package/openwrt-passwall-packages -maxdepth 3 \
        -name Makefile -print | head -80
    exit 1
fi

# ============================================================
# 4. PassWall LuCI（不是 PassWall2）
# ============================================================
echo
echo "========== 4. PassWall LuCI =========="

PASSWALL_REPO="https://github.com/Openwrt-Passwall/openwrt-passwall.git"
PASSWALL_DEST="package/passwall-luci"

clone_repo \
    "$PASSWALL_REPO" \
    "main" \
    "$PASSWALL_DEST"

# 上游仓库实际结构：
# package/passwall-luci/luci-app-passwall/Makefile
if [[ -f "$PASSWALL_DEST/luci-app-passwall/Makefile" ]]; then
    echo "✅ 找到 luci-app-passwall/Makefile"
elif [[ -f "$PASSWALL_DEST/Makefile" ]]; then
    echo "ℹ️ Makefile 位于仓库根目录，使用根目录作为包路径"
else
    echo "❌ 没有找到 PassWall LuCI Makefile"
    echo "========== 克隆目录内容 =========="
    ls -la "$PASSWALL_DEST" || true
    echo "========== 搜索 Makefile =========="
    find "$PASSWALL_DEST" -maxdepth 4 \
        -name Makefile -print | head -100
    echo "========== Git 信息 =========="
    git -C "$PASSWALL_DEST" remote -v || true
    git -C "$PASSWALL_DEST" log -1 --oneline || true
    exit 1
fi

# ============================================================
# 5. poweroffdevice
# ============================================================
echo
echo "========== 5. poweroffdevice =========="

clone_repo \
    "https://github.com/esirplayground/luci-app-poweroffdevice.git" \
    "master" \
    "package/luci-app-poweroffdevice"

# ============================================================
# 6. GHFU
# ============================================================
echo
echo "========== 6. GHFU =========="

clone_repo \
    "https://github.com/destan19/OpenAppFilter.git" \
    "master" \
    "package/OpenAppFilter"

# ============================================================
# 7. OpenAppFilter
# ============================================================
echo
echo "========== 7. OpenAppFilter =========="

# 若你原仓库使用的是另一份 OAF 地址，请保留原地址替换这里。
# 先检查是否已由上一步仓库提供相关包，避免重复克隆同名目录。
if [[ -d "package/OpenAppFilter" ]]; then
    echo "ℹ️ OpenAppFilter 目录已存在，跳过重复克隆"
else
    echo "⚠️ OpenAppFilter 仓库目录不存在，请检查原有仓库地址"
fi

# ============================================================
# 8. DiskMan
# ============================================================
echo
echo "========== 8. DiskMan =========="

clone_repo \
    "https://github.com/lisaac/luci-app-diskman.git" \
    "master" \
    "package/luci-app-diskman"

# ============================================================
# 9. 官方 SmartDNS LuCI
# ============================================================
echo
echo "========== 9. 官方 SmartDNS LuCI =========="

clone_repo \
    "https://github.com/pymumu/luci-app-smartdns.git" \
    "master" \
    "package/luci-app-smartdns"

if [[ -f "package/luci-app-smartdns/Makefile" ]]; then
    echo "✅ 官方 luci-app-smartdns Makefile 存在"
else
    echo "❌ 官方 luci-app-smartdns Makefile 缺失"
    find package/luci-app-smartdns -maxdepth 3 \
        -name Makefile -print | head -50
    exit 1
fi

# ============================================================
# 10. 检查重要软件包
# ============================================================
echo
echo "========== 10. 软件包检查 =========="

check_file() {
    local file="$1"

    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ 缺少文件：$file"
        return 1
    fi
}

check_file \
    "package/openwrt-passwall-packages/smartdns/Makefile"

check_file \
    "package/luci-app-smartdns/Makefile"

check_file \
    "package/passwall-luci/luci-app-passwall/Makefile"

# ============================================================
# 11. DIY1 完成
# ============================================================
echo
echo "=================================================="
echo "✅ DIY1 完成"
echo "=================================================="
echo "Argon：已添加"
echo "Lucky：已添加"
echo "PassWall：已添加（不是 PassWall2）"
echo "SmartDNS 核心：使用 PassWall packages 仓库"
echo "SmartDNS LuCI：使用 pymumu/luci-app-smartdns"
echo "=================================================="
