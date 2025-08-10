#!/bin/bash

# ELK Stack 完整部署脚本
# 包含基础设置和安全配置
# 适用于 Linux 系统

set -e

echo "=== ELK Stack 完整部署脚本 ==="
echo "此脚本将完成ELK Stack的部署和安全配置"
echo

# 检查 Docker 和 Docker Compose
echo "1. 检查系统环境..."
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose 未安装"
    exit 1
fi

# 检查jq是否安装（用于JSON解析）
if ! command -v jq &> /dev/null; then
    echo "警告: jq 未安装，某些输出可能不够格式化"
fi

echo "   系统环境检查完成"

# 加载环境变量
echo "2. 加载配置..."
# 查找 .env 文件的函数
find_env_file() {
    local current_dir="$(pwd)"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # 首先检查当前目录
    if [ -f "$current_dir/.env" ]; then
        echo "$current_dir/.env"
        return 0
    fi

    # 检查脚本所在目录的上级目录（项目根目录）
    if [ -f "$script_dir/../.env" ]; then
        echo "$script_dir/../.env"
        return 0
    fi

    # 检查脚本所在目录
    if [ -f "$script_dir/.env" ]; then
        echo "$script_dir/.env"
        return 0
    fi

    return 1
}

# 查找并加载 .env 文件
env_file=$(find_env_file)
if [ $? -eq 0 ]; then
    # 安全地加载 .env 文件，避免执行带空格的变量值
    set -a  # 自动导出变量
    while IFS= read -r line; do
        # 跳过注释行和空行
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]]; then
            # 处理带空格的变量值，使用 eval 安全加载
            if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
                var_name="${BASH_REMATCH[1]}"
                var_value="${BASH_REMATCH[2]}"
                # 去除变量名前后的空格
                var_name=$(echo "$var_name" | xargs)
                # 导出变量
                export "$var_name"="$var_value"
            fi
        fi
    done < "$env_file"
    set +a  # 停止自动导出
    echo "   已加载配置文件: $env_file"
else
    echo "   警告: 未找到 .env 文件，使用默认密码"
fi

# 设置默认密码
ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-elastic123456}
KIBANA_PASSWORD=${KIBANA_PASSWORD:-kibana123456}
LOGSTASH_PASSWORD=${LOGSTASH_PASSWORD:-logstash123456}
ELASTIC_USER=${ELASTIC_USER:-elastic}

echo "   配置加载完成"

# 设置系统参数
echo "3. 设置系统参数..."
sudo sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf >/dev/null
echo "   系统参数设置完成"

# 创建必要的目录
echo "4. 创建数据目录..."
mkdir -p elasticsearch/data elasticsearch/logs
mkdir -p logstash/logs
mkdir -p kibana/data kibana/logs
echo "   数据目录创建完成"

# 设置目录权限
echo "5. 设置目录权限..."
sudo chown -R 1000:1000 elasticsearch/
sudo chown -R 1000:1000 logstash/
sudo chown -R 1000:1000 kibana/
echo "   目录权限设置完成"

# 检查端口占用
echo "6. 检查端口占用..."
ports=(9200 9300 5044 5000 9600 5601)
for port in "${ports[@]}"; do
    if ss -tuln | grep ":$port " > /dev/null 2>&1; then
        echo "   警告: 端口 $port 已被占用"
    fi
done
echo "   端口检查完成"

# 停止现有服务
echo "7. 停止现有服务..."
docker-compose down >/dev/null 2>&1 || true
echo "   现有服务已停止"

# 清理旧数据（可选）
echo "8. 数据清理选项..."
read -p "   是否清理现有Elasticsearch数据? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   清理现有数据..."
    sudo rm -rf elasticsearch/data/*
    echo "   数据已清理"
else
    echo "   保留现有数据"
fi

# 启动Elasticsearch并等待就绪
echo "9. 启动Elasticsearch..."
docker-compose up -d elasticsearch

echo "   等待Elasticsearch启动..."
for i in {1..60}; do
    if curl -s http://localhost:9200 >/dev/null 2>&1; then
        echo "   Elasticsearch已启动"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "   错误: Elasticsearch启动超时"
        exit 1
    fi
    sleep 2
    printf "."
done
echo

# 设置内置用户密码
echo "10. 设置安全配置..."

# 设置elastic用户密码
echo "    设置elastic用户密码..."
docker exec elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -p $ELASTIC_PASSWORD --batch >/dev/null 2>&1 || {
    echo "    使用API设置elastic密码..."
    curl -s -X POST "localhost:9200/_security/user/elastic/_password" \
         -H "Content-Type: application/json" \
         -d "{\"password\":\"$ELASTIC_PASSWORD\"}" >/dev/null 2>&1 || true
}

# 等待一下确保密码生效
sleep 5

# 设置kibana_system用户密码
echo "    设置kibana_system用户密码..."
curl -s -X POST "localhost:9200/_security/user/kibana_system/_password" \
     -u "elastic:$ELASTIC_PASSWORD" \
     -H "Content-Type: application/json" \
     -d "{\"password\":\"$KIBANA_PASSWORD\"}" >/dev/null 2>&1 || {
    echo "    kibana_system密码设置可能失败，继续..."
}

# 设置logstash_system用户密码
echo "    设置logstash_system用户密码..."
curl -s -X POST "localhost:9200/_security/user/logstash_system/_password" \
     -u "elastic:$ELASTIC_PASSWORD" \
     -H "Content-Type: application/json" \
     -d "{\"password\":\"$LOGSTASH_PASSWORD\"}" >/dev/null 2>&1 || {
    echo "    logstash_system密码设置可能失败，继续..."
}

echo "    安全配置完成"

# 启动所有服务
echo "11. 启动所有ELK服务..."
docker-compose up -d

echo "    等待所有服务启动..."
sleep 30

# 检查服务状态
echo "12. 检查服务状态..."
echo "    Docker容器状态:"
docker-compose ps

echo

# 验证服务
echo "13. 验证服务..."

echo "    验证Elasticsearch..."
if curl -f -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" http://localhost:9200/_cluster/health >/dev/null 2>&1; then
    echo "    ✓ Elasticsearch 运行正常"
    if command -v jq &> /dev/null; then
        echo "    集群健康状态:"
        curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" http://localhost:9200/_cluster/health | jq .
    fi
else
    echo "    ✗ Elasticsearch 未就绪"
fi

echo "    验证Logstash..."
if curl -f -s http://localhost:9600 >/dev/null 2>&1; then
    echo "    ✓ Logstash 运行正常"
else
    echo "    ✗ Logstash 未就绪"
fi

echo "    验证Kibana..."
# 等待Kibana完全启动
for i in {1..30}; do
    if curl -f -s http://localhost:5601/login >/dev/null 2>&1 || curl -f -s http://localhost:5601/api/status >/dev/null 2>&1; then
        echo "    ✓ Kibana 运行正常"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "    ⚠ Kibana 可能仍在启动中，请稍后访问"
    fi
    sleep 2
done

echo
echo "=== ELK Stack 部署完成! ==="
echo
echo "访问信息:"
echo "  🔍 Elasticsearch: http://localhost:9200"
echo "    用户名: $ELASTIC_USER"
echo "    密码: $ELASTIC_PASSWORD"
echo
echo "  📊 Kibana: http://localhost:5601"
echo "    用户名: $ELASTIC_USER"
echo "    密码: $ELASTIC_PASSWORD"
echo
echo "  🔧 Logstash API: http://localhost:9600"
echo
echo "📝 重要提醒:"
echo "  - 请妥善保管用户名和密码信息"
echo "  - 首次访问Kibana时，使用elastic用户登录"
echo "  - 建议在生产环境中修改默认密码"
echo "  - 可以通过 'docker-compose logs <service>' 查看服务日志"
echo
echo "🚀 ELK Stack 已准备就绪！"
