# 基于官方OpenWrt 25.12 编译

本项目基于 OpenWrt 官方 `openwrt-25.12` 分支构建，采用 GitHub Actions 自动化编译，支持 Stable / Snapshot 双模式切换，并集成多项针对 x86_64 软路由场景的优化与增强补丁。

---

## 🚀 固件核心特性

### 📦 双模式构建系统

- Stable 模式：基于 OpenWrt 官方 Tag（默认 v25.12.5）
- Snapshot 模式：基于 openwrt-25.12 滚动分支

---

### ⚙️ x86_64 专属优化

- 适配 `x86_64 / generic` 设备目标
- GRUB EFI / BIOS 双引导支持
- SquashFS + GZIP 压缩镜像
- Kernel / Rootfs 分区优化（32M / 512M）

---

### 🧠 网络性能优化

- 启用 TCP BBR 拥塞控制
- TCP FastOpen 支持
- nftables + firewall4 全栈防火墙体系
- 硬件 NAT / offload 支持（kmod-nft-offload）

---

### 🌐 网络功能增强

- IPv6（odhcp6c + dnsmasq full）
- 多 WAN / 负载均衡（mwan3 兼容）
- TUN 支持（VPN / 代理基础能力）
- UPnP 支持（按插件配置启用）

---

### 💾 存储与 NAS 能力

- block-mount 自动挂载
- ext4 / exFAT / NTFS3 文件系统支持
- USB 3.0 / UAS 加速支持
- Samba4 文件共享
- hd-idle 硬盘休眠支持
- DiskMan 磁盘管理工具

---

### 🖥 LuCI 与界面

- LuCI 完整中文支持（zh-Hans）
- luci-mod-admin-full + status 完整后台
- Argon 主题 + Argon Config
- LuCI HTTPS（uhttpd + ssl）

---

## 📦 内置插件

### 📡 代理 / 网络工具

- luci-app-passwall（科学上网管理）
- luci-app-lucky（网络增强工具）
- luci-app-ghfu（GitHub 更新辅助工具）

---

### 🧩 应用过滤 / 网络控制

- luci-app-oaf（OpenAppFilter 应用过滤）

---

### 💽 存储 / 文件管理

- luci-app-diskman（磁盘管理）
- luci-app-samba4（文件共享）

---

### ⚙️ 系统工具

- luci-app-cpufreq（CPU 频率调节）
- luci-app-ttyd（Web Shell）
- luci-app-poweroffdevice（安全关机）
- luci-app-timecontrol（时间控制）

---

### 🎨 主题系统

- luci-theme-argon
- luci-app-argon-config

---

## 🔧 本固件特性

集成：

- Argon Theme
- PassWall（核心代理组件）
- Lucky
- GHFU
- OpenAppFilter（OAF）
- DiskMan
- PowerOffDevice

---


- 默认 LAN IP：`192.168.5.1`
- 自动识别网卡并分配 WAN / LAN
- 默认时区：Asia/Shanghai
- x86 网络结构自动适配

---

## 🧠 内核与系统优化

- TCP BBR 启用
- TCP FastOpen 支持
- nftables / firewall4 现代防火墙体系
- DMI / sysfs 修复（优化 N100 等设备识别）
- kmod tun / netfilter 增强

---

## 🖥 适用设备

- Intel N100 / N5105 / J4125 / x86 软路由
- VMware / Proxmox 虚拟机
- 家庭网关 / 多拨环境
- NAS + 路由一体设备

---

## 📜 免责声明

本固件仅用于学习、测试与个人网络环境使用，不保证适用于生产环境，使用风险需自行承担。

---

## 🙏 致谢

- OpenWrt Project
- ImmortalWrt 社区
- PassWall / OAF / Lucky 等开源项目作者
- GitHub Actions 开源生态
