#!/bin/bash
# 智能配置向导 - 批量同步配置工具
# 自动发现项目、检查远程、保存配置

set -e

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# 加载模块
source "$MODULES_DIR/config_manager.sh"
source "$MODULES_DIR/find_projects.sh"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Git 批量同步 - 智能配置向导               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# 步骤 1: 检查现有配置
echo -e "${CYAN}[步骤 1/5] 检查配置状态...${NC}"

if config_exists; then
    echo -e "${GREEN}✅ 找到现有配置${NC}"
    echo ""
    config_show_summary
    echo ""
    read -p "是否重新配置？(y/n): " reconfigure
    if [[ "$reconfigure" != "y" ]]; then
        echo -e "${YELLOW}保持现有配置，退出向导${NC}"
        exit 0
    fi
    config_backup
else
    echo -e "${YELLOW}❌ 未找到配置，开始首次配置${NC}"
fi

echo ""

# 步骤 2: 选择搜索路径
echo -e "${CYAN}[步骤 2/5] 选择项目搜索路径${NC}"
echo ""
echo "请选择搜索范围："
echo "  [1] ~/work 和 ~/projects（推荐）"
echo "  [2] 整个用户目录 ~/（可能较慢）"
echo "  [3] 自定义路径"
echo ""

read -p "请选择 (1/2/3): " search_choice

case "$search_choice" in
    1)
        SEARCH_PATHS=("$HOME/work" "$HOME/projects")
        ;;
    2)
        SEARCH_PATHS=("$HOME")
        ;;
    3)
        read -p "请输入搜索路径: " custom_path
        SEARCH_PATHS=("$custom_path")
        ;;
    *)
        echo -e "${RED}无效选择，使用默认路径${NC}"
        SEARCH_PATHS=("$HOME/work" "$HOME/projects")
        ;;
esac

echo ""

# 步骤 3: 搜索项目
echo -e "${CYAN}[步骤 3/5] 搜索 Git 项目${NC}"
echo ""

ALL_PROJECTS=()

for search_path in "${SEARCH_PATHS[@]}"; do
    if [[ -d "$search_path" ]]; then
        echo -e "搜索: $search_path"
        find_git_projects "$search_path" 4
        ALL_PROJECTS+=("${FOUND_PROJECTS[@]}")
    else
        echo -e "${YELLOW}⚠️  路径不存在，跳过: $search_path${NC}"
    fi
done

if [[ ${#ALL_PROJECTS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ 未找到任何 Git 项目${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 找到 ${#ALL_PROJECTS[@]} 个项目${NC}"
echo ""

# 显示项目列表
display_projects ALL_PROJECTS

# 步骤 4: 选择项目
echo -e "${CYAN}[步骤 4/5] 选择需要批量同步的项目${NC}"
echo ""
echo "请输入项目编号（多个用逗号分隔，如: 1,2,3）"
echo "  • 输入 'all' - 选择所有"
echo "  • 输入 'active' - 只选择活跃项目（推荐）"
echo "  • 输入 'cancel' - 取消"
echo ""

read -p "你的选择: " selection

SELECTED_PROJECTS=()

case "$selection" in
    "cancel")
        echo -e "${YELLOW}已取消配置${NC}"
        exit 0
        ;;
    "all")
        SELECTED_PROJECTS=("${ALL_PROJECTS[@]}")
        ;;
    "active")
        # 只选择活跃项目（简化：选择所有有远程的）
        for project in "${ALL_PROJECTS[@]}"; do
            cd "$project" 2>/dev/null || continue
            if git remote get-url origin &>/dev/null; then
                SELECTED_PROJECTS+=("$project")
            fi
        done
        ;;
    *)
        # 解析数字列表
        IFS=',' read -ra INDICES <<< "$selection"
        for idx in "${INDICES[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')  # 去除空格
            if [[ $idx =~ ^[0-9]+$ ]] && [[ $idx -le ${#ALL_PROJECTS[@]} ]]; then
                SELECTED_PROJECTS+=("${ALL_PROJECTS[$((idx-1))]}")
            fi
        done
        ;;
esac

if [[ ${#SELECTED_PROJECTS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ 未选择任何项目${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 已选择 ${#SELECTED_PROJECTS[@]} 个项目：${NC}"
for project in "${SELECTED_PROJECTS[@]}"; do
    echo "  • $(basename "$project")"
done

echo ""
read -p "是否确认？(y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo -e "${YELLOW}已取消${NC}"
    exit 0
fi

# 步骤 5: 保存配置
echo ""
echo -e "${CYAN}[步骤 5/5] 保存配置${NC}"
echo ""

# 创建配置文件
if ! config_exists; then
    config_create
fi

# 保存搜索路径
paths_json="["
for i in "${!SEARCH_PATHS[@]}"; do
    paths_json+="\"${SEARCH_PATHS[$i]}\""
    if [[ $i -lt $((${#SEARCH_PATHS[@]} - 1)) ]]; then
        paths_json+=","
    fi
done
paths_json+="]"

# 保存用户信息
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$GIT_NAME" ]]; then
    config_set "user.gitName" "$GIT_NAME"
fi
if [[ -n "$GIT_EMAIL" ]]; then
    config_set "user.gitEmail" "$GIT_EMAIL"
fi

# 保存项目（简化版：直接写入配置文件）
# 实际使用时应该用 jq 或更完善的 JSON 操作

PROJECT_COUNT=0

for project_path in "${SELECTED_PROJECTS[@]}"; do
    cd "$project_path" 2>/dev/null || continue

    local name="$(basename "$project_path")"
    local has_remote=false
    local remote_url=""

    if git remote get-url origin &>/dev/null; then
        has_remote=true
        remote_url=$(git remote get-url origin)
    fi

    local branch=$(git branch --show-current 2>/dev/null || echo "main")

    echo -e "  ✓ 添加: $name"

    # 这里简化处理，实际应该用 config_add_project
    # 由于复杂度，这里先记录路径列表
    echo "$project_path|$name|$has_remote|$remote_url|$branch" >> "$HOME/.claude/skills/git-workflow/projects.list"

    ((PROJECT_COUNT++))
done

echo ""
echo -e "${GREEN}✅ 配置完成！${NC}"
echo -e "${GREEN}   已添加 $PROJECT_COUNT 个项目${NC}"
echo ""

# 显示使用说明
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🎉 配置成功！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "后续你可以："
echo -e "  • 对 Claude 说：${GREEN}'同步所有项目'${NC} - 批量同步"
echo -e "  • 对 Claude 说：${GREEN}'我要下班了'${NC} - 单项目同步"
echo -e "  • 运行脚本：${CYAN}~/.claude/skills/git-workflow/scripts/sync_all_projects.sh${NC}"
echo ""
echo -e "配置文件位置："
echo -e "  $HOME/.claude/skills/git-workflow/projects.json"
echo -e "  $HOME/.claude/skills/git-workflow/projects.list"
echo ""

read -p "现在要执行首次批量同步吗？(y/n): " do_sync

if [[ "$do_sync" == "y" ]]; then
    echo ""
    echo -e "${BLUE}开始批量同步...${NC}"
    echo ""

    # 调用同步脚本（如果存在）
    SYNC_SCRIPT="$SCRIPT_DIR/sync_configured_projects.sh"

    if [[ -f "$SYNC_SCRIPT" ]]; then
        bash "$SYNC_SCRIPT"
    else
        echo -e "${YELLOW}⚠️  同步脚本未找到，请稍后手动同步${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ 配置向导完成！${NC}"
