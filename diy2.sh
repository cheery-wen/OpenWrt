
#!/bin/bash
set -euo pipefail

echo "========================================="
echo "🚀 OpenWrt 25.12 DIY2 开始"
echo "========================================="

# ==================================================
# 1. 自适应网口
# 保留原有规则：
# 第一张网卡作为 WAN，其余网卡作为 LAN
# 只有一张网卡时作为 LAN
# ==================================================
echo "🔧 配置 x86 自适应网口"

BOARD_D_PATH="target/linux/x86/base-files/etc/board.d"
mkdir -p "$BOARD_D_PATH"

cat > "$BOARD_D_PATH/02_network" << 'EOF'
#!/bin/sh

. /lib/functions.sh
. /lib/functions/uci-defaults.sh

board_config_update

ALL_ETH=$(ls /sys/class/net/ 2>/dev/null | grep -E '^eth[0-9]+$' | sort -V || true)

if [ -n "$ALL_ETH" ]; then
    COUNT=$(printf '%s\n' "$ALL_ETH" | wc -l)
else
    COUNT=0
fi

if [ "$COUNT" -ge 2 ]; then
    WAN_PORT=$(printf '%s\n' "$ALL_ETH" | head -n 1)
    LAN_PORTS=$(printf '%s\n' "$ALL_ETH" | tail -n +2 | tr '\n' ' ')

    ucidef_set_interfaces_lan_wan "$LAN_PORTS" "$WAN_PORT"

elif [ "$COUNT" -eq 1 ]; then
    ucidef_set_interface_lan "$ALL_ETH"

else
    echo "No eth interfaces found"
fi

board_config_flush

exit 0
EOF

chmod +x "$BOARD_D_PATH/02_network"

if [ ! -x "$BOARD_D_PATH/02_network" ]; then
    echo "ERROR：网口配置文件创建失败"
    exit 1
fi

echo "网口配置文件检查通过"

# ==================================================
# 2. 默认 LAN IP
# ==================================================
echo "⚙️ 设置默认 LAN IP -> 192.168.5.1"

LAN_CONFIG="package/base-files/files/bin/config_generate"

if [ ! -f "$LAN_CONFIG" ]; then
    echo "ERROR：未找到 LAN 配置文件：$LAN_CONFIG"
    exit 1
fi

if grep -q '192\.168\.1\.1' "$LAN_CONFIG"; then
    sed -i 's/192\.168\.1\.1/192.168.5.1/g' "$LAN_CONFIG"
elif grep -q '192\.168\.5\.1' "$LAN_CONFIG"; then
    echo "LAN IP 已经是 192.168.5.1"
else
    echo "ERROR：未找到预期的默认 LAN IP，停止修改"
    exit 1
fi

if ! grep -q '192\.168\.5\.1' "$LAN_CONFIG"; then
    echo "ERROR：LAN IP 修改验证失败"
    exit 1
fi

echo "LAN IP 检查通过"

# ==================================================
# 3. 默认时区
# ==================================================
echo "🕒 设置 Asia/Shanghai 时区"

TIMEZONE_DIR="package/base-files/files/etc/uci-defaults"
mkdir -p "$TIMEZONE_DIR"

cat > "$TIMEZONE_DIR/99-timezone" << 'EOF'
#!/bin/sh

uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

exit 0
EOF

chmod +x "$TIMEZONE_DIR/99-timezone"

if [ ! -x "$TIMEZONE_DIR/99-timezone" ]; then
    echo "ERROR：时区配置文件创建失败"
    exit 1
fi

echo "时区配置检查通过"

# ==================================================
# 4. 清理 Go Cache
# ==================================================
echo "🗑️ 清理 Go 模块缓存"

rm -rf dl/go-mod-cache

# ==================================================
# 5. 替换 Golang 27.x
# 获取 27.x 分支最新代码，不固定提交版本
# ==================================================
echo "🔥 配置 Golang 27.x"

GO_REPO="https://github.com/sbwml/packages_lang_golang"
GO_BRANCH="27.x"
GO_PATH="feeds/packages/lang/golang"

rm -rf "$GO_PATH"

mkdir -p "$(dirname "$GO_PATH")"

git clone --depth 1 \
    --branch "$GO_BRANCH" \
    "$GO_REPO" \
    "$GO_PATH"

GO_MAKEFILE="$GO_PATH/golang/Makefile"

if [ ! -f "$GO_MAKEFILE" ]; then
    echo "ERROR：未找到 Golang Makefile"
    exit 1
fi

if ! grep -qE '^GO_VERSION_MAJOR_MINOR:=1\.27([[:space:]]|$)' "$GO_MAKEFILE"; then
    echo "ERROR：Golang 仓库版本不是预期的 1.27 系列"
    grep -E 'GO_VERSION_MAJOR_MINOR|GO_VERSION_PATCH' "$GO_MAKEFILE" || true
    exit 1
fi

echo "Golang 27.x 检查通过"
grep -E 'GO_VERSION_MAJOR_MINOR|GO_VERSION_PATCH' "$GO_MAKEFILE"

# ==================================================
# 6. SmartDNS：清理官方重复软件包
#
# 保留：
# package/openwrt-passwall-packages/smartdns
# package/luci-app-smartdns
#
# 删除官方 feeds 中的重复版本，避免同名包冲突
# ==================================================
echo "🔧 整理 SmartDNS 软件包来源"

rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns

# 清理 feeds install 生成的对应链接或目录
rm -rf package/feeds/packages/smartdns
rm -rf package/feeds/luci/luci-app-smartdns

# ==================================================
# 7. SmartDNS 依赖检查
#
# 依赖关系：
# luci-app-smartdns -> smartdns
# luci-app-smartdns -> smartdns-ui（可选）
# smartdns-ui -> smartdns
#
# smartdns-ui 依赖核心 smartdns，不构成循环依赖。
# 保留上游 Makefile，不用正则强制改写。
# ==================================================
echo "🔧 检查 SmartDNS 依赖"

SMARTDNS_CORE_MK="package/openwrt-passwall-packages/smartdns/Makefile"
SMARTDNS_UI_MK="package/luci-app-smartdns/Makefile"

if [ ! -f "$SMARTDNS_CORE_MK" ]; then
    echo "ERROR：未找到 PassWall packages 中的 SmartDNS Makefile"
    exit 1
fi

if [ ! -f "$SMARTDNS_UI_MK" ]; then
    echo "ERROR：未找到 luci-app-smartdns Makefile"
    exit 1
fi

# 检查核心软件包定义
if ! grep -q 'Package/smartdns' "$SMARTDNS_CORE_MK"; then
    echo "ERROR：SmartDNS 核心包定义不存在"
    exit 1
fi

# 检查 WebUI 软件包定义
if ! grep -q 'Package/smartdns-ui' "$SMARTDNS_CORE_MK"; then
    echo "ERROR：SmartDNS WebUI 包定义不存在"
    exit 1
fi

# WebUI 应依赖 SmartDNS 核心
if ! grep -qE 'DEPENDS:=[^#]*\+smartdns' "$SMARTDNS_CORE_MK"; then
    echo "ERROR：SmartDNS WebUI 未声明核心依赖"
    exit 1
fi

# LuCI 应依赖 SmartDNS 核心
if ! grep -qE 'LUCI_DEPENDS:=[^#]*\+smartdns' "$SMARTDNS_UI_MK"; then
    echo "ERROR：SmartDNS LuCI 未声明核心依赖"
    exit 1
fi

echo "SmartDNS 核心、WebUI、LuCI 依赖检查通过"

# ==================================================
# 8. 检查关键软件包目录
# ==================================================
echo "🔍 检查关键软件包"

required_files=(
    "package/openwrt-passwall-packages/smartdns/Makefile"
    "package/luci-app-smartdns/Makefile"
    "feeds/packages/lang/golang/golang/Makefile"
    "target/linux/x86/base-files/etc/board.d/02_network"
    "package/base-files/files/bin/config_generate"
    "package/base-files/files/etc/uci-defaults/99-timezone"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR：缺少关键文件：$file"
        exit 1
    fi
done

echo "所有关键文件检查通过"

# ==================================================
# 9. 检查 .config 中的关键配置
# ==================================================
echo "🔍 检查关键编译配置"

if [ -f .config ]; then
    required_config=(
        "CONFIG_TARGET_x86_64=y"
        "CONFIG_TARGET_x86_64_DEVICE_generic=y"
        "CONFIG_GRUB_IMAGES=y"
        "CONFIG_GRUB_EFI_IMAGES=y"
        "CONFIG_TARGET_KERNEL_PARTSIZE=32"
        "CONFIG_TARGET_ROOTFS_PARTSIZE=512"
        "CONFIG_TARGET_ROOTFS_SQUASHFS=y"
        "CONFIG_PACKAGE_luci-app-passwall=y"
        "CONFIG_PACKAGE_smartdns=y"
        "CONFIG_PACKAGE_smartdns-ui=y"
        "CONFIG_PACKAGE_luci-app-smartdns=y"
    )

    for item in "${required_config[@]}"; do
        if ! grep -Fxq "$item" .config; then
            echo "ERROR：缺少配置：$item"
            exit 1
        fi
    done

    echo ".config 关键配置检查通过"
else
    echo "ERROR：未找到 .config"
    exit 1
fi

# ==================================================
# 完成
# ==================================================
echo "========================================="
echo "✅ OpenWrt 25.12 DIY2 执行完成"
echo "========================================="
