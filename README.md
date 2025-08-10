# ELK Stack 8.19.1 Docker 部署方案

> 企业级 ELK (Elasticsearch + Logstash + Kibana) 日志分析平台
> 基于 Docker Compose 快速部署，内置安全认证，专为 Spring Boot 应用优化

[![ELK Version](https://img.shields.io/badge/ELK-8.19.1-blue)](https://www.elastic.co/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)

## 特性亮点

- 🔐 **安全认证**: 内置 X-Pack Security，支持用户权限管理
- 🚀 **快速部署**: 一键启动，自动化配置初始化
- 🔧 **高度可配置**: 环境变量配置，支持多环境部署
- 💾 **数据持久化**: 完整的数据卷映射
- 🏥 **健康检查**: 内置服务健康监控和自动重启
- 📈 **Filebeat 集成**: 自动化日志收集，支持多种日志类型
- 🛠️ **统一管理**: 集成管理脚本，简化运维操作

------



## **快速开始**

### **环境要求**

```
    Linux发行版
    Docker 20.10+
    Docker Compose 2.0+
    系统内存 4GB+ (推荐 8GB+)
    磁盘空间 10GB+
```
### 一键部署

```bash
# 1. 首次完整部署（推荐）
./scripts/elk-manager.sh setup

# 2. 或快速启动（轻量级，无完整配置）
./scripts/elk-manager.sh quick-start

# 3. 验证服务状态
./scripts/elk-manager.sh verify

# 4. 生成示例日志数据
./scripts/elk-manager.sh generate-logs
```

### 统一管理脚本

统一的管理脚本 `elk-manager.sh`，支持完整的生命周期管理

```bash
# 查看帮助
./scripts/elk-manager.sh help

# 主要命令
./scripts/elk-manager.sh setup           # 完整部署（首次安装）
./scripts/elk-manager.sh quick-start     # 快速启动（轻量级）
./scripts/elk-manager.sh start           # 启动所有服务
./scripts/elk-manager.sh stop            # 停止所有服务
./scripts/elk-manager.sh restart         # 重启所有服务
./scripts/elk-manager.sh status          # 查看服务状态
./scripts/elk-manager.sh verify          # 健康检查
./scripts/elk-manager.sh logs [service]  # 查看日志
./scripts/elk-manager.sh cleanup         # 清理环境
./scripts/elk-manager.sh reset-password  # 重置密码
```



## **主要文档结构**

```
elk/
├── docker-compose.yml              # Docker Compose 主配置
├── README.md                       # 项目文档
├── .env.example                    # 环境配置模板
├── cookies.txt                     # 认证相关文件
├── elasticsearch/                  # Elasticsearch 配置
│   ├── config/
│   │   └── elasticsearch.yml       # ES 主配置文件
│   ├── data/                       # ES 数据目录（持久化）
│   └── logs/                       # ES 日志目录
├── logstash/                       # Logstash 配置
│   ├── config/
│   │   └── logstash.yml            # Logstash 主配置
│   ├── pipeline/
│   │   └── logstash.conf           # 数据处理管道配置
│   └── logs/                       # Logstash 日志目录
├── kibana/                         # Kibana 配置
│   ├── config/
│   │   └── kibana.yml              # Kibana 主配置
│   ├── data/                       # Kibana 数据目录（持久化）
│   └── logs/                       # Kibana 日志目录
├── filebeat/                       # Filebeat 配置
│   ├── config/
│   │   └── filebeat.yml            # Filebeat 主配置
│   └── data/                       # Filebeat 数据目录
└── scripts/                        # 管理脚本
    ├── elk-manager.sh              # 🆕 统一管理脚本（主要工具）
    ├── cleanup.sh                  # 清理脚本（优化版）
    ├── generate-sample-logs.sh     # 示例日志生成（增强版）
    └── verify.sh                   # 服务验证脚本（优化版）
```

## **服务架构**

| 服务              | 版本   | 端口             | 描述                           |
| ----------------- | ------ | ---------------- | ------------------------------ |
| **Elasticsearch** | 8.19.1 | 9200, 9300       | 分布式搜索引擎，数据存储和检索 |
| **Logstash**      | 8.19.1 | 5044, 5000, 9600 | 数据收集、处理和转发           |
| **Kibana**        | 8.19.1 | 5601             | 数据可视化和管理界面           |
| **Filebeat**      | 8.19.1 | 5066             | 轻量级日志收集器               |

## **数据流向**

```
应用日志 → Logstash → Elasticsearch → Kibana
    ↓          ↓           ↓          ↓
  多协议输入   数据处理    索引存储    可视化展示
```

### **自定义配置**

创建 `.env` 文件进行个性化配置：

```yml
# ELK 版本
ELK_VERSION=8.19.1

# Elasticsearch 配置
ELASTIC_PASSWORD=your_strong_password
ELASTIC_USER=elastic
ES_JAVA_OPTS="-Xms2g -Xmx2g"

# Kibana 配置
KIBANA_PASSWORD=your_kibana_password
KIBANA_USER=kibana_system

# Logstash 配置
LOGSTASH_PASSWORD=your_logstash_password
LOGSTASH_USER=logstash_system
LS_JAVA_OPTS="-Xms1g -Xmx1g"

# 端口配置
ELASTICSEARCH_PORT=9200
KIBANA_PORT=5601
LOGSTASH_BEATS_PORT=5044
LOGSTASH_TCP_PORT=5000
```

### 添加自定义日志源

编辑 `filebeat/config/filebeat.yml`

```yml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /path/to/your/app/logs/*.log
    fields:
      log_type: your_app
      service: your_service
      environment: production
    fields_under_root: true
    multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
    multiline.negate: true
    multiline.match: after
```

重启 Filebeat 使配置生效：

```bash
./scripts/elk-manager.sh restart
# 或者
docker-compose restart filebeat
```



## **服务访问**

### **Elasticsearch REST API**

**访问地址**: [http://localhost:9200](http://localhost:9200/) **认证方式**: HTTP Basic Auth (elastic / your_password)

```
# Elasticsearch 集群状态
curl -u elastic:password "http://localhost:9200/_cluster/health?pretty"

# 节点统计信息
curl -u elastic:password "http://localhost:9200/_nodes/stats?pretty"

# 索引统计信息
curl -u elastic:password "http://localhost:9200/_stats?pretty"

# Logstash 管道统计
curl "http://localhost:9600/_node/stats/pipelines?pretty"
```

### **Kibana 控制台**

**访问地址**: [http://localhost:5601](http://localhost:5601/) **登录账号**: elastic / your_password

### **Logstash 管理API**

**访问地址**: [http://localhost:9600](http://localhost:9600/) **主要端点**: `/_node/stats`, `/_node/plugins`

## **数据输入配置**

### **支持的输入协议**

| **协议** | **端口** |        **用途**         |  **数据格式**   |
| :------: | :------: | :---------------------: | :-------------: |
|  Beats   |   5044   | Filebeat, Metricbeat 等 | Binary Protocol |
|   TCP    |   5000   |      应用直接发送       |   JSON Lines    |
|   UDP    |   5000   |   Syslog, 高并发场景    |   JSON Lines    |
|   HTTP   |   8080   |      REST API 收集      |      JSON       |

## **安全配置**

### **内置用户账号**

|   **用户名**    |     **用途**      |  **默认密码**  |
| :-------------: | :---------------: | :------------: |
|     elastic     |    超级管理员     | elastic123456  |
|  kibana_system  |  Kibana 服务账号  |  kibana123456  |
| logstash_system | Logstash 服务账号 | logstash123456 |

**生产环境建议**：修改 `.env` 文件中的默认密码

## 运维管理

### 日常运维命令

```bash
# 服务管理
./scripts/elk-manager.sh start          # 启动服务
./scripts/elk-manager.sh stop           # 停止服务
./scripts/elk-manager.sh restart        # 重启服务
./scripts/elk-manager.sh status         # 查看状态

# 健康检查
./scripts/elk-manager.sh verify         # 全面健康检查
./scripts/verify.sh                     # 快速状态验证

# 日志管理
./scripts/elk-manager.sh logs           # 查看所有服务日志
./scripts/elk-manager.sh logs elasticsearch  # 查看ES日志
./scripts/elk-manager.sh logs logstash       # 查看Logstash日志
./scripts/elk-manager.sh logs kibana         # 查看Kibana日志
./scripts/elk-manager.sh logs filebeat       # 查看Filebeat日志

# 数据管理
./scripts/elk-manager.sh generate-logs  # 生成测试数据
./scripts/elk-manager.sh backup         # 备份配置和数据
./scripts/elk-manager.sh cleanup        # 清理环境
```

### 监控和警报

#### 关键指标监控

```bash
# Elasticsearch 集群状态
curl -u elastic:password "http://localhost:9200/_cluster/health?pretty"

# 节点统计信息
curl -u elastic:password "http://localhost:9200/_nodes/stats?pretty"

# 索引统计信息
curl -u elastic:password "http://localhost:9200/_stats?pretty"

# Logstash 管道统计
curl "http://localhost:9600/_node/stats/pipelines?pretty"
```

## 故障排除

### 常见问题及解决方案

#### 1. 容器启动失败

```bash
# 检查服务日志
./scripts/elk-manager.sh logs
./scripts/elk-manager.sh logs elasticsearch

# 检查资源使用情况
docker stats

# 检查端口占用
ss -tuln | grep -E ":(9200|9300|5601|5044|5000|9600)"
```

#### 2. 内存不足错误

```bash
# 编辑 .env 文件，减少 JVM 堆内存
ES_JAVA_OPTS=-Xms1g -Xmx1g
LS_JAVA_OPTS=-Xms512m -Xmx512m

# 检查系统内存
free -h

# 重启服务
./scripts/elk-manager.sh restart
```

#### 3. Elasticsearch 连接失败

```bash
# 检查服务状态
./scripts/elk-manager.sh verify

# 重置elastic用户密码
./scripts/elk-manager.sh reset-password elastic

# 检查防火墙设置
sudo ufw status
```

#### 4. Filebeat 无法发送日志

```bash
# 检查Filebeat状态
./scripts/elk-manager.sh logs filebeat

# 验证日志文件路径
ls -la /path/to/log/files/

# 检查文件权限
sudo chown -R 1000:1000 ./filebeat/data
```

#### 5. Kibana 无法访问

```bash
# 检查Kibana日志
./scripts/elk-manager.sh logs kibana

# 等待Kibana完全启动（可能需要2-3分钟）
curl -I http://localhost:5601

# 清理Kibana数据重新初始化
sudo rm -rf ./kibana/data/*
./scripts/elk-manager.sh restart
```
