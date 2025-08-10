#!/bin/bash

# ELK Stack 状态验证脚本

set -e

echo "=== ELK Stack 状态验证 ==="
echo

# 设置密码（直接使用，避免.env文件格式问题）
ELASTIC_PASSWORD="elastic123456"
ELASTIC_USER="elastic"

echo "🔍 检查容器状态..."
docker-compose ps
echo

echo "🔧 验证服务连接..."

# 验证 Elasticsearch
echo "1. Elasticsearch 状态:"
if elasticsearch_health=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" http://localhost:9200/_cluster/health 2>/dev/null); then
    echo "   ✅ 连接成功"
    echo "   集群状态: $(echo $elasticsearch_health | jq -r .status)"
    echo "   节点数量: $(echo $elasticsearch_health | jq -r .number_of_nodes)"
else
    echo "   ❌ 连接失败"
fi

# 验证 Logstash
echo "2. Logstash 状态:"
if logstash_status=$(curl -s http://localhost:9600 2>/dev/null); then
    echo "   ✅ 连接成功"
    echo "   状态: $(echo $logstash_status | jq -r .status)"
    echo "   版本: $(echo $logstash_status | jq -r .version)"
else
    echo "   ❌ 连接失败"
fi

# 验证 Kibana
echo "3. Kibana 状态:"
if kibana_status=$(curl -s http://localhost:5601/api/status 2>/dev/null); then
    overall_status=$(echo $kibana_status | jq -r '.status.overall.level')
    if [ "$overall_status" = "available" ]; then
        echo "   ✅ 服务可用"
    else
        echo "   ⚠️  状态: $overall_status"
    fi
else
    echo "   ❌ 连接失败"
fi

echo

echo "📊 索引信息:"
if curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "http://localhost:9200/_cat/indices?v" 2>/dev/null | head -10; then
    echo ""
else
    echo "   无法获取索引信息"
fi

echo
echo "🌐 访问地址:"
echo "   Elasticsearch: http://localhost:9200"
echo "     用户名: $ELASTIC_USER"
echo "     密码: $ELASTIC_PASSWORD"
echo "   Kibana: http://localhost:5601"
echo "     用户名: $ELASTIC_USER"
echo "     密码: $ELASTIC_PASSWORD"
echo "   Logstash API: http://localhost:9600"

echo
echo "=== 验证完成 ==="
