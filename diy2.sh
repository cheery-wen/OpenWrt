#!/bin/bash
set -e
set -o pipefail

# 替换25.12专用Go环境
if [ -d "feeds/packages/lang/golang" ]; then
    rm -rf feeds/packages/lang/golang
fi
git clone --depth 1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

./scripts/feeds update -a
./scripts/feeds install -a

echo "==================== Feeds 完整性校验 ===================="
./scripts/feeds list -r
echo "==================== Feeds 校验完成 ===================="

# 固化编译参数
sed -i '/^CONFIG_USE_SSTRIP/d' .config
echo "CONFIG_USE_SSTRIP=n" >> .config

sed -i '/^CONFIG_KERNEL_TRANSPARENT_HUGEPAGE/d' .config
echo "CONFIG_KERNEL_TRANSPARENT_HUGEPAGE=n" >> .config

make defconfig
rm -rf tmp build_dir/tmp* 2>/dev/null

exit 0
