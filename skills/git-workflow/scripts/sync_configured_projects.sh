#!/bin/bash
# 读取配置文件并批量同步项目

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_LIST="$HOME/.claude/skills/git-workflow/projects.list"

if [[ ! -f "$CONFIG_LIST" ]]; then
    echo -e "${RED}❌ 未找到配置文件${NC}"
    echo -e "${YELLOW}   请先运行配置向导：${NC}"
    echo -e "${YELLOW}   bash ~/.claude/skills/git-workflow/scripts/configure_wizard.sh${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}批量同步已配置的项目${NC}"
echo -e "${BLUE}========================================${NC}\n"

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

while IFS='|' read -r project_path name has_remote remote_url branch; do
    echo -e "\n${YELLOW}[处理项目] $name${NC}"

    if [[ ! -d "$project_path" ]]; then
        echo -e "${RED}✗ 目录不存在，跳过${NC}"
        ((SKIP_COUNT++))
        continue
    fi

    cd "$project_path"

    # 检查是否有改动
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${GREEN}✓ 没有改动，跳过${NC}"
        ((SKIP_COUNT++))
        continue
    fi

    echo -e "${YELLOW}  → 发现改动，开始同步...${NC}"

    # 显示改动的文件
    echo -e "${YELLOW}  → 改动的文件：${NC}"
    git status --short | sed 's/^/    /'

    # 提交改动
    COMMIT_MSG="Auto sync: $(date '+%Y-%m-%d %H:%M:%S') from $(hostname)"

    if git add . && git commit -m "$COMMIT_MSG"; then
        echo -e "${GREEN}  ✓ 提交成功${NC}"

        # 推送到远程
        if [[ "$has_remote" == "true" ]]; then
            if git push; then
                echo -e "${GREEN}  ✓ 推送成功${NC}"
                ((SUCCESS_COUNT++))
            else
                echo -e "${RED}  ✗ 推送失败${NC}"
                ((FAIL_COUNT++))
            fi
        else
            echo -e "${YELLOW}  ⚠️  无远程仓库，跳过推送${NC}"
            ((SKIP_COUNT++))
        fi
    else
        echo -e "${RED}  ✗ 提交失败${NC}"
        ((FAIL_COUNT++))
    fi

done < "$CONFIG_LIST"

# 显示总结
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}同步完成！${NC}"
echo -e "${GREEN}成功: $SUCCESS_COUNT${NC}"
echo -e "${RED}失败: $FAIL_COUNT${NC}"
echo -e "${YELLOW}跳过: $SKIP_COUNT${NC}"
echo -e "${BLUE}========================================${NC}"
