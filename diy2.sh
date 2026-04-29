#!/bin/bash
set -e
set -o pipefail

# 当前已处于 openwrt 目录，不二次切路径
WORKDIR=$(pwd)

# 安全判断删除旧Go，不存在不报错
if [ -d "feeds/packages/lang/golang" ]; then
    rm -rf feeds/packages/lang/golang
fi

# 拉取25.12专属稳定Go
git clone --depth 1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# 更新+安装feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Feeds完整性预检
echo "==================== Feeds 完整性校验开始 ===================="
./scripts/feeds list -r
echo "==================== Feeds 校验完成 无误 ===================="

# 安全固化配置，先删后写不失效
sed -i '/^CONFIG_USE_SSTRIP/d' .config
echo "CONFIG_USE_SSTRIP=n" >> .config

sed -i '/^CONFIG_KERNEL_TRANSPARENT_HUGEPAGE/d' .config
echo "CONFIG_KERNEL_TRANSPARENT_HUGEPAGE=n" >> .config

make defconfig

rm -rf tmp build_dir/tmp* 2>/dev/null

exit 0
