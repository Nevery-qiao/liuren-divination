# Git 工作流常见问题解决方案

## 1. 合并冲突 (Merge Conflicts)

### 场景
当在不同电脑上修改了同一文件的同一部分时，pull 会产生冲突。

### 症状
```
CONFLICT (content): Merge conflict in file.txt
Automatic merge failed; fix conflicts and then commit the result.
```

### 解决方案

1. 查看冲突文件
   ```bash
   git status
   ```

2. 打开冲突文件，找到冲突标记：
   ```
   <<<<<<< HEAD
   你当前的代码
   =======
   远程的代码
   >>>>>>> origin/main
   ```

3. 手动编辑，选择保留哪部分代码

4. 删除冲突标记，保存文件

5. 标记为已解决并提交
   ```bash
   git add <冲突文件>
   git commit -m "解决合并冲突"
   git push
   ```

## 2. 身份认证问题

### 场景
Push 或 pull 时提示认证失败。

### 症状
```
remote: Support for password authentication was removed
fatal: Authentication failed
```

### 解决方案

#### 选项 A: Personal Access Token (推荐)

1. 访问 GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. 选择 `repo` 权限
4. 复制 token（只显示一次！）
5. 推送时使用 token 作为密码

#### 选项 B: SSH 密钥

1. 生成 SSH 密钥
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. 添加到 SSH agent
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. 复制公钥
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

4. 添加到 GitHub: Settings → SSH and GPG keys → New SSH key

5. 修改远程 URL
   ```bash
   git remote set-url origin git@github.com:username/repo.git
   ```

## 3. 分支偏离 (Diverged Branches)

### 场景
本地和远程分支都有新的提交，历史分叉了。

### 症状
```
Your branch and 'origin/main' have diverged
```

### 解决方案

#### 选项 A: 优先使用远程代码 (推荐新手)

```bash
git fetch origin
git reset --hard origin/main
```
⚠️ 警告：会丢失本地未推送的提交！

#### 选项 B: 合并两边的更改

```bash
git pull --rebase origin main
```
如果有冲突，解决后：
```bash
git rebase --continue
```

## 4. 忘记推送就离开

### 场景
在公司忘记 push，回家想继续工作。

### 解决方案

**无法避免，但可以补救：**

1. 下次到公司时，先 push 未推送的提交
2. 回家后再 pull
3. 如果家里已经做了工作，会出现分支偏离（参考问题3）

**预防措施：**
- 养成离开前运行此 skill 的习惯
- 设置提醒或自动脚本

## 5. 大文件问题

### 场景
推送时提示文件过大。

### 症状
```
remote: error: File is too large
remote: error: See http://git.io/iEPt8g for more information
```

### 解决方案

1. 将大文件添加到 .gitignore
   ```bash
   echo "large-file.zip" >> .gitignore
   ```

2. 从 Git 历史中移除（如果已提交）
   ```bash
   git rm --cached large-file.zip
   git commit -m "移除大文件"
   ```

3. 考虑使用 Git LFS (Large File Storage)
   ```bash
   git lfs install
   git lfs track "*.zip"
   git add .gitattributes
   ```

## 6. 不小心提交了敏感信息

### 场景
提交了密码、API key 等敏感信息。

### 解决方案

⚠️ 如果已经 push，需要立即：

1. 撤销 GitHub 上泄露的凭据（改密码、撤销 token）

2. 从历史中移除（复杂，需谨慎）
   ```bash
   git filter-branch --force --index-filter \
   "git rm --cached --ignore-unmatch path/to/sensitive-file" \
   --prune-empty --tag-name-filter cat -- --all
   ```

3. 强制推送
   ```bash
   git push origin --force --all
   ```

**预防：**
- 使用 .gitignore 排除 .env, secrets.json 等
- 使用环境变量存储敏感信息

## 7. 错误的提交信息

### 场景
提交信息写错了，还没 push。

### 解决方案

```bash
git commit --amend -m "正确的提交信息"
```

⚠️ 如果已经 push，不要 amend！创建新提交更安全。

## 8. Windows 和 Mac 之间的行尾问题

### 场景
在不同系统间切换时，Git 显示大量文件被修改。

### 症状
```
warning: LF will be replaced by CRLF
```

### 解决方案

配置 Git 自动处理：

**Windows：**
```bash
git config --global core.autocrlf true
```

**Mac/Linux：**
```bash
git config --global core.autocrlf input
```

这样 Git 会自动转换，不会产生虚假的修改。
