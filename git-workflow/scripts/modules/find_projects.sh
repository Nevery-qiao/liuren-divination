#!/bin/bash
# 项目搜索模块 - 自动发现并分类本地 Git 项目

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 排除路径模式
EXCLUDE_PATTERNS=(
    "*/node_modules/*"
    "*/.Trash/*"
    "*/Library/*"
    "*/AppData/*"
    "*/.cache/*"
    "*/.npm/*"
    "*/.nvm/*"
    "*/venv/*"
    "*/env/*"
    "*/__pycache__/*"
)

# 搜索 Git 项目
find_git_projects() {
    local search_path="$1"
    local max_depth="${2:-5}"  # 默认最大深度 5

    echo -e "${BLUE}🔍 正在搜索 Git 项目...${NC}"
    echo -e "${CYAN}   搜索路径: $search_path${NC}"
    echo -e "${CYAN}   最大深度: $max_depth 层${NC}"
    echo ""

    # 构建 find 排除参数
    local exclude_args=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args+=(-path "$pattern" -prune -o)
    done

    # 搜索 .git 目录
    local git_dirs=()
    while IFS= read -r -d '' git_dir; do
        local project_dir="$(dirname "$git_dir")"
        git_dirs+=("$project_dir")
    done < <(find "$search_path" -maxdepth "$max_depth" \( "${exclude_args[@]}" \) -name ".git" -type d -print0 2>/dev/null)

    echo "${#git_dirs[@]}"  # 返回找到的项目数量

    # 导出供其他函数使用
    export FOUND_PROJECTS=("${git_dirs[@]}")
}

# 提取项目元数据
get_project_metadata() {
    local project_path="$1"

    cd "$project_path" 2>/dev/null || return 1

    # 项目名称
    local name="$(basename "$project_path")"

    # 远程仓库
    local has_remote=false
    local remote_url=""
    if git remote get-url origin &>/dev/null; then
        has_remote=true
        remote_url=$(git remote get-url origin)
    fi

    # 当前分支
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    # 最后提交信息
    local last_commit_date=""
    local last_commit_hash=""
    local last_commit_msg=""
    local days_since_commit=99999

    if git log -1 --format="%H|%ci|%s" &>/dev/null; then
        IFS='|' read -r last_commit_hash last_commit_date last_commit_msg <<< "$(git log -1 --format="%H|%ci|%s" 2>/dev/null)"

        # 计算距离最后提交的天数
        if [[ -n "$last_commit_date" ]]; then
            local commit_timestamp=$(date -d "$last_commit_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S %z" "$last_commit_date" +%s 2>/dev/null || echo "0")
            local now_timestamp=$(date +%s)
            days_since_commit=$(( (now_timestamp - commit_timestamp) / 86400 ))
        fi
    fi

    # 未提交的改动
    local uncommitted_changes=false
    local changed_files=0
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        uncommitted_changes=true
        changed_files=$(git status --porcelain 2>/dev/null | wc -l)
    fi

    # 项目大小
    local size=$(du -sk "$project_path" 2>/dev/null | cut -f1 || echo "0")

    # 判断项目类别
    local category="active"
    local suspicious_reasons=()

    # 检查是否是依赖包
    if [[ "$project_path" == *"/node_modules/"* ]] || \
       [[ "$project_path" == *"/venv/"* ]] || \
       [[ "$project_path" == *"/vendor/"* ]]; then
        category="suspicious"
        suspicious_reasons+=("可能是依赖包")
    fi

    # 根据最后提交时间分类
    if [[ $days_since_commit -gt 180 ]]; then
        category="inactive"
    elif [[ $days_since_commit -gt 30 ]] && [[ "$category" != "suspicious" ]]; then
        category="dormant"
    fi

    # 输出 JSON 格式（简化版，实际使用时可以用 jq 格式化）
    cat << EOF
{
  "path": "$project_path",
  "name": "$name",
  "hasRemote": $has_remote,
  "remoteUrl": "$remote_url",
  "branch": "$branch",
  "lastCommitHash": "$last_commit_hash",
  "lastCommitDate": "$last_commit_date",
  "lastCommitMsg": "$last_commit_msg",
  "daysSinceCommit": $days_since_commit,
  "uncommittedChanges": $uncommitted_changes,
  "changedFiles": $changed_files,
  "size": $size,
  "category": "$category"
}
EOF
}

# 格式化显示项目列表
display_projects() {
    local -n projects_ref=$1  # 使用 nameref 传递数组

    if [[ ${#projects_ref[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  未找到任何 Git 项目${NC}"
        return 1
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}发现 ${#projects_ref[@]} 个 Git 项目${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 分类存储
    local active_projects=()
    local dormant_projects=()
    local inactive_projects=()
    local suspicious_projects=()

    # 分类项目
    local index=1
    for project_path in "${projects_ref[@]}"; do
        cd "$project_path" 2>/dev/null || continue

        local name="$(basename "$project_path")"
        local has_remote=false
        local remote_url=""
        if git remote get-url origin &>/dev/null; then
            has_remote=true
            remote_url=$(git remote get-url origin | sed 's|https://||' | sed 's|git@||' | sed 's|:|/|')
        fi

        # 最后提交时间
        local last_commit_date=$(git log -1 --format="%cr" 2>/dev/null || echo "未知")
        local days_since_commit=99999

        if git log -1 --format="%ci" &>/dev/null; then
            local commit_date_full=$(git log -1 --format="%ci" 2>/dev/null)
            local commit_timestamp=$(date -d "$commit_date_full" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S %z" "$commit_date_full" +%s 2>/dev/null || echo "0")
            local now_timestamp=$(date +%s)
            days_since_commit=$(( (now_timestamp - commit_timestamp) / 86400 ))
        fi

        # 未提交改动
        local status_icon="✓"
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            status_icon="⚠️"
        fi

        # 远程状态
        local remote_icon="✓"
        if ! $has_remote; then
            remote_icon="⚠️"
        fi

        # 分类
        local category="active"
        if [[ "$project_path" == *"/node_modules/"* ]] || \
           [[ "$project_path" == *"/venv/"* ]] || \
           [[ "$project_path" == *"/vendor/"* ]]; then
            category="suspicious"
        elif [[ $days_since_commit -gt 180 ]]; then
            category="inactive"
        elif [[ $days_since_commit -gt 30 ]]; then
            category="dormant"
        fi

        # 存储到对应分类
        local project_info="[$index]|$name|$project_path|$has_remote|$remote_url|$last_commit_date|$status_icon|$remote_icon"

        case "$category" in
            "active")
                active_projects+=("$project_info")
                ;;
            "dormant")
                dormant_projects+=("$project_info")
                ;;
            "inactive")
                inactive_projects+=("$project_info")
                ;;
            "suspicious")
                suspicious_projects+=("$project_info")
                ;;
        esac

        ((index++))
    done

    # 显示活跃项目
    if [[ ${#active_projects[@]} -gt 0 ]]; then
        echo -e "${GREEN}📁 活跃项目（最后提交 < 1个月）：${NC}"
        echo ""
        for project in "${active_projects[@]}"; do
            IFS='|' read -r idx name path has_remote remote last_commit status_icon remote_icon <<< "$project"
            echo -e "  ${GREEN}$idx${NC}. $status_icon $name"
            echo -e "      └─ 路径: $path"
            if [[ "$has_remote" == "true" ]]; then
                echo -e "      └─ 远程: $remote_icon $remote"
            else
                echo -e "      └─ 远程: ${YELLOW}⚠️ 未配置${NC}"
            fi
            echo -e "      └─ 最后提交: $last_commit"
            echo ""
        done
    fi

    # 显示休眠项目
    if [[ ${#dormant_projects[@]} -gt 0 ]]; then
        echo -e "${YELLOW}📁 休眠项目（最后提交 1-6个月）：${NC}"
        echo ""
        for project in "${dormant_projects[@]}"; do
            IFS='|' read -r idx name path has_remote remote last_commit status_icon remote_icon <<< "$project"
            echo -e "  ${YELLOW}$idx${NC}. $status_icon $name"
            echo -e "      └─ 路径: $path"
            if [[ "$has_remote" == "true" ]]; then
                echo -e "      └─ 远程: $remote_icon $remote"
            else
                echo -e "      └─ 远程: ${YELLOW}⚠️ 未配置${NC}"
            fi
            echo -e "      └─ 最后提交: $last_commit"
            echo ""
        done
    fi

    # 显示不活跃项目
    if [[ ${#inactive_projects[@]} -gt 0 ]]; then
        echo -e "${RED}📁 可能废弃（最后提交 > 6个月）：${NC}"
        echo ""
        for project in "${inactive_projects[@]}"; do
            IFS='|' read -r idx name path has_remote remote last_commit status_icon remote_icon <<< "$project"
            echo -e "  ${RED}$idx${NC}. $status_icon $name"
            echo -e "      └─ 路径: $path"
            echo -e "      └─ 最后提交: $last_commit"
            echo ""
        done
    fi

    # 显示疑似依赖
    if [[ ${#suspicious_projects[@]} -gt 0 ]]; then
        echo -e "${RED}⚠️  疑似依赖包（建议排除）：${NC}"
        echo ""
        for project in "${suspicious_projects[@]}"; do
            IFS='|' read -r idx name path has_remote remote last_commit status_icon remote_icon <<< "$project"
            echo -e "  ${RED}$idx${NC}. $name"
            echo -e "      └─ 路径: $path"
            echo ""
        done
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 导出函数供其他脚本使用
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "项目搜索模块"
    echo ""
    echo "用法: source find_projects.sh"
    echo ""
    echo "可用函数:"
    echo "  find_git_projects <path> [depth]  - 搜索 Git 项目"
    echo "  get_project_metadata <path>       - 获取项目元数据"
    echo "  display_projects <array>          - 显示项目列表"
    echo ""
    echo "示例:"
    echo "  source find_projects.sh"
    echo "  find_git_projects ~/work 3"
    echo "  display_projects FOUND_PROJECTS"
fi
