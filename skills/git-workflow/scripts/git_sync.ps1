# Git 自动同步脚本 (PowerShell 版本)
# 用于快速执行：检查状态 → 提交 → 推送的完整流程

param(
    [string]$CommitMessage = "Auto sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

Write-Host "=== Git 自动同步开始 ===" -ForegroundColor Cyan

# 检查是否在 git 仓库中
try {
    git rev-parse --is-inside-work-tree 2>&1 | Out-Null
} catch {
    Write-Host "错误: 当前目录不是 Git 仓库" -ForegroundColor Red
    exit 1
}

# 1. 检查状态
Write-Host "`n[1/4] 检查仓库状态..." -ForegroundColor Yellow
git status

# 检查是否有改动
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "✓ 没有需要提交的改动" -ForegroundColor Green
    $hasChanges = $false
} else {
    Write-Host "! 发现未提交的改动" -ForegroundColor Yellow
    $hasChanges = $true
}

# 2. 如果有改动，提交它们
if ($hasChanges) {
    Write-Host "`n[2/4] 添加并提交改动..." -ForegroundColor Yellow

    git add .
    git commit -m $CommitMessage

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 提交完成: $CommitMessage" -ForegroundColor Green
    } else {
        Write-Host "✗ 提交失败" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[2/4] 跳过提交（无改动）" -ForegroundColor Yellow
}

# 3. 推送到远程
Write-Host "`n[3/4] 推送到远程仓库..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 推送成功" -ForegroundColor Green
} else {
    Write-Host "✗ 推送失败" -ForegroundColor Red
    exit 1
}

# 4. 显示最新的提交
Write-Host "`n[4/4] 最近的提交:" -ForegroundColor Yellow
git log --oneline -5

Write-Host "`n=== 同步完成！ ===" -ForegroundColor Green
