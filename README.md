OpenWrt 25.12 x86_64

基于 OpenWrt 官方源码构建的 x86_64 软路由固件，适用于常见 x86 工控机、迷你主机及多网口软路由设备。

固件信息

项目| 配置
源码| "OpenWrt 官方源码" (https://github.com/openwrt/openwrt)
源码分支| "openwrt-25.12"
Stable 版本| "v25.12.6"
Snapshot 版本| "openwrt-25.12"
架构| x86_64
设备类型| Generic
引导方式| GRUB BIOS / EFI
文件系统| SquashFS
Kernel 分区| 32 MB
Rootfs 分区| 512 MB
默认 LAN 地址| "192.168.5.1"
默认时区| "Asia/Shanghai"
默认语言| 简体中文

主要特性

系统与网络

- 基于 OpenWrt 官方 25.12 源码。
- 支持 x86_64 Generic 通用设备。
- 支持传统 BIOS 和 UEFI 启动。
- SquashFS 固件格式。
- Firewall4 防火墙及 nftables。
- IPv4 / IPv6 网络支持。
- TCP BBR 拥塞控制。
- TCP Fast Open。
- x86 网口自动识别及 WAN / LAN 初始化配置。
- 默认 LAN 地址："192.168.5.1"。
- 默认时区："Asia/Shanghai"。

LuCI 管理界面

- LuCI Web 管理界面。
- 简体中文语言支持。
- Argon 主题。
- Argon 主题配置插件。
- HTTPS 管理界面。
- ttyd Web 终端。
- 文件传输管理。

网络与代理插件

- PassWall。
- Lucky 内网穿透及网络服务管理。
- SmartDNS DNS 分流与解析服务。
- Cloudflare DDNS 相关支持。
- GHFU。

存储与 NAS

- Block Mount 磁盘挂载管理。
- ext4 文件系统。
- exFAT 文件系统。
- NTFS3 文件系统。
- FAT / VFAT 文件系统。
- USB 2.0 / USB 3.0 存储支持。
- USB UAS 支持。
- Samba4 文件共享。
- DiskMan 磁盘管理界面。
- Parted 分区工具。
- Smartmontools 磁盘健康检测。
- hd-idle 硬盘休眠管理。

系统管理与辅助功能

- CPUFreq CPU 频率管理。
- PowerOffDevice 设备关机管理。
- TimeControl 网络时间控制。
- OpenAppFilter 应用过滤。
- htop 系统资源查看。
- iperf3 网络性能测试。
- tcpdump 网络抓包。
- chrony 时间同步。

编译方式

本项目通过 GitHub Actions 自动构建固件。

1. 进入仓库的 Actions 页面。
2. 选择「编译官方 OpenWrt 25.12」工作流。
3. 点击 Run workflow。
4. 选择编译模式：
   - Stable：使用官方 OpenWrt "v25.12.6" 标签。
   - Snapshot：使用官方 "openwrt-25.12" 分支最新源码。
5. 启动编译并等待任务完成。
6. 在 Actions Artifacts 或对应 Release 中获取固件。

源码与 Feeds

- OpenWrt 使用官方源码仓库。
- 默认使用官方 "feeds.conf.default"。
- 如果仓库根目录存在自定义 "feeds.conf.default"，则优先使用仓库中的文件。
- 第三方插件由 DIY 脚本集成。

注意事项

1. 本项目面向 x86_64 Generic 设备，不保证适用于所有硬件平台。
2. 不同设备的网卡数量、网卡驱动及接口命名可能不同，首次使用建议检查 WAN / LAN 接口分配。
3. 首次刷写前请确认启动方式与设备 BIOS / UEFI 设置匹配。
4. 固件默认 LAN 地址为 "192.168.5.1"，请确保本地网络没有地址冲突。
5. Stable 模式固定 OpenWrt 源码版本，但第三方插件使用上游仓库代码，插件更新可能影响构建结果。
6. OpenAppFilter 内核模块需要结合当前 OpenWrt 内核版本进行编译兼容性验证。
7. 第三方插件是否最终进入固件，以编译配置检查及实际构建结果为准。


免责声明

本项目仅供个人学习、测试及技术交流使用。

刷写固件前请自行备份原有配置和数据。因刷写、配置或使用本固件造成的数据丢失、设备故障及其他损失，由使用者自行承担。
