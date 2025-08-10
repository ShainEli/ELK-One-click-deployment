#!/bin/bash

# ELK Stack 清理脚本

set -e

echo "开始清理 ELK Stack..."

# 停止服务
echo "停止服务..."
docker-compose down

# 询问是否删除数据
read -p "是否删除所有数据? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "删除数据目录..."
    sudo rm -rf elasticsearch/data/*
    sudo rm -rf elasticsearch/logs/*
    sudo rm -rf logstash/logs/*
    sudo rm -rf kibana/data/*
    sudo rm -rf kibana/logs/*
    
    # 删除 Docker 卷
    docker-compose down -v
    
    echo "数据已清理"
else
    echo "保留数据"
fi

# 询问是否删除镜像
read -p "是否删除 Docker 镜像? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "删除 Docker 镜像..."
    docker rmi docker.elastic.co/elasticsearch/elasticsearch:8.19.1 || true
    docker rmi docker.elastic.co/logstash/logstash:8.19.1 || true
    docker rmi docker.elastic.co/kibana/kibana:8.19.1 || true
    echo "镜像已删除"
fi

echo "清理完成!"