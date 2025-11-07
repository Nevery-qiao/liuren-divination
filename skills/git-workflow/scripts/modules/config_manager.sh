#!/bin/bash
# 配置管理模块 - 处理 projects.json 的读写
# 支持 jq (推荐) 或纯 Bash fallback

set -e

# 配置文件路径
CONFIG_DIR="$HOME/.claude/skills/git-workflow"
CONFIG_FILE="$CONFIG_DIR/projects.json"
TEMPLATE_FILE="$(dirname "$(dirname "$(dirname "$0")")")/templates/projects.json.template"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查 jq 是否可用
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
fi

###################
# 核心函数
###################

# 检查配置文件是否存在
config_exists() {
    [[ -f "$CONFIG_FILE" ]]
}

# 创建新配置文件
config_create() {
    echo -e "${BLUE}📝 创建新的配置文件...${NC}"

    # 确保目录存在
    mkdir -p "$CONFIG_DIR"

    # 复制模板
    if [[ -f "$TEMPLATE_FILE" ]]; then
        cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    else
        # 如果模板不存在，创建基础配置
        cat > "$CONFIG_FILE" << 'EOF'
{
  "version": "1.0.0",
  "configuredAt": "",
  "lastSync": null,
  "user": {
    "githubUsername": "",
    "gitName": "",
    "gitEmail": "",
    "authMethod": "",
    "hasToken": false,
    "hasSSH": false
  },
  "searchPaths": [],
  "projects": [],
  "settings": {
    "autoCommitMessage": "Auto sync: {date} from {hostname}",
    "skipNoChanges": true,
    "showProgress": true,
    "parallelSync": false
  },
  "stats": {
    "totalSyncs": 0,
    "successfulSyncs": 0,
    "failedSyncs": 0,
    "lastError": null
  }
}
EOF
    fi

    # 设置配置时间
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
    config_set "configuredAt" "$now"

    echo -e "${GREEN}✅ 配置文件已创建: $CONFIG_FILE${NC}"
}

# 读取配置值 (使用 jq 或 fallback)
config_get() {
    local key="$1"
    local default="${2:-}"

    if ! config_exists; then
        echo "$default"
        return 1
    fi

    if $HAS_JQ; then
        # 使用 jq
        local value=$(jq -r ".$key // empty" "$CONFIG_FILE" 2>/dev/null)
        if [[ -z "$value" || "$value" == "null" ]]; then
            echo "$default"
        else
            echo "$value"
        fi
    else
        # Fallback: 简单的 grep 和 sed
        local value=$(grep "\"$key\"" "$CONFIG_FILE" | head -1 | sed 's/.*: *"\(.*\)".*/\1/' | sed 's/,$//')
        if [[ -z "$value" ]]; then
            echo "$default"
        else
            echo "$value"
        fi
    fi
}

# 设置配置值
config_set() {
    local key="$1"
    local value="$2"

    if ! config_exists; then
        config_create
    fi

    if $HAS_JQ; then
        # 使用 jq
        local temp_file=$(mktemp)
        jq ".$key = \"$value\"" "$CONFIG_FILE" > "$temp_file"
        mv "$temp_file" "$CONFIG_FILE"
    else
        # Fallback: 使用 sed (简单替换)
        sed -i.bak "s|\"$key\": *\"[^\"]*\"|\"$key\": \"$value\"|" "$CONFIG_FILE"
        rm -f "$CONFIG_FILE.bak"
    fi
}

# 读取所有项目
config_get_projects() {
    if ! config_exists; then
        echo "[]"
        return
    fi

    if $HAS_JQ; then
        jq -c '.projects' "$CONFIG_FILE" 2>/dev/null || echo "[]"
    else
        # Fallback: 返回空数组
        echo "[]"
    fi
}

# 添加项目
config_add_project() {
    local project_json="$1"

    if ! config_exists; then
        config_create
    fi

    if $HAS_JQ; then
        local temp_file=$(mktemp)
        jq ".projects += [$project_json]" "$CONFIG_FILE" > "$temp_file"
        mv "$temp_file" "$CONFIG_FILE"
        echo -e "${GREEN}✅ 项目已添加${NC}"
    else
        echo -e "${YELLOW}⚠️  需要 jq 才能添加项目${NC}"
        echo -e "${YELLOW}   安装: brew install jq (Mac) 或 apt install jq (Linux)${NC}"
        return 1
    fi
}

# 获取项目数量
config_get_project_count() {
    if ! config_exists; then
        echo "0"
        return
    fi

    if $HAS_JQ; then
        jq '.projects | length' "$CONFIG_FILE" 2>/dev/null || echo "0"
    else
        # Fallback: 计算 "id": 出现次数
        grep -c '"id":' "$CONFIG_FILE" 2>/dev/null || echo "0"
    fi
}

# 更新统计信息
config_update_stats() {
    local total="$1"
    local success="$2"
    local failed="$3"

    if ! config_exists; then
        return 1
    fi

    if $HAS_JQ; then
        local temp_file=$(mktemp)
        local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

        jq ".stats.totalSyncs += $total |
            .stats.successfulSyncs += $success |
            .stats.failedSyncs += $failed |
            .lastSync = \"$now\"" "$CONFIG_FILE" > "$temp_file"
        mv "$temp_file" "$CONFIG_FILE"
    fi
}

# 显示配置摘要
config_show_summary() {
    if ! config_exists; then
        echo -e "${RED}❌ 未找到配置文件${NC}"
        return 1
    fi

    echo -e "${BLUE}📋 配置摘要${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local configured_at=$(config_get "configuredAt" "未知")
    local project_count=$(config_get_project_count)
    local username=$(config_get "user.githubUsername" "未配置")
    local git_name=$(config_get "user.gitName" "未配置")
    local git_email=$(config_get "user.gitEmail" "未配置")

    echo -e "配置文件: $CONFIG_FILE"
    echo -e "配置时间: $configured_at"
    echo -e "GitHub 用户: $username"
    echo -e "Git 姓名: $git_name"
    echo -e "Git 邮箱: $git_email"
    echo -e "已配置项目: $project_count 个"

    if $HAS_JQ; then
        local total=$(jq -r '.stats.totalSyncs' "$CONFIG_FILE" 2>/dev/null || echo "0")
        local success=$(jq -r '.stats.successfulSyncs' "$CONFIG_FILE" 2>/dev/null || echo "0")
        local failed=$(jq -r '.stats.failedSyncs' "$CONFIG_FILE" 2>/dev/null || echo "0")
        echo -e "同步统计: 总计 $total 次 | 成功 $success | 失败 $failed"
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 验证配置文件
config_validate() {
    if ! config_exists; then
        return 1
    fi

    if $HAS_JQ; then
        if jq empty "$CONFIG_FILE" 2>/dev/null; then
            return 0
        else
            echo -e "${RED}❌ 配置文件 JSON 格式错误${NC}"
            return 1
        fi
    else
        # 简单验证：检查是否有关键字段
        if grep -q '"version"' "$CONFIG_FILE" && grep -q '"projects"' "$CONFIG_FILE"; then
            return 0
        else
            echo -e "${RED}❌ 配置文件格式可能有误${NC}"
            return 1
        fi
    fi
}

# 备份配置文件
config_backup() {
    if config_exists; then
        local backup_file="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$backup_file"
        echo -e "${GREEN}✅ 配置已备份到: $backup_file${NC}"
    fi
}

# 删除配置文件
config_delete() {
    if config_exists; then
        config_backup
        rm "$CONFIG_FILE"
        echo -e "${GREEN}✅ 配置文件已删除${NC}"
    else
        echo -e "${YELLOW}⚠️  配置文件不存在${NC}"
    fi
}

###################
# 导出函数供其他脚本使用
###################

# 如果直接运行此脚本，显示帮助
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "配置管理模块"
    echo ""
    echo "用法: source config_manager.sh"
    echo ""
    echo "可用函数:"
    echo "  config_exists          - 检查配置是否存在"
    echo "  config_create          - 创建新配置"
    echo "  config_get <key>       - 获取配置值"
    echo "  config_set <key> <val> - 设置配置值"
    echo "  config_get_projects    - 获取所有项目"
    echo "  config_add_project     - 添加项目"
    echo "  config_get_project_count - 获取项目数量"
    echo "  config_update_stats    - 更新统计"
    echo "  config_show_summary    - 显示配置摘要"
    echo "  config_validate        - 验证配置"
    echo "  config_backup          - 备份配置"
    echo "  config_delete          - 删除配置"
    echo ""
    echo "示例:"
    echo "  source config_manager.sh"
    echo "  config_create"
    echo "  config_set 'user.githubUsername' 'myname'"
    echo "  config_show_summary"
fi
