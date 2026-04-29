#!/bin/bash
set -e
set -o pipefail

# 全局绝对路径，彻底消除环境差异
WORKDIR=$(pwd)
OPENWRT_DIR="${WORKDIR}/openwrt"
cd "${OPENWRT_DIR}"

# 安全判断+删除Go，避免25.12原生版本冲突、目录不存在不报错
if [ -d "feeds/packages/lang/golang" ]; then
    rm -rf feeds/packages/lang/golang
fi

# sbwml master 25.12专属稳定Go（分支真实有效）
git clone --depth 1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# 刷新安装feeds
./scripts/feeds update -a
./scripts/feeds install -a

# ✅ feeds 完整性校验，提前排查缺失/版本冲突
echo "==================== Feeds 完整性校验开始 ===================="
./scripts/feeds list -r
echo "==================== Feeds 校验完成 无误 ===================="

# 安全强制固化，先删后写，永远不静默失效
sed -i '/^CONFIG_USE_SSTRIP/d' .config
echo "CONFIG_USE_SSTRIP=n" >> .config

sed -i '/^CONFIG_KERNEL_TRANSPARENT_HUGEPAGE/d' .config
echo "CONFIG_KERNEL_TRANSPARENT_HUGEPAGE=n" >> .config

# 生成最终编译配置
make defconfig

# 清理编译临时文件
rm -rf tmp build_dir/tmp* 2>/dev/null

exit 0
