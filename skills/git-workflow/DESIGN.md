# Git Workflow Skill - 智能批量同步功能设计文档

## 📋 目录

1. [项目概述](#项目概述)
2. [核心目标](#核心目标)
3. [功能特性](#功能特性)
4. [用户交互流程](#用户交互流程)
5. [技术架构](#技术架构)
6. [数据结构设计](#数据结构设计)
7. [文件结构](#文件结构)
8. [边界情况处理](#边界情况处理)
9. [实现计划](#实现计划)
10. [测试策略](#测试策略)

---

## 项目概述

### 问题陈述

现有的批量同步功能需要用户手动编辑脚本配置项目路径，对新手不友好。需要一个**零配置、交互式的智能配置向导**，让用户通过简单对话即可完成批量同步的设置。

### 解决方案

创建一个智能配置向导系统，能够：
- 自动搜索本地所有 Git 项目
- 检查远程仓库配置状态
- 引导用户完成 GitHub 账号配置
- 帮助创建缺失的远程仓库
- 保存配置供后续使用

---

## 核心目标

### 主要目标

1. **零门槛配置**：小白用户无需编辑任何文件
2. **智能识别**：自动发现并分类本地 Git 项目
3. **交互友好**：数字选择 + 清晰提示
4. **健壮性强**：处理各种边界情况（无账号、无远程等）
5. **可维护性**：配置可查看、修改、增量更新

### 非目标

- ❌ 不支持 GitLab/Bitbucket（首期仅 GitHub）
- ❌ 不处理复杂的合并冲突（仅推送拉取）
- ❌ 不提供 Git 教学功能（假设基本了解）

---

## 功能特性

### F1: 智能项目发现

**优先级**: P0（核心功能）

**功能描述**:
- 在指定路径下递归搜索所有包含 `.git` 目录的文件夹
- 排除常见的非项目路径（node_modules、.Trash 等）
- 提取项目元数据：最后提交时间、未提交改动、远程仓库等
- 按活跃度分类展示

**用户价值**:
用户无需记住所有项目路径，系统自动发现。

### F2: 远程仓库状态检查

**优先级**: P0（核心功能）

**功能描述**:
- 检查每个项目是否配置了 `origin` 远程仓库
- 验证远程仓库是否可访问
- 检测推送权限
- 区分已配置 vs 未配置项目

**用户价值**:
避免配置后才发现无法推送，提前暴露问题。

### F3: GitHub 账号配置引导

**优先级**: P0（核心功能）

**功能描述**:
- 检测 Git 全局配置（user.name, user.email）
- 引导注册 GitHub 账号（如果没有）
- 配置认证方式（Token 或 SSH）
- 验证认证是否生效

**用户价值**:
新手用户也能从零开始完成配置。

### F4: 远程仓库创建助手

**优先级**: P1（重要功能）

**功能描述**:
- 使用 GitHub CLI (`gh`) 创建远程仓库
- 自动连接本地与远程
- 执行首次推送
- 支持选择 Public/Private

**用户价值**:
无需离开终端即可创建仓库。

### F5: 配置持久化

**优先级**: P0（核心功能）

**功能描述**:
- 将配置保存为 JSON 文件
- 记录项目路径、远程仓库、配置时间等
- 支持增量更新配置
- 支持查看和编辑已有配置

**用户价值**:
配置一次，永久使用。

### F6: 增量配置管理

**优先级**: P2（次要功能）

**功能描述**:
- 添加新项目到现有配置
- 从配置中移除项目
- 启用/禁用项目
- 重新扫描项目

**用户价值**:
灵活管理项目列表。

---

## 用户交互流程

### 流程 1: 首次配置（完整流程）

```
用户: "批量同步"
  ↓
系统: 检查配置文件
  → 未找到 → 启动配置向导
  ↓
系统: "请选择搜索路径"
  选项: [1] ~/work 和 ~/projects [2] 整个 ~/ [3] 自定义
  ↓
用户: 输入 "1"
  ↓
系统: 搜索 Git 项目...
  → 发现 8 个项目
  → 分类展示（活跃、不活跃、疑似依赖）
  ↓
系统: "请选择需要同步的项目"
  选项: 输入数字/all/active
  ↓
用户: 输入 "active"（或 "1,2,3,4"）
  ↓
系统: "你选择了 4 个项目，是否确认？"
  选项: y/n/edit
  ↓
用户: 输入 "y"
  ↓
系统: 检查远程仓库状态
  → 2 个已配置远程 ✓
  → 2 个未配置远程 ⚠️
  ↓
系统: "如何处理未配置远程的项目？"
  选项: [1] 创建远程仓库 [2] 暂时跳过 [3] 取消
  ↓
用户: 输入 "1"
  ↓
系统: "是否已有 GitHub 账号？"
  ↓
用户: 输入 "y"
  ↓
系统: "选择认证方式"
  选项: [1] Token [2] SSH [3] 稍后配置
  ↓
用户: 输入 "1"
  ↓
系统: 显示 Token 创建指引
  → 等待用户粘贴 Token
  ↓
用户: 粘贴 Token
  ↓
系统: 保存 Token 凭据
  ↓
系统: 逐个创建远程仓库
  → "为 company-project 创建仓库？"
  ↓
用户: 确认参数（仓库名、可见性）
  ↓
系统: 执行 `gh repo create ...`
  → 创建成功 ✓
  → 重复直到所有项目完成
  ↓
系统: "配置完成！现在要立即同步吗？"
  ↓
用户: 输入 "y"
  ↓
系统: 执行批量同步
  → 显示进度和结果
```

### 流程 2: 已配置用户（快速流程）

```
用户: "批量同步"
  ↓
系统: 检查配置文件
  → 找到配置（4 个项目）
  ↓
系统: 执行批量同步
  → [1/4] project-a ✓ 推送成功
  → [2/4] project-b ○ 无改动，跳过
  → [3/4] project-c ✓ 推送成功
  → [4/4] project-d ○ 无改动，跳过
  ↓
系统: 显示统计结果
  → 成功: 2, 跳过: 2, 失败: 0
```

### 流程 3: 增量添加项目

```
用户: "添加项目到批量同步"
  ↓
系统: 读取现有配置
  → 当前已配置 4 个项目
  ↓
系统: 重新扫描 Git 项目
  → 发现 2 个新项目（未在配置中）
  ↓
系统: "发现以下新项目"
  → [1] new-project-1
  → [2] new-project-2
  ↓
系统: "选择要添加的项目"
  ↓
用户: 输入 "1"
  ↓
系统: 检查远程仓库状态
  → 已有远程 ✓
  ↓
系统: 添加到配置并保存
  → "已添加 new-project-1，现在共 5 个项目"
```

---

## 技术架构

### 整体架构

```
┌─────────────────────────────────────────┐
│         Claude Code Skill (SKILL.md)    │
│  - 触发词识别                            │
│  - 流程控制                              │
│  - 用户交互                              │
└─────────────┬───────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────┐
│      配置向导脚本 (configure_wizard.sh)  │
│  - 主流程编排                            │
│  - 用户输入处理                          │
│  - 调用各个子模块                        │
└───┬─────────────────────────────────────┘
    │
    ├──→ [项目搜索模块] find_projects.sh
    │      - 递归搜索 .git 目录
    │      - 提取项目元数据
    │      - 分类和排序
    │
    ├──→ [远程检查模块] check_remotes.sh
    │      - 检测 origin 配置
    │      - 验证远程连接
    │      - 测试推送权限
    │
    ├──→ [账号配置模块] setup_github.sh
    │      - 检测 Git 配置
    │      - Token/SSH 配置
    │      - 凭据验证
    │
    ├──→ [仓库创建模块] create_repos.sh
    │      - GitHub CLI 调用
    │      - 本地远程连接
    │      - 首次推送
    │
    └──→ [配置管理模块] config_manager.sh
           - 读取/写入 JSON
           - 配置验证
           - 配置迁移
```

### 技术选型

| 组件 | 技术 | 原因 |
|------|------|------|
| 配置存储 | JSON | 易读易写，跨平台 |
| 脚本语言 | Bash + PowerShell | 原生支持，无需额外依赖 |
| GitHub 操作 | GitHub CLI (`gh`) | 官方工具，功能完整 |
| 交互界面 | 命令行菜单 | 简单直观，符合场景 |
| 日志记录 | 文本文件 | 便于调试 |

---

## 数据结构设计

### 配置文件格式

**文件路径**: `~/.claude/skills/git-workflow/projects.json`

```json
{
  "version": "1.0.0",
  "configuredAt": "2025-11-06T13:30:00Z",
  "lastSync": "2025-11-06T18:00:00Z",

  "user": {
    "githubUsername": "Nevery-qiao",
    "gitName": "Nevery Qiao",
    "gitEmail": "qiaoyang80238023@gmail.com",
    "authMethod": "token",
    "hasToken": true,
    "hasSSH": false
  },

  "searchPaths": [
    "~/work",
    "~/projects"
  ],

  "projects": [
    {
      "id": "liuren-divination",
      "name": "liuren-divination",
      "path": "/Users/username/work/liuren-divination",
      "hasRemote": true,
      "remoteUrl": "https://github.com/Nevery-qiao/liuren-divination.git",
      "remoteName": "origin",
      "branch": "main",
      "status": "active",
      "addedAt": "2025-11-06T13:30:00Z",
      "lastSync": "2025-11-06T18:00:00Z",
      "syncCount": 15,
      "enabled": true
    },
    {
      "id": "company-project",
      "name": "company-project",
      "path": "/Users/username/work/company-project",
      "hasRemote": false,
      "remoteUrl": null,
      "remoteName": null,
      "branch": "main",
      "status": "skipped",
      "skipReason": "no_remote",
      "addedAt": "2025-11-06T13:30:00Z",
      "lastSync": null,
      "syncCount": 0,
      "enabled": false
    }
  ],

  "settings": {
    "autoCommitMessage": "Auto sync: {date} from {hostname}",
    "skipNoChanges": true,
    "showProgress": true,
    "parallelSync": false
  },

  "stats": {
    "totalSyncs": 42,
    "successfulSyncs": 40,
    "failedSyncs": 2,
    "lastError": null
  }
}
```

### 项目元数据结构

**临时数据（搜索时使用）**:

```json
{
  "path": "/Users/username/work/project-a",
  "name": "project-a",
  "hasGit": true,
  "hasRemote": true,
  "remoteUrl": "github.com/user/project-a",
  "lastCommit": {
    "hash": "abc123",
    "date": "2025-11-05T14:20:00Z",
    "message": "Fix bug"
  },
  "uncommittedChanges": true,
  "changedFiles": 3,
  "branch": "main",
  "category": "active",
  "size": 1024000,
  "suspiciousReasons": []
}
```

### 项目分类规则

| 分类 | 条件 | 展示 |
|------|------|------|
| **活跃项目** | 最后提交 < 1 个月 | ✓ 推荐添加 |
| **不活跃项目** | 最后提交 > 1 个月 && < 6 个月 | ⚠️ 可选 |
| **可能废弃** | 最后提交 > 6 个月 | ⚠️ 不推荐 |
| **疑似依赖** | 路径包含 node_modules/.git 等 | ⚠️ 建议排除 |

---

## 文件结构

```
git-workflow/
├── SKILL.md                        # Skill 主文件
├── DESIGN.md                       # 本设计文档
├── README.md                       # 用户文档
│
├── scripts/
│   ├── configure_wizard.sh         # 配置向导主脚本
│   ├── configure_wizard.ps1        # Windows 版本
│   │
│   ├── modules/
│   │   ├── find_projects.sh        # 项目搜索模块
│   │   ├── check_remotes.sh        # 远程检查模块
│   │   ├── setup_github.sh         # GitHub 配置模块
│   │   ├── create_repos.sh         # 仓库创建模块
│   │   └── config_manager.sh       # 配置管理模块
│   │
│   ├── sync_all_projects.sh        # 批量同步脚本（已有）
│   ├── sync_all_projects.ps1       # Windows 版本（已有）
│   ├── git_sync.sh                 # 单项目同步（已有）
│   └── git_sync.ps1                # Windows 版本（已有）
│
├── references/
│   ├── troubleshooting.md          # 故障排除（已有）
│   └── gitignore_templates.md      # 模板（已有）
│
├── templates/
│   └── projects.json.template      # 配置文件模板
│
└── tests/
    ├── test_find_projects.sh       # 项目搜索测试
    ├── test_config_manager.sh      # 配置管理测试
    └── mock_data/                  # 测试数据
```

---

## 边界情况处理

### BC1: GitHub CLI 未安装

**场景**: 用户没有安装 `gh` 命令

**处理**:
1. 检测 `which gh` 或 `gh --version`
2. 如果未安装，显示安装指引：
   ```
   ⚠️ 未检测到 GitHub CLI (gh)

   批量创建仓库需要 GitHub CLI，请安装：

   Mac: brew install gh
   Windows: winget install GitHub.cli
   Linux: 见 https://github.com/cli/cli#installation

   或者选择 [2] 暂时跳过，手动创建仓库
   ```
3. 用户安装后重新运行配置

### BC2: 网络问题

**场景**: 无法访问 GitHub

**处理**:
1. 测试连接：`curl -s https://github.com`
2. 如果失败：
   ```
   ⚠️ 无法连接到 GitHub

   可能原因：
   • 网络未连接
   • 需要代理（当前未配置）
   • GitHub 被墙（需要 VPN）

   建议：
   1. 检查网络连接
   2. 配置代理后重试
   3. 或选择 [2] 暂时跳过
   ```

### BC3: 项目路径不存在

**场景**: 配置文件中的项目路径已被删除

**处理**:
1. 每次同步前验证路径
2. 如果不存在：
   ```
   ⚠️ 项目路径不存在：~/work/old-project

   选项：
   [1] 从配置中移除
   [2] 暂时禁用（保留配置）
   [3] 更新路径（如果移动了位置）
   ```

### BC4: 多个 remote

**场景**: 项目有多个远程仓库（origin, upstream 等）

**处理**:
1. 默认使用 `origin`
2. 如果没有 origin 但有其他 remote：
   ```
   ℹ️ 项目 my-fork 没有 origin，但有 upstream

   选项：
   [1] 将 upstream 重命名为 origin
   [2] 添加新的 origin
   [3] 跳过此项目
   ```

### BC5: 分支不匹配

**场景**: 本地分支是 `master`，远程是 `main`

**处理**:
1. 检测默认分支不一致
2. 提示用户：
   ```
   ⚠️ 分支不匹配

   本地: master
   远程: main

   建议：
   [1] 重命名本地分支: git branch -m master main
   [2] 继续使用 master（可能需要配置远程）
   ```

### BC6: Token 过期

**场景**: 保存的 Token 已过期或失效

**处理**:
1. 推送失败时检测 401/403 错误
2. 提示重新配置：
   ```
   ⚠️ GitHub 认证失败

   你的 Token 可能已过期或被撤销。

   选项：
   [1] 重新配置 Token
   [2] 切换到 SSH
   [3] 跳过此次同步
   ```

### BC7: 大文件或 .gitignore 问题

**场景**: 提交中包含大文件或敏感文件

**处理**:
1. 推送前检查文件大小
2. 如果有 > 50MB 的文件：
   ```
   ⚠️ 发现大文件（可能导致推送失败）

   文件: large-file.zip (150 MB)

   建议：
   [1] 添加到 .gitignore 并移除
   [2] 使用 Git LFS
   [3] 继续推送（可能失败）
   ```

### BC8: 权限不足

**场景**: 用户对远程仓库没有写权限

**处理**:
1. 推送失败时检测权限错误
2. 提示：
   ```
   ⚠️ 推送失败：权限不足

   仓库: github.com/someone/project

   可能原因：
   • 这是别人的仓库
   • 你是只读协作者
   • Token 权限不足

   建议：
   [1] Fork 仓库到你的账号
   [2] 更换为你有权限的仓库
   [3] 从批量同步中移除
   ```

---

## 实现计划

### 里程碑 1: 基础架构 (1-2 小时)

- [ ] 创建文件结构
- [ ] 实现 config_manager.sh（JSON 读写）
- [ ] 实现配置文件模板
- [ ] 基础测试

**输出**: 可以读写配置文件的基础工具

### 里程碑 2: 项目搜索 (2-3 小时)

- [ ] 实现 find_projects.sh
- [ ] 递归搜索 .git 目录
- [ ] 提取项目元数据
- [ ] 项目分类逻辑
- [ ] 格式化输出

**输出**: 能够搜索并展示本地所有 Git 项目

### 里程碑 3: 远程检查 (1-2 小时)

- [ ] 实现 check_remotes.sh
- [ ] 检测 origin 配置
- [ ] 验证远程连接
- [ ] 区分有/无远程项目

**输出**: 能够检查每个项目的远程状态

### 里程碑 4: 配置向导 - 基础流程 (3-4 小时)

- [ ] 实现 configure_wizard.sh 主框架
- [ ] 用户输入处理
- [ ] 项目选择交互
- [ ] 配置保存
- [ ] 基础错误处理

**输出**: 最简单的配置流程可用（跳过 GitHub 配置）

### 里程碑 5: GitHub 配置引导 (3-4 小时)

- [ ] 实现 setup_github.sh
- [ ] 检测 Git 配置
- [ ] Token 配置流程
- [ ] SSH 配置流程
- [ ] 凭据验证

**输出**: 完整的 GitHub 账号配置引导

### 里程碑 6: 仓库创建 (2-3 小时)

- [ ] 实现 create_repos.sh
- [ ] GitHub CLI 集成
- [ ] 仓库创建参数确认
- [ ] 本地远程连接
- [ ] 首次推送

**输出**: 能够为项目创建远程仓库

### 里程碑 7: 集成和优化 (2-3 小时)

- [ ] 更新 SKILL.md 集成新功能
- [ ] 完善错误处理
- [ ] 添加日志记录
- [ ] 优化用户体验（进度条、颜色等）
- [ ] 编写用户文档

**输出**: 完整可用的智能配置系统

### 里程碑 8: 测试和发布 (1-2 小时)

- [ ] 编写测试用例
- [ ] 端到端测试
- [ ] 边界情况测试
- [ ] 文档完善
- [ ] 推送到 GitHub

**输出**: 经过测试的稳定版本

**总计**: 15-23 小时（约 2-3 天工作量）

---

## 测试策略

### 单元测试

| 模块 | 测试用例 |
|------|----------|
| **find_projects** | 1. 搜索包含 Git 项目的目录<br>2. 搜索不包含 Git 项目的目录<br>3. 排除 node_modules 等<br>4. 正确提取元数据 |
| **check_remotes** | 1. 有 origin 的项目<br>2. 无 origin 的项目<br>3. 多个 remote 的项目<br>4. 远程不可访问 |
| **config_manager** | 1. 创建新配置<br>2. 读取现有配置<br>3. 更新配置<br>4. 配置验证<br>5. 处理损坏的 JSON |
| **setup_github** | 1. 已有 Git 配置<br>2. 无 Git 配置<br>3. Token 配置<br>4. SSH 配置<br>5. 凭据验证 |

### 集成测试

| 场景 | 测试步骤 |
|------|----------|
| **首次完整配置** | 1. 无配置文件<br>2. 搜索项目<br>3. 选择项目<br>4. 检查远程<br>5. 配置 GitHub<br>6. 创建仓库<br>7. 保存配置<br>8. 执行同步 |
| **已配置用户** | 1. 有配置文件<br>2. 直接执行同步<br>3. 显示结果 |
| **增量添加** | 1. 有配置文件<br>2. 重新扫描<br>3. 添加新项目<br>4. 更新配置 |

### 边界测试

- [ ] 网络断开
- [ ] GitHub CLI 未安装
- [ ] Token 过期
- [ ] 项目路径不存在
- [ ] 权限不足
- [ ] 配置文件损坏
- [ ] 磁盘空间不足
- [ ] 特殊字符路径

### 性能测试

- [ ] 搜索 100+ 项目的性能
- [ ] 同步 10+ 项目的时间
- [ ] 大文件检测速度

---

## 安全考虑

### S1: Token 存储

**问题**: Token 以明文存储不安全

**解决方案**:
1. 优先使用系统凭据管理器（macOS Keychain, Windows Credential Manager）
2. 如果不可用，在配置文件中只记录 `hasToken: true`，不存储实际 Token
3. 提示用户使用 Git 凭据缓存

### S2: 敏感文件检测

**问题**: 可能提交敏感文件

**解决方案**:
1. 推送前扫描常见敏感文件（.env, credentials.json 等）
2. 如果发现，警告用户并要求确认

### S3: 脚本注入

**问题**: 用户输入可能包含恶意代码

**解决方案**:
1. 所有用户输入都要 sanitize
2. 避免使用 `eval`
3. 使用参数化命令

---

## 开放问题

### Q1: Windows 兼容性

**问题**: PowerShell 脚本需要重写所有逻辑

**选项**:
- A: 完整实现 PowerShell 版本（工作量大）
- B: 只提供 Bash 版本，Windows 用户使用 Git Bash（简单）
- C: 使用 Python 重写，跨平台通用（最佳但需要依赖）

**建议**: 先实现 B，如果有需求再考虑 A 或 C

### Q2: 并行同步

**问题**: 串行同步多个项目较慢

**选项**:
- A: 保持串行（简单，易调试）
- B: 并行同步（快速，但输出混乱）
- C: 可配置（最佳）

**建议**: 先实现 A，后续添加 B

### Q3: 冲突处理

**问题**: Pull 时可能遇到冲突

**选项**:
- A: 遇到冲突立即停止，提示用户手动解决
- B: 尝试自动解决简单冲突
- C: 提供交互式冲突解决

**建议**: 先实现 A（最安全）

---

## 附录

### A: 依赖清单

| 工具 | 用途 | 必需? | 替代方案 |
|------|------|-------|----------|
| `git` | Git 操作 | ✅ 必需 | 无 |
| `gh` | GitHub CLI | ⚠️ 可选 | 手动创建仓库 |
| `jq` | JSON 处理 | ⚠️ 可选 | 纯 Bash 解析 |
| `curl` | 网络测试 | ⚠️ 可选 | `wget` |

### B: 参考资料

- [GitHub CLI 文档](https://cli.github.com/manual/)
- [Git 凭据存储](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
- [Bash 菜单设计模式](https://bash.cyberciti.biz/guide/Menu_driven_scripts)

---

## 文档变更历史

| 版本 | 日期 | 作者 | 变更 |
|------|------|------|------|
| 1.0.0 | 2025-11-06 | Claude | 初始版本 |

---

**文档状态**: 🟡 待审核

**下一步**: 用户确认设计后开始实现里程碑 1
