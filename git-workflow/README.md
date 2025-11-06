# Git Workflow Skill for Claude Code

这是一个用于 Claude Code 的自定义 Skill，帮助管理跨电脑的 Git 工作流程。

## 功能特点

- 🚀 自动化 Git 提交和推送流程
- 🔄 智能的跨电脑代码同步
- 📝 中英文双语支持
- 🛠️ 包含常见问题解决方案
- 📜 多种语言的 .gitignore 模板

## 使用场景

- 下班前保存工作并推送到 GitHub
- 上班后拉取最新代码
- 在新电脑上克隆项目
- 设置新的 Git 仓库
- 解决常见的 Git 问题

## 安装方法

### 个人使用（推荐）

将此 skill 复制到你的个人 skills 目录：

**Windows:**
```powershell
# 克隆仓库
git clone https://github.com/Nevery-qiao/git-workflow.git

# 复制到个人 skills 目录
cp -r git-workflow ~/.claude/skills/
```

**Mac/Linux:**
```bash
# 克隆仓库
git clone https://github.com/Nevery-qiao/git-workflow.git

# 复制到个人 skills 目录
cp -r git-workflow ~/.claude/skills/
```

### 项目级使用

将此 skill 放在项目的 `.claude/skills/` 目录下，与团队共享：

```bash
cd your-project
git clone https://github.com/Nevery-qiao/git-workflow.git .claude/skills/git-workflow
git add .claude/skills/git-workflow
git commit -m "添加 git-workflow skill"
git push
```

## 触发词示例

在 Claude Code 中，说出以下任何一句话即可触发此 skill：

- "帮我推送代码到 GitHub"
- "我要下班了，保存今天的工作"
- "拉取最新代码"
- "同步代码"
- "创建新的 GitHub 仓库"

## Skill 内容

```
git-workflow/
├── SKILL.md                          # 核心工作流指导
├── scripts/
│   ├── git_sync.sh                   # Bash 自动同步脚本
│   └── git_sync.ps1                  # PowerShell 自动同步脚本
└── references/
    ├── troubleshooting.md            # 常见问题解决方案
    └── gitignore_templates.md        # .gitignore 模板集合
```

## 自动化脚本使用

### 单项目同步

**Bash (Mac/Linux)**

```bash
# 基本用法
./git-workflow/scripts/git_sync.sh

# 自定义提交消息
./git-workflow/scripts/git_sync.sh "完成了新功能开发"
```

**PowerShell (Windows)**

```powershell
# 基本用法
.\git-workflow\scripts\git_sync.ps1

# 自定义提交消息
.\git-workflow\scripts\git_sync.ps1 -CommitMessage "完成了新功能开发"
```

### 批量同步所有项目 ⭐ 新功能

如果你有多个项目（如 project-a, project-b, project-c 等），可以一次性同步所有项目！

**第一次使用前需要配置：**

1. 编辑脚本文件，添加你的项目路径：
   - Windows: 编辑 `scripts/sync_all_projects.ps1`
   - Mac/Linux: 编辑 `scripts/sync_all_projects.sh`

2. 找到项目路径配置部分，修改为你的实际路径：

```powershell
# Windows PowerShell 配置示例
$Projects = @(
    "$HOME\work\liuren-divination",
    "$HOME\work\my-app",
    "$HOME\personal\blog"
)
```

```bash
# Mac/Linux Bash 配置示例
PROJECTS=(
    "$HOME/work/liuren-divination"
    "$HOME/work/my-app"
    "$HOME/personal/blog"
)
```

**使用方法：**

**Windows:**
```powershell
# 一键同步所有项目
.\git-workflow\scripts\sync_all_projects.ps1

# 预览模式（不实际执行，只显示会做什么）
.\git-workflow\scripts\sync_all_projects.ps1 -DryRun
```

**Mac/Linux:**
```bash
# 一键同步所有项目
./git-workflow/scripts/sync_all_projects.sh
```

**功能特点：**
- 自动遍历所有配置的项目
- 只同步有改动的项目
- 显示详细的同步进度
- 最后显示成功/失败/跳过的统计

## 支持的工作流

1. **Leaving Work** - 下班前保存并推送
2. **Starting Work** - 上班后拉取最新代码
3. **Quick Sync** - 快速双向同步
4. **New Repository** - 创建并连接新仓库
5. **Clone Repository** - 克隆现有仓库
6. **Batch Sync All** - 批量同步所有项目 ⭐

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 作者

Created for cross-computer development workflow
