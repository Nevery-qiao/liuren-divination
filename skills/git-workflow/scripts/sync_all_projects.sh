#!/bin/bash
# 批量同步所有 Git 项目
# 用于一次性提交并推送所有项目

set -e

# 配置：你的所有项目路径（需要修改为你的实际路径）
PROJECTS=(
    "$HOME/projects/project-a"
    "$HOME/projects/project-b"
    "$HOME/projects/project-c"
    "$HOME/projects/project-d"
)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}批量同步所有 Git 项目${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 统计变量
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# 遍历所有项目
for PROJECT_PATH in "${PROJECTS[@]}"; do
    echo -e "\n${YELLOW}[处理项目] $PROJECT_PATH${NC}"

    # 检查目录是否存在
    if [ ! -d "$PROJECT_PATH" ]; then
        echo -e "${RED}✗ 目录不存在，跳过${NC}"
        ((SKIP_COUNT++))
        continue
    fi

    # 进入项目目录
    cd "$PROJECT_PATH"

    # 检查是否是 Git 仓库
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${RED}✗ 不是 Git 仓库，跳过${NC}"
        ((SKIP_COUNT++))
        continue
    fi

    # 获取仓库名称
    REPO_NAME=$(basename "$PROJECT_PATH")

    # 检查是否有改动
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${GREEN}✓ [$REPO_NAME] 没有改动，跳过${NC}"
        ((SKIP_COUNT++))
        continue
    fi

    echo -e "${YELLOW}  → [$REPO_NAME] 发现改动，开始同步...${NC}"

    # 显示改动的文件
    echo -e "${YELLOW}  → 改动的文件：${NC}"
    git status --short | sed 's/^/    /'

    # 提交改动
    COMMIT_MSG="Auto sync: $(date '+%Y-%m-%d %H:%M:%S') from $(hostname)"

    if git add . && git commit -m "$COMMIT_MSG"; then
        echo -e "${GREEN}  ✓ [$REPO_NAME] 提交成功${NC}"

        # 推送到远程
        if git push; then
            echo -e "${GREEN}  ✓ [$REPO_NAME] 推送成功${NC}"
            ((SUCCESS_COUNT++))
        else
            echo -e "${RED}  ✗ [$REPO_NAME] 推送失败${NC}"
            ((FAIL_COUNT++))
        fi
    else
        echo -e "${RED}  ✗ [$REPO_NAME] 提交失败${NC}"
        ((FAIL_COUNT++))
    fi
done

# 显示总结
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}同步完成！${NC}"
echo -e "${GREEN}成功: $SUCCESS_COUNT${NC}"
echo -e "${RED}失败: $FAIL_COUNT${NC}"
echo -e "${YELLOW}跳过: $SKIP_COUNT${NC}"
echo -e "${BLUE}========================================${NC}"
