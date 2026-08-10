# MiaoNotes / 喵喵便签

[English](README.md) | [简体中文](README.zh-CN.md)

> 一款以快速打开、快速记录和安全同步为核心的轻量化、本地优先便签应用。

MiaoNotes 是一款本地优先的轻量化便签应用。目前，Windows Flutter 客户端与纯 Dart 同步核心正在协同开发，同时编辑器始终不依赖网络可用性。

产品体验的优先级不可动摇：

1. 快速打开；
2. 立即接受输入；
3. 将草稿持久化到本地；
4. 在本地完成搜索；
5. 在后台安全同步。

网络访问、S3、加密初始化、维护任务和代码生成均不得进入“启动到编辑器可用”的关键路径。

## 仓库结构

```text
apps/
  windows/                  # 原生 Flutter 外壳、编辑器和本地自动保存
packages/
  miaonotes_core/           # 模型、Drift/SQLite 存储、协议和同步引擎
tools/
  sync_simulator/           # 确定性的多设备故障模拟器
docs/
  adr/                      # 已冻结的架构决策
  protocol/                 # 传输协议和对象布局规格
```

## 开发

工作区需要 Dart 3.10 或更高版本。

```text
dart pub get
cd packages/miaonotes_core
dart run build_runner build
cd ../..
dart format .
dart analyze .
dart test packages/miaonotes_core/test
dart test tools/sync_simulator/test
cd tools/sync_simulator
dart run bin/sync_simulator.dart
```

Windows 应用有意采用独立的依赖解析流程，并需要稳定版 Flutter SDK。原生构建还需要安装 Visual Studio 的“使用 C++ 的桌面开发”工作负载。

```text
cd apps/windows
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

## 云端构建与发布

GitHub Actions 是权威构建环境，因此本地电脑主要用作代码编辑器即可。Pull Request 会验证 Core 和 Windows；每次通过全部检查并推送至 `main` 的提交，也会在对应工作流的 **Artifacts** 区域提供保留七天的 Windows 快照。

维护者发布版本时，应先更新 `apps/windows/pubspec.yaml`，将变更合并进检查通过的 `main`，然后推送对应的 `vMAJOR.MINOR.PATCH` 标签。标签工作流会重新执行全部发布门禁，并创建包含以下文件的 GitHub Release：

- `MiaoNotes-vMAJOR.MINOR.PATCH-windows-x64-portable.zip`；
- 对应的 `.sha256` 校验文件。

启动 MiaoNotes 前请完整解压 ZIP；可执行文件依赖同目录下的 DLL 和 `data` 文件。目前的 `v0.*` 包均为未签名的预发布版本，Windows 可能显示信誉警告。GitHub Actions 中不保存任何 R2 或 Vault 密钥。

SQLite 的唯一事实来源是 `packages/miaonotes_core/schema/schema_v1.sql`。其 Drift 镜像会接受严格的一致性校验，生成的数据库类型也会提交到仓库。产品启动时不会运行代码生成。

## 当前阶段边界

当前已包含：原生 Windows Flutter 外壳、快速本地编辑器/自动保存路径、`miaonotes_core`、SQLite Schema v1、持久化 Drift 仓库、Fake ObjectStore、Cloudflare R2/S3 ObjectStore、Sync Protocol v1、持久化同步协调器以及 Sync Simulator。草稿、修订、事件、DAG 头、逐设备拉取游标、设备序列分配和发件箱记录都能跨进程重启保存。拉取应用和游标推进具有原子性；远端上传具备幂等性，并会在故障或重启后从持久化发件箱继续。

Windows 外壳会在编辑空闲一段时间后创建本地不可变版本。若后台提交期间出现新的输入，新内容会重新基于生成后的 DAG 头。用户可通过便签侧边栏的云按钮配置 R2。远端存储只会在编辑器渲染完成后启动，并且只同步已提交对象；后台轮询以及离线、身份验证、Vault 不匹配和重试状态均不会降低本地编辑的可用性。

侧边栏提供针对便签标题与正文的按需本地全文搜索。查询经过防抖并安全转换为 FTS5 前缀词，也可以使用 `Ctrl+F` 聚焦搜索框。搜索不会执行网络 I/O，也不会进入启动路径。

R2 密钥不会写入源代码、SQLite 或配置文件。Windows 客户端通过纯 Dart FFI 将密钥作为通用凭据保存在当前用户的 Windows 凭据管理器中；不敏感的端点和存储桶设置则使用小型本地 JSON 配置。两者都只会在编辑器首帧之后加载。临时集成工具仍可从进程环境变量读取凭据，在随机 `_miaonotes-temporary-tests/` 前缀下工作，并仅删除其创建的确切对象。

远端 Revision 和 Event 负载现已使用 E2E Crypto v1。随机 Vault 主密钥用于加密逐对象 AES-256-GCM 信封；Argon2id 保护其密码信封，HKDF-SHA256 则隔离恢复密钥与对象密钥。Windows 客户端只在单独的凭据管理器条目中保存解封后的主密钥。密码与一次性恢复密钥永不持久化。加密初始化和解锁仍属于首帧后的后台工作，因此锁定的 Vault 不会延迟本地打开、输入或草稿持久化。

只有在现有远端不包含任何受保护对象时，才允许其缺少加密元数据。旧版明文 Revision/Event 数据会被拒绝，不会与密文静默混合。

连接现有远端 Vault 时受到保护：Vault 不匹配时保持只读，直到用户明确选择导入；仅当本地数据库不包含便签、修订、事件、发件箱条目、游标或冲突时，才允许导入。

Windows 冲突中心现可展示并发的便签正文。用户可以比较所有头版本、选择一个版本、编辑合并后的 Markdown 结果，并保存一条明确的合并 Revision。全部旧有头仍保留在历史中；未提交的本地草稿会得到保护；合并继续使用现有的加密发件箱路径。冲突详情只会在启动后按需加载。

侧边栏的保存图标提供 Portable Export v1。它会先刷新当前草稿，然后把所有便签（包括未提交和已删除便签）、不可变 Revision 历史以及冲突记录导出到 `Documents/MiaoNotes Exports` 下的新目录。每个文件都纳入 SHA-256 清单，并且临时目录只有在完整校验通过后才会正式发布。导出内容刻意采用可读明文，永不包含密码、恢复密钥、Vault 主密钥或 R2 凭据。

经过验证的导入是一项单独且明确的操作：它会重新校验清单中的每个条目，预览数量与 Vault 身份，并且只允许恢复到未配置同步的空本地 Vault。Core 会在单个 SQLite 事务内重建 Revision DAG 和同步发件箱，因此失败或遭篡改的导入不会留下部分数据。

持久化发布门禁覆盖三设备收敛、并发头、上传响应不明确、离线重启恢复、远端对象损坏以及并发删除标记/编辑历史。

Windows 应用在通过本地路径使用 Core 包的同时，维护独立的 Flutter 锁文件。这样即使 Flutter 使用 SDK 固定的分析器依赖，也能保留纯 Dart Core 工具链。

明确排除：Rust Core、Electron、官方后端/账号系统、插件、AI、团队协作，以及任何启动期间同步执行的远端工作。

## 贡献与安全

欢迎贡献。在修改已冻结的架构、协议、加密、持久化或启动边界前，请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。如发现疑似安全漏洞，请按照 [SECURITY.md](SECURITY.md) 中的说明私下报告，不要提交公开 Issue。

## 许可证

MiaoNotes 采用 Mozilla Public License 2.0（`MPL-2.0`）授权。完整条款请参阅 [LICENSE](LICENSE)。
