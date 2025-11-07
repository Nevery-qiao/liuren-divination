#!/bin/bash
# Git 自动同步脚本
# 用于快速执行：检查状态 → 提交 → 推送的完整流程

set -e  # 遇到错误立即退出

echo "=== Git 自动同步开始 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否在 git 仓库中
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}错误: 当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 1. 检查状态
echo -e "\n${YELLOW}[1/4] 检查仓库状态...${NC}"
git status

# 检查是否有改动
if git diff-index --quiet HEAD --; then
    echo -e "${GREEN}✓ 没有需要提交的改动${NC}"
    HAS_CHANGES=false
else
    echo -e "${YELLOW}! 发现未提交的改动${NC}"
    HAS_CHANGES=true
fi

# 2. 如果有改动，提交它们
if [ "$HAS_CHANGES" = true ]; then
    echo -e "\n${YELLOW}[2/4] 添加并提交改动...${NC}"

    # 获取提交消息（可以通过参数传入，否则使用默认）
    if [ -z "$1" ]; then
        COMMIT_MSG="Auto sync: $(date '+%Y-%m-%d %H:%M:%S')"
    else
        COMMIT_MSG="$1"
    fi

    git add .
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ 提交完成: $COMMIT_MSG${NC}"
else
    echo -e "\n${YELLOW}[2/4] 跳过提交（无改动）${NC}"
fi

# 3. 推送到远程
echo -e "\n${YELLOW}[3/4] 推送到远程仓库...${NC}"
if git push; then
    echo -e "${GREEN}✓ 推送成功${NC}"
else
    echo -e "${RED}✗ 推送失败${NC}"
    exit 1
fi

# 4. 显示最新的提交
echo -e "\n${YELLOW}[4/4] 最近的提交:${NC}"
git log --oneline -5

echo -e "\n${GREEN}=== 同步完成！ ===${NC}"
