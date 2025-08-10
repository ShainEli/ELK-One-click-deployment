#!/bin/bash

# ELK Stack 状态验证脚本
# 快速检查所有ELK组件的运行状态和健康情况
# Author: ELK Team
# Version: 2.0.0

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${CYAN}=== ELK Stack 状态验证 v2.0.0 ===${NC}"
echo

# 设置密码（从环境变量或使用默认值）
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-elastic123456}"
ELASTIC_USER="${ELASTIC_USER:-elastic}"

log_info "检查容器状态..."
if ! docker-compose ps; then
    log_error "无法获取容器状态，请确保在项目根目录运行此脚本"
    exit 1
fi
echo

log_info "验证服务连接..."

# 验证 Elasticsearch
echo -e "\n${CYAN}🔍 Elasticsearch:${NC}"
if elasticsearch_health=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" http://localhost:9200/_cluster/health 2>/dev/null); then
    echo -e "  ✅ 连接成功"
    if command -v jq &> /dev/null; then
        status=$(echo $elasticsearch_health | jq -r .status)
        nodes=$(echo $elasticsearch_health | jq -r .number_of_nodes)
        echo -e "  📊 集群状态: ${GREEN}$status${NC}"
        echo -e "  🖥️  节点数量: $nodes"
    else
        echo -e "  💡 安装jq可获得更详细的状态信息"
    fi
else
    echo -e "  ❌ 连接失败 - 检查服务是否启动"
fi

# 验证 Logstash
echo -e "\n${CYAN}⚙️  Logstash:${NC}"
if logstash_status=$(curl -s http://localhost:9600 2>/dev/null); then
    echo -e "  ✅ 连接成功"
    if command -v jq &> /dev/null; then
        status=$(echo $logstash_status | jq -r .status 2>/dev/null || echo "运行中")
        version=$(echo $logstash_status | jq -r .version 2>/dev/null || echo "未知")
        echo -e "  📊 状态: ${GREEN}$status${NC}"
        echo -e "  📦 版本: $version"
    fi
else
    echo -e "  ❌ 连接失败 - 检查服务是否启动"
fi

# 验证 Kibana
echo -e "\n${CYAN}📊 Kibana:${NC}"
if kibana_status=$(curl -s http://localhost:5601/api/status 2>/dev/null); then
    if command -v jq &> /dev/null; then
        overall_status=$(echo $kibana_status | jq -r '.status.overall.level' 2>/dev/null || echo "unknown")
        if [ "$overall_status" = "available" ]; then
            echo -e "  ✅ 服务可用"
        else
            echo -e "  ⚠️  状态: $overall_status"
        fi
    else
        echo -e "  ✅ 连接成功"
    fi
else
    echo -e "  ❌ 连接失败 - 服务可能正在启动中"
fi

# 验证 Filebeat (如果存在)
echo -e "\n${CYAN}📡 Filebeat:${NC}"
if docker-compose ps filebeat 2>/dev/null | grep -q "Up"; then
    echo -e "  ✅ 服务运行中"
    # 尝试获取Filebeat监控信息
    if curl -s http://localhost:5066/stats 2>/dev/null >/dev/null; then
        echo -e "  📊 监控端点可访问"
    fi
else
    echo -e "  ⚠️  服务未运行或未配置"
fi

echo

log_info "检查索引信息..."
if indices_info=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "http://localhost:9200/_cat/indices?v&h=index,status,health,docs.count,store.size" 2>/dev/null); then
    echo "$indices_info" | head -10
    echo
    total_indices=$(echo "$indices_info" | tail -n +2 | wc -l)
    if [ "$total_indices" -gt 10 ]; then
        echo -e "  ${YELLOW}... 还有 $((total_indices - 10)) 个索引（已省略显示）${NC}"
    fi
else
    log_warn "无法获取索引信息"
fi

echo
echo -e "${CYAN}🌐 访问地址:${NC}"
echo -e "  🔍 Elasticsearch: ${YELLOW}http://localhost:9200${NC}"
echo -e "     用户名: ${GREEN}$ELASTIC_USER${NC}"
echo -e "     密码: ${GREEN}$ELASTIC_PASSWORD${NC}"
echo -e "  📊 Kibana: ${YELLOW}http://localhost:5601${NC}"
echo -e "     用户名: ${GREEN}$ELASTIC_USER${NC}"
echo -e "     密码: ${GREEN}$ELASTIC_PASSWORD${NC}"
echo -e "  ⚙️  Logstash API: ${YELLOW}http://localhost:9600${NC}"

echo
echo -e "${CYAN}💡 有用的命令:${NC}"
echo "  查看服务日志: docker-compose logs -f [service_name]"
echo "  重启服务: docker-compose restart [service_name]"
echo "  完整管理: ./scripts/elk-manager.sh [command]"

echo
echo -e "${GREEN}=== 验证完成 ===${NC}"
