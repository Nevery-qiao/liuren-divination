---
name: git-workflow
description: Helps manage cross-computer Git workflows between multiple development environments (e.g., work and home computers). Use this skill when the user needs to sync code with GitHub, push changes before leaving, pull updates before starting work, or set up a new project repository. Keywords that trigger this skill include "push", "pull", "sync", "下班" (leaving work), "上班" (starting work), "commit", "GitHub同步" (GitHub sync).
---

# Git Workflow Manager

## Overview

This skill provides guided workflows for managing Git repositories across multiple computers, ensuring seamless code synchronization through GitHub. It automates common Git operations and prevents sync conflicts.

## Core Workflows

### Workflow 1: Leaving Work (Before Switching Computers)

**When to use**: User is about to leave current computer (going home from work, or vice versa)

**Triggers**: "下班了", "帮我保存工作", "我要走了", "push代码", "同步到GitHub"

**Steps**:

1. Check repository status
   ```bash
   git status
   ```

2. Review changes and confirm with user
   - Show modified files
   - Show untracked files
   - Ask user which files to commit (if needed)

3. Stage and commit changes
   ```bash
   git add .
   git commit -m "[descriptive message based on changes]"
   ```
   - Commit message should be descriptive and in Chinese or English based on user preference
   - Include summary of what was changed

4. Push to remote
   ```bash
   git push
   ```

5. Confirm success and show commit hash

### Workflow 2: Starting Work (After Switching Computers)

**When to use**: User just arrived at a different computer and wants latest code

**Triggers**: "拉取代码", "pull最新代码", "更新代码", "同步代码", "开始工作"

**Steps**:

1. Check current repository status
   ```bash
   git status
   ```

2. If there are uncommitted changes, warn user and ask how to proceed:
   - Stash changes: `git stash`
   - Commit changes first
   - Discard changes (if confirmed)

3. Pull latest changes
   ```bash
   git pull
   ```

4. If stashed, ask whether to restore: `git stash pop`

5. Show what changed in the pull

### Workflow 3: Quick Sync (Commit + Push + Pull)

**When to use**: User wants to do a complete sync operation

**Triggers**: "同步", "sync", "快速同步"

**Steps**:

1. Execute Workflow 1 (Leaving Work)
2. After successful push, confirm with user if they also want to pull
3. If confirmed, execute Workflow 2 (Starting Work)

### Workflow 4: Setting Up New Repository

**When to use**: User has a new project and wants to connect it to GitHub

**Triggers**: "创建新仓库", "连接GitHub", "第一次推送", "新项目上传"

**Steps**:

1. Check if Git is initialized
   ```bash
   git status
   ```
   - If not, run: `git init`

2. Check if .gitignore exists
   - If not, ask user about project type and create appropriate .gitignore
   - Use `references/gitignore_templates.md` for common templates

3. Initial commit
   ```bash
   git add .
   git commit -m "Initial commit"
   ```

4. Guide user to create GitHub repository:
   - Provide instructions for creating repo on github.com
   - Wait for user to provide repository URL

5. Connect to remote and push
   ```bash
   git remote add origin [user-provided-url]
   git branch -M main
   git push -u origin main
   ```

### Workflow 5: Cloning Existing Repository

**When to use**: User wants to clone a repository on a new computer

**Triggers**: "克隆仓库", "下载项目", "clone", "在新电脑上开始工作"

**Steps**:

1. Ask for repository URL if not provided

2. Clone repository
   ```bash
   git clone [url]
   ```

3. Verify clone success
   ```bash
   cd [repo-name]
   git status
   git log --oneline -5
   ```

4. Confirm with user that setup is complete

### Workflow 6: Batch Sync All Projects

**When to use**: User has multiple projects and wants to sync all of them at once

**Triggers**: "同步所有项目", "批量同步", "sync all projects", "一键同步所有仓库"

**Important**: This workflow requires user to configure project paths in the batch sync script first.

**Steps**:

1. Check if batch sync script is configured
   - Ask user for all project paths if not configured
   - Help edit the script to add project paths

2. Execute batch sync script:
   - **Windows**: Run `scripts/sync_all_projects.ps1`
   - **Mac/Linux**: Run `scripts/sync_all_projects.sh`

3. The script will automatically:
   - Iterate through all configured projects
   - Check each project for changes
   - Commit and push changes if found
   - Skip projects with no changes
   - Report success/failure/skip counts

4. Show summary to user

**Preview mode**: User can run with `-DryRun` (PowerShell) to see what would be done without actual execution.

**Note**: This is useful for end-of-day syncing when user has worked on multiple projects. Each project is synced to its own remote repository automatically.

## Best Practices

When using this skill, always:

1. **Check status first**: Always run `git status` before any operation
2. **Descriptive commits**: Generate meaningful commit messages based on actual changes
3. **User confirmation**: Confirm before destructive operations (force push, discarding changes)
4. **Show results**: Display operation results and confirm success
5. **Handle errors gracefully**: If Git commands fail, explain the error and suggest solutions

## Common Issues and Solutions

Reference `references/troubleshooting.md` for detailed solutions to:
- Merge conflicts
- Authentication issues
- Diverged branches
- Large files / storage issues

## Scripts

### scripts/git_sync.sh / git_sync.ps1

Single-project automated sync script. Execute when user wants a fully automated sync without step-by-step confirmation for the current project.

### scripts/sync_all_projects.sh / sync_all_projects.ps1

Multi-project batch sync script. Syncs all configured projects at once. User needs to edit the script to add their project paths before first use.

**Configuration example (PowerShell)**:
```powershell
$Projects = @(
    "$HOME\work\project-a",
    "$HOME\work\project-b",
    "$HOME\personal\my-app"
)
```

**Configuration example (Bash)**:
```bash
PROJECTS=(
    "$HOME/work/project-a"
    "$HOME/work/project-b"
    "$HOME/personal/my-app"
)
```

## Cross-Platform Notes

- **Windows**: Use PowerShell or Git Bash
- **Mac/Linux**: Use Terminal
- Git commands are identical across platforms
- Path formats may differ (Windows: `\`, Mac/Linux: `/`)
