# Claude Code Skills 集合

这是我的 Claude Code 自定义 Skills 集合，包含多个实用的 AI 助手技能扩展。

## 📦 包含的 Skills

### 1. Git Workflow - 智能 Git 工作流管理 ⭐

跨电脑 Git 项目同步神器，支持自动发现项目、批量同步、智能配置。

**主要功能：**
- 🔍 自动搜索本地所有 Git 项目
- 📊 智能分类：活跃/休眠/废弃项目
- 🎯 交互式项目选择
- 🚀 一键批量同步多个项目
- 💾 配置持久化，一次配置永久使用

**适用场景：**
- 在公司和家里使用不同电脑开发
- 管理多个 Git 项目
- 需要跨设备同步代码

**快速开始：**
```bash
# 安装 skill
cp -r skills/git-workflow ~/.claude/skills/

# 重启 Claude Code 后使用
# 对 Claude 说："配置批量同步"
```

[📖 详细文档](./skills/git-workflow/README.md) | [🎨 设计文档](./skills/git-workflow/DESIGN.md)

---

### 2. 六壬神课占卜工具

基于 Python 的六壬神课占卜程序，可用于扣子插件。

**主要功能：**
- 支持自定义日期时间占卜
- 自动获取宫位信息
- 多种时间格式输入

**快速开始：**
```bash
cd skills/liuren-divination
pip install selenium beautifulsoup4 webdriver-manager
python divination.py
```

[📖 详细文档](./skills/liuren-divination/README.md)

---

## 🚀 如何使用

### 安装单个 Skill

```bash
# 方法 1：复制到个人 skills 目录
cp -r skills/<skill-name> ~/.claude/skills/

# 方法 2：复制到项目 skills 目录（团队共享）
cp -r skills/<skill-name> .claude/skills/
```

### 在 Claude Code 中使用

安装后重启 Claude Code，Skills 会自动加载。触发方式：
- 说出 Skill 相关的关键词
- Claude 会自动识别并使用对应的 Skill

---

## 📖 关于 Claude Code Skills

Skills 是 Claude Code 的扩展机制，可以：
- 提供专业领域知识
- 集成工具和脚本
- 定义工作流程
- 捆绑参考资料

[了解更多关于 Skills](https://docs.claude.com/en/docs/claude-code/skills)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

如果你创建了新的 Skill，欢迎通过 PR 添加到这个集合中。

---

## 📊 统计

![Shell](https://img.shields.io/badge/Shell-70.7%25-green)
![Python](https://img.shields.io/badge/Python-17.8%25-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-11.5%25-darkblue)

---

## 📄 许可证

MIT License

---

## 🌟 Star History

如果觉得这些 Skills 有用，欢迎 Star ⭐️

---

## 作者

Created by [Nevery-qiao](https://github.com/Nevery-qiao)

**Happy Coding with Claude Code! 🚀**
