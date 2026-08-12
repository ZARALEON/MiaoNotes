# Changelog / 更新日志

MiaoNotes follows semantic versioning for tagged Windows prereleases.
MiaoNotes 的 Windows 标签预发布版本遵循语义化版本。

## 0.2.0 - 2026-08-13

### English

- Added verified Portable Import v1 with manifest revalidation, empty-Vault
  safety checks, atomic SQLite restore, Revision DAG reconstruction, and durable
  sync outbox recovery.
- Added on-demand local FTS5 search across note titles and bodies.
- Added Recycle Bin v1 with synchronized tombstone revisions and safe restore.
- Added inline tags, exact tag filtering, and tag/search intersection.
- Added local-only note pinning and newest, oldest, or title sidebar ordering.
- Added manually dispatched `core-ci` Windows snapshots.
- Upgraded workflow artifact uploads to the Node.js 24-compatible
  `actions/upload-artifact@v7`.
- Added complete English and Simplified Chinese project documentation.

Known limitations: this remains an unsigned Windows Alpha prerelease. Pin and
sort preferences are local to each device. Attachments, MiaoDoc rich text,
automatic updates, and non-Windows clients are not included.

### 简体中文

- 新增经过清单复验、空 Vault 安全检查和 SQLite 原子事务保护的 Portable
  Import v1，可重建 Revision DAG 与持久化同步发件箱。
- 新增针对便签标题和正文的按需本地 FTS5 搜索。
- 新增回收站 v1，通过可同步 tombstone Revision 安全删除与恢复便签。
- 新增行内标签、精确标签筛选，以及标签与搜索的组合查询。
- 新增仅限当前设备的便签置顶，以及最近、最早或标题排序。
- 新增可手动触发的 `core-ci` Windows 快照构建。
- 将工作流 Artifact 上传升级至兼容 Node.js 24 的
  `actions/upload-artifact@v7`。
- 补齐英文与简体中文项目文档。

已知限制：这仍是未签名的 Windows Alpha 预发布版本。置顶和排序偏好仅保存在
当前设备。附件、MiaoDoc 富文本、自动更新和非 Windows 客户端尚未包含。

## 0.1.0 - 2026-08-10

Initial Windows Alpha baseline with the local-first editor, SQLite Schema v1,
Sync Protocol v1, R2/S3 storage, E2E Crypto v1, conflict resolution, Portable
Export v1, cloud builds, and tag-based GitHub Releases.

首个 Windows Alpha 基线，包含本地优先编辑器、SQLite Schema v1、Sync
Protocol v1、R2/S3 存储、E2E Crypto v1、冲突处理、Portable Export v1、
云端构建与基于标签的 GitHub Release。
