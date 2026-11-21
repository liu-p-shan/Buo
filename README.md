# Buo · 安全陪伴笔记

> **你的笔记，只属于你。** 双空间加密 · 指纹秒开 · 完全离线

![version](https://img.shields.io/badge/version-v1.0.4-3D7FFF)
![platform](https://img.shields.io/badge/platform-Android-30A46C)
![offline](https://img.shields.io/badge/network-完全离线-FFA640)

Buo 是一款为「不想被人翻到手机笔记」设计的安卓应用：

- 🔐 **双空间保护** —— 设置两个密码：常用密码进真实笔记，伪装密码进一个一模一样的普通笔记空间。不得不交出密码时，真实笔记安然无恙。
- 👆 **指纹秒开** —— 验证指纹直达真实空间，切后台立刻自动上锁。
- 🛡️ **全程加密** —— SQLCipher 本地加密数据库，PIN 摘要用 PBKDF2-HMAC-SHA256（30 万次迭代），数据不出设备。
- 🚫 **完全离线** —— 不申请联网权限，没有服务器，没有账号，没人能远程看到你的任何东西。
- 🖼️ **防偷窥** —— 防截屏、防任务列表预览，锁定时自动关闭加密库。

## 📥 下载安装（最新版 v1.0.4）

1. 点开本仓库的 **[Releases](https://github.com/liu-p-shan/Buo/releases/latest)** 页面
2. 下载 `Buo-v1.0.4.apk`（认准 .apk，不要去 Actions 里下 zip，那个要解压）
3. 在手机上点开安装；如提示风险，允许「安装未知来源应用」后继续
4. 第一次打开，按引导设置**两个密码**并牢记 —— 密码无法找回，这是故意的

> v1.0.4 修复了第一次设置密码时「初始化失败、请找开发者」的问题（打包配置未生效 + 存储/数据库自愈兜底），并美化了设置流程界面。

## 🚀 第一次使用

1. 点「开始使用」
2. 设置**常用密码**（4–8 位数字，日常解锁用）并确认
3. 设置**伪装密码**（不能与常用密码相同）并确认
4. 等待几秒生成加密密钥，自动进入首页，开始写笔记

## 🧱 技术与构建

- Flutter + flutter_miuix（HyperOS 风格组件）
- sqflite_sqlcipher / flutter_secure_storage / local_auth
- 本仓库不含 android 平台目录，由 GitHub Actions 在打包时用 `flutter create` 生成并应用 `patches/` 下的平台补丁，随后自动发布 Release

## 📮 反馈

遇到问题请加 QQ：**2731379078**（李明），备注 Buo。
