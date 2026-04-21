# ---------- 5. 清理 Go 模块缓存 ----------
echo "🗑️ 清理 Go 模块缓存..."
rm -rf dl/go-mod-cache 2>/dev/null || true
echo "✅ Go 缓存已清理"



# 替换官方 Golang 为 26.x 版本
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
echo "✅ Golang 已更新至 26.x"

echo "✅ diy2.sh 执行完成"
