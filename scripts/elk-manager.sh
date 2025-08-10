#!/bin/bash

# ELK Stack 管理脚本
# 整合所有ELK相关操作的统一管理工具
# Author: ELK Team
# Version: 2.1.0

set -e

# 脚本信息
SCRIPT_VERSION="2.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

# 显示帮助信息
show_help() {
    echo -e "${CYAN}ELK Stack Manager v${SCRIPT_VERSION}${NC}"
    echo "统一管理 Elasticsearch、Logstash、Kibana 和 Filebeat 服务"
    echo
    echo -e "${YELLOW}用法:${NC}"
    echo "  $0 <command> [options]"
    echo
    echo -e "${YELLOW}命令:${NC}"
    echo -e "  ${GREEN}setup${NC}           完整部署ELK Stack（首次安装）"
    echo -e "  ${GREEN}start${NC}           启动所有服务"
    echo -e "  ${GREEN}stop${NC}            停止所有服务"
    echo -e "  ${GREEN}restart${NC}         重启所有服务"
    echo -e "  ${GREEN}status${NC}          查看服务状态"
    echo -e "  ${GREEN}verify${NC}          验证服务健康状态"
    echo -e "  ${GREEN}logs${NC} [service]  查看服务日志（可选指定服务名）"
    echo -e "  ${GREEN}cleanup${NC}         清理环境（谨慎使用）"
    echo -e "  ${GREEN}update${NC}          更新服务配置"
    echo -e "  ${GREEN}backup${NC}          备份配置和数据"
    echo -e "  ${GREEN}restore${NC}         恢复配置和数据"
    echo -e "  ${GREEN}generate-logs${NC}   生成示例日志数据"
    echo -e "  ${GREEN}reset-password${NC}  重置用户密码"
    echo -e "  ${GREEN}quick-start${NC}     快速启动（轻量级，无完整配置）"
    echo
    echo -e "${YELLOW}服务名称:${NC}"
    echo "  elasticsearch, logstash, kibana, filebeat"
    echo
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0 setup              # 首次完整部署"
    echo "  $0 quick-start        # 快速启动开发环境"
    echo "  $0 start              # 启动所有服务"
    echo "  $0 logs elasticsearch # 查看ES日志"
    echo "  $0 verify             # 健康检查"
}

# 加载环境变量
load_env() {
    local env_files=("$PROJECT_DIR/.env" "$SCRIPT_DIR/.env" ".env")
    local env_loaded=false

    for env_file in "${env_files[@]}"; do
        if [ -f "$env_file" ]; then
            log_info "加载环境配置: $env_file"
            set -a
            source "$env_file"
            set +a
            env_loaded=true
            break
        fi
    done

    if [ "$env_loaded" = false ]; then
        log_warn "未找到.env文件，使用默认配置"
    fi

    # 设置默认值
    export ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-"elastic123456"}
    export KIBANA_PASSWORD=${KIBANA_PASSWORD:-"kibana123456"}
    export LOGSTASH_PASSWORD=${LOGSTASH_PASSWORD:-"logstash123456"}
    export ELASTIC_USER=${ELASTIC_USER:-"elastic"}
    export ELK_VERSION=${ELK_VERSION:-"8.19.1"}
}

# 检查系统环境
check_environment() {
    log_info "检查系统环境..."

    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装Docker"
        exit 1
    fi

    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装Docker Compose"
        exit 1
    fi

    # 检查内存
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_mem" -lt 4096 ]; then
        log_warn "系统内存少于4GB，可能影响ELK性能"
    fi

    # 检查磁盘空间
    local disk_space=$(df -BG "$PROJECT_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$disk_space" -lt 10 ]; then
        log_warn "磁盘剩余空间少于10GB，可能影响数据存储"
    fi

    log_info "环境检查完成"
}

# 设置系统参数
setup_system() {
    log_info "设置系统参数..."

    # 设置vm.max_map_count
    current_max_map_count=$(sysctl -n vm.max_map_count)
    if [ "$current_max_map_count" -lt 262144 ]; then
        log_info "设置vm.max_map_count=262144"
        sudo sysctl -w vm.max_map_count=262144
        echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf >/dev/null
    fi

    # 创建目录并设置权限
    log_info "创建数据目录..."
    mkdir -p "$PROJECT_DIR"/{elasticsearch/{data,logs},logstash/logs,kibana/{data,logs},filebeat/data}

    log_info "设置目录权限..."
    sudo chown -R 1000:1000 "$PROJECT_DIR/elasticsearch/"
    sudo chown -R 1000:1000 "$PROJECT_DIR/logstash/"
    sudo chown -R 1000:1000 "$PROJECT_DIR/kibana/"
    sudo chown -R 1000:1000 "$PROJECT_DIR/filebeat/" 2>/dev/null || true

    # 修复Filebeat配置文件权限 (Filebeat要求配置文件由root拥有)
    if [ -f "$PROJECT_DIR/filebeat/config/filebeat.yml" ]; then
        log_info "设置Filebeat配置文件权限..."
        sudo chown root:root "$PROJECT_DIR/filebeat/config/filebeat.yml"
        sudo chmod 600 "$PROJECT_DIR/filebeat/config/filebeat.yml"
    fi
}

# 完整安装设置
cmd_setup() {
    log_info "开始ELK Stack完整部署..."

    check_environment
    load_env
    setup_system

    # 检查端口占用
    log_info "检查端口占用..."
    local ports=(9200 9300 5044 5000 9600 5601)
    for port in "${ports[@]}"; do
        if ss -tuln | grep ":$port " > /dev/null 2>&1; then
            log_warn "端口 $port 已被占用"
        fi
    done

    # 停止现有服务
    log_info "停止现有服务..."
    cd "$PROJECT_DIR"
    docker-compose down 2>/dev/null || true

    # 询问是否清理数据
    echo
    read -p "是否清理现有数据? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "清理现有数据..."
        sudo rm -rf "$PROJECT_DIR/elasticsearch/data/"*
    fi

    # 启动Elasticsearch并配置安全
    log_info "启动Elasticsearch..."
    docker-compose up -d elasticsearch

    # 等待Elasticsearch启动
    log_info "等待Elasticsearch启动..."
    for i in {1..60}; do
        if curl -s http://localhost:9200 >/dev/null 2>&1; then
            log_info "Elasticsearch已启动"
            break
        fi
        if [ $i -eq 60 ]; then
            log_error "Elasticsearch启动超时"
            exit 1
        fi
        sleep 2
        printf "."
    done
    echo

    # 配置安全
    log_info "配置安全认证..."

    # 设置elastic用户密码
    docker exec elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -p "$ELASTIC_PASSWORD" --batch >/dev/null 2>&1 || {
        log_warn "使用API设置elastic密码..."
        curl -s -X POST "localhost:9200/_security/user/elastic/_password" \
             -H "Content-Type: application/json" \
             -d "{\"password\":\"$ELASTIC_PASSWORD\"}" >/dev/null 2>&1 || true
    }

    sleep 3

    # 设置其他用户密码
    curl -s -X POST "localhost:9200/_security/user/kibana_system/_password" \
         -u "elastic:$ELASTIC_PASSWORD" \
         -H "Content-Type: application/json" \
         -d "{\"password\":\"$KIBANA_PASSWORD\"}" >/dev/null 2>&1 || true

    curl -s -X POST "localhost:9200/_security/user/logstash_system/_password" \
         -u "elastic:$ELASTIC_PASSWORD" \
         -H "Content-Type: application/json" \
         -d "{\"password\":\"$LOGSTASH_PASSWORD\"}" >/dev/null 2>&1 || true

    # 启动所有服务
    log_info "启动所有服务..."
    docker-compose up -d

    log_info "等待服务启动完成..."
    sleep 30

    # 验证服务
    cmd_verify

    log_info "ELK Stack部署完成！"
    echo
    echo -e "${CYAN}访问信息:${NC}"
    echo -e "  🔍 Elasticsearch: ${YELLOW}http://localhost:9200${NC}"
    echo -e "  📊 Kibana: ${YELLOW}http://localhost:5601${NC}"
    echo -e "  🔧 Logstash API: ${YELLOW}http://localhost:9600${NC}"
    echo
    echo -e "${CYAN}登录凭据:${NC}"
    echo -e "  用户名: ${GREEN}$ELASTIC_USER${NC}"
    echo -e "  密码: ${GREEN}$ELASTIC_PASSWORD${NC}"
}

# 启动服务
cmd_start() {
    log_info "启动ELK Stack服务..."
    load_env
    setup_system

    cd "$PROJECT_DIR"
    docker-compose up -d

    log_info "等待服务启动..."
    sleep 15
    cmd_status
}

# 停止服务
cmd_stop() {
    log_info "停止ELK Stack服务..."
    cd "$PROJECT_DIR"
    docker-compose down
    log_info "服务已停止"
}

# 重启服务
cmd_restart() {
    log_info "重启ELK Stack服务..."
    cmd_stop
    sleep 5
    cmd_start
}

# 查看状态
cmd_status() {
    log_info "ELK Stack服务状态:"
    cd "$PROJECT_DIR"
    docker-compose ps
}

# 健康检查
cmd_verify() {
    load_env
    log_info "验证ELK Stack健康状态..."

    # 验证Elasticsearch
    echo -e "\n${CYAN}Elasticsearch:${NC}"
    if elasticsearch_health=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" http://localhost:9200/_cluster/health 2>/dev/null); then
        echo -e "  ✅ 连接成功"
        if command -v jq &> /dev/null; then
            echo "  状态: $(echo $elasticsearch_health | jq -r .status)"
            echo "  节点: $(echo $elasticsearch_health | jq -r .number_of_nodes)"
        fi
    else
        echo -e "  ❌ 连接失败"
    fi

    # 验证Logstash
    echo -e "\n${CYAN}Logstash:${NC}"
    if logstash_status=$(curl -s http://localhost:9600 2>/dev/null); then
        echo -e "  ✅ 连接成功"
        if command -v jq &> /dev/null; then
            echo "  状态: $(echo $logstash_status | jq -r .status)"
        fi
    else
        echo -e "  ❌ 连接失败"
    fi

    # 验证Kibana
    echo -e "\n${CYAN}Kibana:${NC}"
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
        echo -e "  ❌ 连接失败"
    fi

    # 验证Filebeat
    echo -e "\n${CYAN}Filebeat:${NC}"
    if docker-compose ps filebeat | grep -q "Up"; then
        echo -e "  ✅ 服务运行中"
    else
        echo -e "  ❌ 服务未运行"
    fi
}

# 查看日志
cmd_logs() {
    local service="$1"
    cd "$PROJECT_DIR"

    if [ -z "$service" ]; then
        log_info "显示所有服务日志..."
        docker-compose logs --tail=100 -f
    else
        case "$service" in
            elasticsearch|es)
                log_info "显示Elasticsearch日志..."
                docker-compose logs --tail=100 -f elasticsearch
                ;;
            logstash|ls)
                log_info "显示Logstash日志..."
                docker-compose logs --tail=100 -f logstash
                ;;
            kibana|kb)
                log_info "显示Kibana日志..."
                docker-compose logs --tail=100 -f kibana
                ;;
            filebeat|fb)
                log_info "显示Filebeat日志..."
                docker-compose logs --tail=100 -f filebeat
                ;;
            *)
                log_error "未知服务: $service"
                log_info "可用服务: elasticsearch, logstash, kibana, filebeat"
                exit 1
                ;;
        esac
    fi
}

# 清理环境
cmd_cleanup() {
    log_warn "这将删除所有ELK数据，请谨慎操作！"
    echo
    read -p "确认删除所有数据? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        return
    fi

    log_info "停止所有服务..."
    cd "$PROJECT_DIR"
    docker-compose down -v

    log_info "删除数据目录..."
    sudo rm -rf elasticsearch/data/* elasticsearch/logs/*
    sudo rm -rf logstash/logs/*
    sudo rm -rf kibana/data/* kibana/logs/*
    sudo rm -rf filebeat/data/* 2>/dev/null || true

    read -p "是否删除Docker镜像? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "删除Docker镜像..."
        docker rmi "docker.elastic.co/elasticsearch/elasticsearch:${ELK_VERSION}" 2>/dev/null || true
        docker rmi "docker.elastic.co/logstash/logstash:${ELK_VERSION}" 2>/dev/null || true
        docker rmi "docker.elastic.co/kibana/kibana:${ELK_VERSION}" 2>/dev/null || true
        docker rmi "docker.elastic.co/beats/filebeat:${ELK_VERSION}" 2>/dev/null || true
    fi

    log_info "清理完成"
}

# 生成示例日志
cmd_generate_logs() {
    log_info "生成示例日志数据..."
    "$SCRIPT_DIR/generate-sample-logs.sh"
}

# 重置密码
cmd_reset_password() {
    load_env
    local user="${1:-elastic}"

    log_info "重置用户 $user 的密码..."
    read -s -p "请输入新密码: " new_password
    echo

    if [ "$user" = "elastic" ]; then
        docker exec elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -u "$user" -p "$new_password" --batch
    else
        curl -s -X POST "localhost:9200/_security/user/$user/_password" \
             -u "elastic:$ELASTIC_PASSWORD" \
             -H "Content-Type: application/json" \
             -d "{\"password\":\"$new_password\"}"
    fi

    log_info "密码重置完成"
}

# 备份配置和数据
cmd_backup() {
    local backup_dir="$PROJECT_DIR/backups/elk-backup-$(date +%Y%m%d-%H%M%S)"
    log_info "备份ELK配置和数据到: $backup_dir"

    mkdir -p "$backup_dir"

    # 备份配置文件
    cp -r "$PROJECT_DIR"/{elasticsearch,logstash,kibana,filebeat}/config "$backup_dir/" 2>/dev/null || true
    cp "$PROJECT_DIR/docker-compose.yml" "$backup_dir/"
    [ -f "$PROJECT_DIR/.env" ] && cp "$PROJECT_DIR/.env" "$backup_dir/"

    # 备份Elasticsearch数据
    log_info "创建Elasticsearch快照..."
    # 这里可以添加快照创建逻辑

    log_info "备份完成: $backup_dir"
}

# 快速启动（原start-elk-filebeat.sh功能）
cmd_quick_start() {
    log_info "快速启动ELK Stack（轻量级模式）..."

    # 基本环境检查
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装Docker Compose"
        exit 1
    fi

    cd "$PROJECT_DIR"

    # 检查docker-compose文件
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml 文件不存在"
        log_info "请确保在ELK项目根目录运行此脚本"
        exit 1
    fi

    load_env

    log_info "设置目录权限..."
    sudo chown -R 1000:1000 "$PROJECT_DIR/filebeat/data" 2>/dev/null || true
    sudo chown -R 1000:1000 "$PROJECT_DIR/elasticsearch/data" 2>/dev/null || true
    sudo chown -R 1000:1000 "$PROJECT_DIR/kibana/data" 2>/dev/null || true

    log_info "清理旧容器..."
    docker-compose down 2>/dev/null || true

    log_info "启动ELK + Filebeat服务..."
    docker-compose up -d

    log_info "等待服务启动..."
    sleep 20

    log_info "检查服务状态..."
    docker-compose ps

    echo
    echo -e "${GREEN}🎉 ELK + Filebeat 系统启动完成！${NC}"
    echo
    echo -e "${CYAN}📊 访问地址:${NC}"
    echo -e "  Kibana:        ${YELLOW}http://localhost:5601${NC}"
    echo -e "  Elasticsearch: ${YELLOW}http://localhost:9200${NC}"
    echo -e "  Logstash API:  ${YELLOW}http://localhost:9600${NC}"
    echo
    echo -e "${CYAN}🔐 默认凭据:${NC}"
    echo -e "  用户名: ${GREEN}elastic${NC}"
    echo -e "  密码:   ${GREEN}${ELASTIC_PASSWORD}${NC}"
    echo
    echo -e "${CYAN}📋 下一步操作:${NC}"
    echo "  1. 访问 Kibana 创建索引模式"
    echo "  2. 检查 Filebeat 日志收集状态"
    echo "  3. 在 Discover 页面查看日志数据"
    echo
    echo -e "${CYAN}🔧 管理命令:${NC}"
    echo "  完整验证:     ./scripts/elk-manager.sh verify"
    echo "  查看日志:     ./scripts/elk-manager.sh logs [service]"
    echo "  停止服务:     ./scripts/elk-manager.sh stop"
    echo "  生成示例日志: ./scripts/elk-manager.sh generate-logs"
}

# 主函数
main() {
    case "${1:-}" in
        setup)
            cmd_setup
            ;;
        start)
            cmd_start
            ;;
        stop)
            cmd_stop
            ;;
        restart)
            cmd_restart
            ;;
        status)
            cmd_status
            ;;
        verify)
            cmd_verify
            ;;
        logs)
            cmd_logs "$2"
            ;;
        cleanup)
            cmd_cleanup
            ;;
        generate-logs)
            cmd_generate_logs
            ;;
        reset-password)
            cmd_reset_password "$2"
            ;;
        backup)
            cmd_backup
            ;;
        quick-start)
            cmd_quick_start
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
