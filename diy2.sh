#!/bin/bash
set -e
set -o pipefail

# ========== 2. 清理 Go 模块缓存 ==========
echo "🗑️ 清理 Go 模块缓存..."
rm -rf dl/go-mod-cache 2>/dev/null || true
echo "✅ Go 缓存已清理"

# ========== 3. 替换官方 Golang 为 26.x 版本 ==========
#rm -rf feeds/packages/lang/golang
#git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
#echo "✅ Golang 已更新至 26.x"

#echo "==================== Feeds 完整性校验 ===================="
#./scripts/feeds list -r
#echo "==================== Feeds 校验完成 ===================="

make defconfig

rm -rf tmp build_dir/tmp* 2>/dev/null

exit 0
