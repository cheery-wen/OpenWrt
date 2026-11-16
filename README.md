
# OpenWrt 25.12 x86_64

基于 OpenWrt 官方源码构建的 x86_64 软路由固件，面向常见 x86 工控机、迷你主机及多网口软路由设备。

项目采用 GitHub Actions 自动编译，基于官方 OpenWrt 25.12 系列源码，集成常用网络、代理、存储及系统管理插件。

## 固件信息

- **源码：** [OpenWrt 官方源码](https://github.com/openwrt/openwrt)
- **源码分支：** openwrt-25.12
- **Stable 版本：** v25.12.6
- **Snapshot 版本：** openwrt-25.12
- **架构：** x86_64
- **设备类型：** Generic
- **引导方式：** GRUB BIOS / EFI
- **文件系统：** SquashFS
- **Kernel 分区：** 32 MB
- **Rootfs 分区：** 512 MB
- **默认 LAN 地址：** 192.168.5.1
- **默认时区：** Asia/Shanghai
- **默认语言：** 简体中文

## 主要特性

### 系统与网络

- 基于 OpenWrt 官方 25.12 源码。
- 支持 x86_64 Generic 通用设备。
- 支持传统 BIOS 和 UEFI 启动。
- SquashFS 固件格式。
- Firewall4 防火墙及 nftables。
- IPv4 / IPv6 网络支持。
- TCP BBR 拥塞控制。
- TCP Fast Open。
- x86 网口自动识别及 WAN / LAN 初始化配置。
- 默认 LAN 地址：192.168.5.1。
- 默认时区：Asia/Shanghai。
- 保留官方内核及网络驱动支持，避免针对单一硬件平台进行强制调优。

### LuCI 管理界面

- LuCI Web 管理界面。
- 简体中文语言支持。
- Argon 主题。
- Argon 主题配置插件。
- HTTPS 管理界面。
- ttyd Web 终端。
- 文件传输管理。

### 网络与代理插件

- PassWall 代理管理。
- Lucky 内网穿透及网络服务管理。
- SmartDNS DNS 分流与解析服务。
- Cloudflare DDNS 相关支持。
- GHFU。

### 存储与 NAS

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

### 系统管理与辅助功能

- PowerOffDevice 设备关机管理。
- TimeControl 网络时间控制。
- OpenAppFilter 应用过滤。
- htop 系统资源查看。
- iperf3 网络性能测试。
- tcpdump 网络抓包。
- chrony 时间同步。

## 硬件兼容性

本固件采用 x86_64 Generic 通用目标，不针对特定 CPU、主板或网卡型号进行绑定，适用于具备 x86_64 启动能力的常见软路由设备。

### CPU 平台

可用于以下常见 Intel / AMD x86_64 平台：

- Intel Celeron 3215U。
- Intel Celeron J4125。
- Intel Processor N100。
- Intel Celeron / Pentium / Core 系列。
- AMD Ryzen 及其他支持 x86_64 的处理器平台。

以上为平台示例，实际兼容性取决于设备固件、启动方式及硬件驱动支持情况。

### 网卡支持

常见网卡及驱动示例：

- **Intel i210 / i211：** 常见驱动为 igb。
- **Intel i225 / i226：** 常见驱动为 igc。
- **Intel i219 系列：** 常见驱动为 e1000e。
- **Intel 82574 系列：** 常见驱动为 e1000e。
- **Intel 8254x 系列：** 常见驱动为 e1000。
- **Intel 部分 10GbE 网卡：** 常见驱动为 ixgbe。
- **Realtek RTL8111 / RTL8168：** 根据型号使用 r8169 或对应驱动。
- **Realtek RTL8125：** 根据硬件版本及内核支持情况确定驱动。

具体驱动取决于网卡硬件版本、内核版本及固件中的驱动配置。

### 网口与网络环境

- 支持常见 2 网口、4 网口、6 网口及多网口 x86 软路由。
- 支持千兆及 2.5G 网络接口。
- 适用于家庭宽带、千兆宽带及多 WAN 网络环境。
- 可作为主路由或旁路由使用。
- 支持运行 PassWall 等代理服务。

固件包含 x86 网口自动识别及 WAN / LAN 初始化配置逻辑。不同设备的网卡数量和接口命名可能存在差异，首次启动后建议检查实际接口分配。

### 启动与存储

- 支持传统 BIOS（Legacy）启动。
- 支持 UEFI 启动。
- 支持常见 SATA SSD、机械硬盘及 USB 存储设备。
- 支持 SquashFS 固件格式。

### 通用性说明

为了兼容不同 CPU、网卡及主板平台，固件采用相对保守的通用配置：

- 不绑定特定 CPU 型号。
- 不强制指定 CPU 频率或运行策略。
- 不强制修改网卡中断分配。
- 不强制启用软件或硬件流量分载。
- 保留官方内核及常规网卡驱动支持。

不同硬件的性能、功耗和网络表现可能存在差异，建议根据实际设备进行测试和调整。

以上硬件型号仅作为兼容平台参考，并不代表所有型号均已完成实机测试。

## 编译方式

本项目通过 GitHub Actions 自动构建固件。

1. 进入仓库的 Actions 页面。
2. 选择「编译官方 OpenWrt 25.12」工作流。
3. 点击 Run workflow。
4. 选择编译模式：

   - **Stable：** 使用官方 OpenWrt v25.12.6 标签。
   - **Snapshot：** 使用官方 openwrt-25.12 分支最新源码。

5. 启动编译并等待任务完成。
6. 在 Actions Artifacts 或对应 Release 中获取固件。

## 项目文件结构

```text
.
├── .github/
│   └── workflows/
│       └── build.yml
├── .config
├── diy1.sh
├── diy2.sh
├── README.md
└── LICENSE
```

### 文件说明

- **build.yml：** GitHub Actions 自动编译工作流。
- **.config：** OpenWrt 固件基础配置。
- **diy1.sh：** 第三方插件及软件包集成。
- **diy2.sh：** 系统、网络及编译环境相关自定义配置。
- **README.md：** 项目说明文档。
- **LICENSE：** GPL-3.0 许可证。

## 源码与 Feeds

- OpenWrt 使用官方源码仓库。
- 源码分支为 openwrt-25.12。
- Stable 模式使用固定版本标签 v25.12.6。
- Snapshot 模式使用 openwrt-25.12 分支最新源码。
- 使用 OpenWrt 官方源码内置的 `feeds.conf.default`。
- 第三方插件由 DIY 脚本集成。

## 注意事项

1. 本项目面向 x86_64 Generic 设备，不保证适用于所有硬件平台。
2. 不同设备的网卡数量、网卡驱动及接口命名可能不同，首次使用建议检查 WAN / LAN 接口分配。
3. 首次刷写前请确认启动方式与设备 BIOS / UEFI 设置匹配。
4. 固件默认 LAN 地址为 `192.168.5.1`，请确保本地网络没有地址冲突。
5. Stable 模式固定 OpenWrt 源码版本，但第三方插件使用上游仓库代码，插件更新可能影响构建结果。
6. OpenAppFilter 内核模块需要结合当前 OpenWrt 内核版本进行编译兼容性验证。
7. 第三方插件是否最终进入固件，以实际编译结果及固件内容为准。
8. 首次刷写前请备份原有系统配置及重要数据。

## 许可证

本项目原创的编译配置、DIY 脚本、GitHub Actions 工作流及相关说明，除另有声明外，采用 GNU General Public License v3.0（GPL-3.0）授权。

本项目基于 OpenWrt 官方源码构建，并集成第三方软件包及插件。

OpenWrt 官方源码、第三方软件包、插件及其他外部组件均保留其各自原有的版权声明和许可证，不因本项目的许可证声明而改变。

使用、修改或再分发本项目及其构建产物时，请遵守相关组件各自适用的许可证及其附带义务。

GPL-3.0 完整许可证文本见仓库根目录 `LICENSE` 文件。

## 免责声明

本项目仅供个人学习、测试及技术交流使用。

刷写固件前请自行备份原有配置和数据。因刷写、配置或使用本固件造成的数据丢失、设备故障及其他损失，由使用者自行承担。
