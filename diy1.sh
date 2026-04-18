#!/bin/bash
# ============================================
# DIY 脚本 1 - 在更新 feeds 前执行
# 功能：修改源码配置、添加第三方插件
# ============================================

set -e

# 禁用 Git 交互式认证提示
export GIT_ASKPASS=echo

# 定义带重试的克隆函数
clone_with_retry() {
    local url="$1"
    local dest="$2"
    local retries=3
    local delay=5

    for i in $(seq 1 $retries); do
        echo ">>> 尝试克隆 ($i/$retries): $url -> $dest"
        if git clone --depth 1 "$url" "$dest"; then
            return 0
        fi
        echo "⚠️ 克隆失败，${delay}秒后重试..."
        sleep $delay
    done
    echo "❌ 克隆失败已达最大重试次数: $url"
    return 1
}

# ---------- 1. 修改默认 IP 地址为 192.168.5.1 ----------
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# ---------- 2. 清除登录密码 ----------
if [ -f "package/base-files/files/etc/shadow" ]; then
    sed -i 's/root:[^:]*:/root::/g' package/base-files/files/etc/shadow
fi

# ---------- 3. 自定义固件版本显示 ----------
sed -i "s/DISTRIB_REVISION='.*'/DISTRIB_REVISION='$(TZ=UTC-8 date "+%Y.%m.%d") compiled by cheery'/g" package/base-files/files/etc/openwrt_release

# ---------- 4. 删除有依赖问题的软件包 ----------
rm -rf feeds/packages/net/onionshare-cli 2>/dev/null || true

# ---------- 5. 添加第三方插件（带重试机制）----------
echo ">>> 添加 Argon 主题与配置"
clone_with_retry "https://github.com/jerrykuku/luci-theme-argon.git" "package/luci-theme-argon"
clone_with_retry "https://github.com/jerrykuku/luci-app-argon-config.git" "package/luci-app-argon-config"

echo ">>> 添加 Lienol 插件 (访问限制、内存释放)"
clone_with_retry "https://github.com/Lienol/openwrt-package.git" "package/lienol-packages"

echo ">>> 添加关机按钮"
clone_with_retry "https://github.com/esirplayground/luci-app-poweroff.git" "package/luci-app-poweroff"

echo ">>> 添加 Lucky"
clone_with_retry "https://github.com/gdy666/luci-app-lucky.git" "package/luci-app-lucky"

echo ">>> 添加 PassWall"
clone_with_retry "https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git" "package/openwrt-passwall-packages"
clone_with_retry "https://github.com/Openwrt-Passwall/openwrt-passwall.git" "package/luci-app-passwall"

echo ">>> 添加 Autocore"
# 原仓库已失效，替换为有效镜像
clone_with_retry "https://github.com/1715173329/autocore.git" "package/autocore"

echo ">>> 添加 USB 自动共享 (autosamba)"
clone_with_retry "https://github.com/sbwml/autosamba.git" "package/autosamba"

echo "✅ diy1.sh 执行完成"
