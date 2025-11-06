# 批量同步所有 Git 项目 (PowerShell 版本)
# 用于一次性提交并推送所有项目

param(
    [switch]$DryRun  # 仅显示会做什么，不实际执行
)

# 配置：你的所有项目路径（需要修改为你的实际路径）
$Projects = @(
    "$HOME\projects\project-a",
    "$HOME\projects\project-b",
    "$HOME\projects\project-c",
    "$HOME\projects\project-d"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "批量同步所有 Git 项目" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[预览模式] 不会实际执行任何操作`n" -ForegroundColor Yellow
}

# 统计变量
$successCount = 0
$failCount = 0
$skipCount = 0

# 遍历所有项目
foreach ($projectPath in $Projects) {
    Write-Host "`n[处理项目] $projectPath" -ForegroundColor Yellow

    # 检查目录是否存在
    if (-not (Test-Path $projectPath)) {
        Write-Host "✗ 目录不存在，跳过" -ForegroundColor Red
        $skipCount++
        continue
    }

    # 保存当前位置
    $originalLocation = Get-Location

    try {
        # 进入项目目录
        Set-Location $projectPath

        # 检查是否是 Git 仓库
        try {
            git rev-parse --is-inside-work-tree 2>&1 | Out-Null
        } catch {
            Write-Host "✗ 不是 Git 仓库，跳过" -ForegroundColor Red
            $skipCount++
            continue
        }

        # 获取仓库名称
        $repoName = Split-Path $projectPath -Leaf

        # 检查是否有改动
        $status = git status --porcelain
        if ([string]::IsNullOrWhiteSpace($status)) {
            Write-Host "✓ [$repoName] 没有改动，跳过" -ForegroundColor Green
            $skipCount++
            continue
        }

        Write-Host "  → [$repoName] 发现改动，开始同步..." -ForegroundColor Yellow

        # 显示改动的文件
        Write-Host "  → 改动的文件：" -ForegroundColor Yellow
        git status --short | ForEach-Object { Write-Host "    $_" }

        if ($DryRun) {
            Write-Host "  [预览] 将会提交并推送这些改动" -ForegroundColor Yellow
            $skipCount++
            continue
        }

        # 提交改动
        $commitMsg = "Auto sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') from $env:COMPUTERNAME"

        git add .
        git commit -m $commitMsg 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ [$repoName] 提交成功" -ForegroundColor Green

            # 推送到远程
            git push 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ [$repoName] 推送成功" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  ✗ [$repoName] 推送失败" -ForegroundColor Red
                $failCount++
            }
        } else {
            Write-Host "  ✗ [$repoName] 提交失败" -ForegroundColor Red
            $failCount++
        }
    } finally {
        # 恢复原始位置
        Set-Location $originalLocation
    }
}

# 显示总结
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "同步完成！" -ForegroundColor Cyan
Write-Host "成功: $successCount" -ForegroundColor Green
Write-Host "失败: $failCount" -ForegroundColor Red
Write-Host "跳过: $skipCount" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
