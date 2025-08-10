#!/bin/bash

# ELK Stack 清理脚本
# 安全地清理ELK Stack环境和数据
# Author: ELK Team
# Version: 2.0.0

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}=== ELK Stack 清理工具 v2.0.0 ===${NC}"
echo -e "${RED}⚠️  警告: 此操作将删除ELK Stack数据，请谨慎操作！${NC}"
echo

log_info "停止ELK Stack服务..."
cd "$PROJECT_DIR"
docker-compose down

# 加载环境变量获取版本信息
ELK_VERSION="${ELK_VERSION:-8.19.1}"

# 数据清理选项
echo
log_warn "数据清理选项"
echo "将要清理的数据包括："
echo "  - Elasticsearch 数据和日志"
echo "  - Kibana 数据和日志"
echo "  - Logstash 日志"
echo "  - Filebeat 数据"
echo "  - Docker 卷"
echo
read -p "确认删除所有数据? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "清理数据目录..."

    # 清理各服务数据
    log_info "清理Elasticsearch数据..."
    sudo rm -rf "$PROJECT_DIR/elasticsearch/data/"* 2>/dev/null || true
    sudo rm -rf "$PROJECT_DIR/elasticsearch/logs/"* 2>/dev/null || true

    log_info "清理Kibana数据..."
    sudo rm -rf "$PROJECT_DIR/kibana/data/"* 2>/dev/null || true
    sudo rm -rf "$PROJECT_DIR/kibana/logs/"* 2>/dev/null || true

    log_info "清理Logstash日志..."
    sudo rm -rf "$PROJECT_DIR/logstash/logs/"* 2>/dev/null || true

    log_info "清理Filebeat数据..."
    sudo rm -rf "$PROJECT_DIR/filebeat/data/"* 2>/dev/null || true

    # 删除 Docker 卷
    log_info "删除Docker卷..."
    docker-compose down -v 2>/dev/null || true

    log_info "数据清理完成"
else
    log_info "保留现有数据"
fi

# Docker镜像清理选项
echo
log_warn "Docker镜像清理选项"
echo "将要删除的镜像："
echo "  - elasticsearch:$ELK_VERSION"
echo "  - logstash:$ELK_VERSION"
echo "  - kibana:$ELK_VERSION"
echo "  - filebeat:$ELK_VERSION"
echo
read -p "是否删除ELK Stack Docker镜像? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "删除Docker镜像..."

    # 删除ELK镜像
    docker rmi "docker.elastic.co/elasticsearch/elasticsearch:$ELK_VERSION" 2>/dev/null || log_warn "Elasticsearch镜像删除失败或不存在"
    docker rmi "docker.elastic.co/logstash/logstash:$ELK_VERSION" 2>/dev/null || log_warn "Logstash镜像删除失败或不存在"
    docker rmi "docker.elastic.co/kibana/kibana:$ELK_VERSION" 2>/dev/null || log_warn "Kibana镜像删除失败或不存在"
    docker rmi "docker.elastic.co/beats/filebeat:$ELK_VERSION" 2>/dev/null || log_warn "Filebeat镜像删除失败或不存在"

    log_info "镜像清理完成"
else
    log_info "保留Docker镜像"
fi

# 网络清理
echo
read -p "是否清理未使用的Docker网络和卷? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "清理Docker网络和卷..."
    docker network prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
    log_info "网络和卷清理完成"
fi

echo
log_info "ELK Stack清理操作完成！"
echo
echo -e "${CYAN}后续操作建议:${NC}"
echo "  1. 如需重新部署: ./scripts/elk-manager.sh setup"
echo "  2. 如需快速启动: ./scripts/elk-manager.sh start"
echo "  3. 检查系统状态: ./scripts/elk-manager.sh verify"