# ELK Stack 8.19.1 Docker 部署方案

> 基于 Docker Compose 快速部署, 企业级 ELK (Elasticsearch + Logstash + Kibana) 日志分析平台

[![ELK Version](https://img.shields.io/badge/ELK-8.19.1-blue)](https://www.elastic.co/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)

## ✨特性亮点

- 🔐 **安全认证**: 内置 X-Pack Security，支持用户权限管理
- 🚀 **快速部署**: 一键启动，自动化配置初始化
- 📊 **Spring Boot 优化**: 专门针对 Spring Boot 日志格式优化
- 🔧 **高度可配置**: 环境变量配置，支持多环境部署
- 💾 **数据持久化**: 完整的数据卷映射
- 🏥 **健康检查**: 内置服务健康监控和自动重启
- 🌐 **多协议支持**: TCP/UDP/HTTP/Beats 多种数据输入方式

------



## **快速开始**

### **环境要求**

``` text
    Linux发行版
    Docker 20.10+
    Docker Compose 2.0+
    系统内存 4GB+ (推荐 8GB+)
    磁盘空间 10GB+
```
## **项目结构**

``` text
elk/
├── docker-compose.yml              # Docker Compose 主配置
├── README.md                       # 项目文档
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
└── scripts/                        # 管理脚本
    ├── cleanup.sh                  # 清理脚本
    ├── setup-complete.sh           # 完整设置脚本
    └── verify.sh                   # 服务验证脚本
```

## **服务架构**

|   **服务**    | **版本** |     **端口**     | **描述**                       |
| :-----------: | :------: | :--------------: | ------------------------------ |
| Elasticsearch |  8.19.1  |    9200, 9300    | 分布式搜索引擎，数据存储和检索 |
|   Logstash    |  8.19.1  | 5044, 5000, 9600 | 数据收集、处理和转发           |
|    Kibana     |  8.19.1  |       5601       | 数据可视化和管理界面           |

## **数据流向**

``` text
应用日志 → Logstash → Elasticsearch → Kibana
    ↓          ↓           ↓          ↓
  多协议输入   数据处理    索引存储    可视化展示
```

### **一键部署**

``` bash
# 1. 启动 ELK Stack
./scripts/setup-complete.sh

# 2. 验证服务状态
./scripts/verify.sh
```

### **自定义配置**

创建 `.env` 文件进行个性化配置：

``` bash
# ELK 版本
ELK_VERSION=8.19.1

# Elasticsearch 配置
ELASTIC_PASSWORD=your_strong_password
ELASTIC_USER=elastic
ES_JAVA_OPTS=-Xms2g -Xmx2g

# Kibana 配置
KIBANA_PASSWORD=your_kibana_password
KIBANA_USER=kibana_system

# Logstash 配置
LOGSTASH_PASSWORD=your_logstash_password
LOGSTASH_USER=logstash_system
LS_JAVA_OPTS=-Xms1g -Xmx1g

# 端口配置
ELASTICSEARCH_PORT=9200
KIBANA_PORT=5601
LOGSTASH_BEATS_PORT=5044
LOGSTASH_TCP_PORT=5000
```

## **服务访问**

### **Elasticsearch REST API**

**访问地址**: [http://localhost:9200](http://localhost:9200/) **认证方式**: HTTP Basic Auth (elastic / your_password)

``` bash
# 集群健康状态
curl -u elastic:your_password http://localhost:9200/_cluster/health

# 索引列表
curl -u elastic:your_password http://localhost:9200/_cat/indices?v
```

### **Kibana 控制台**

**访问地址**: [http://localhost:5601](http://localhost:5601/) **登录账号**: `elastic/your_password`

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

### **Logback 配置 (logback-spring.xml)**

``` xml
<configuration>
    <appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
        <destination>localhost:5000</destination>
        <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <providers>
                <timestamp/>
                <logLevel/>
                <loggerName/>
                <message/>
                <mdc/>
                <stackTrace/>
            </providers>
        </encoder>
        <customFields>{"app_name":"your-app","env":"production"}</customFields>
    </appender>

    <root level="INFO">
        <appender-ref ref="LOGSTASH"/>
    </root>
</configuration>
```

### **依赖添加 (pom.xml)**

``` xml
<dependency>

    <groupId>net.logstash.logback</groupId>

    <artifactId>logstash-logback-encoder</artifactId>

    <version>7.4</version>

</dependency>
```

## **管理脚本**

### **verify.sh - 服务验证**

``` bash
# 检查容器运行状态，验证服务连通性，显示集群健康信息
./scripts/verify.sh
```

### **cleanup.sh - 环境清理**

``` bash
# 停止所有服务，可选删除数据卷，清理日志文件
./scripts/cleanup.sh
```

### **setup-complete.sh - 完整部署**

``` bash
# 完整的环境初始化和自动配置
./scripts/setup-complete.sh
```

## **安全配置**

### **内置用户账号**

|   **用户名**    |     **用途**      |  **默认密码**  |
| :-------------: | :---------------: | :------------: |
|     elastic     |    超级管理员     | elastic123456  |
|  kibana_system  |  Kibana 服务账号  |  kibana123456  |
| logstash_system | Logstash 服务账号 | logstash123456 |

**生产环境建议**：修改 `.env` 文件中的默认密码

## **故障排除**

### **常见问题**

#### **容器启动失败**

``` bash
# 检查日志
docker-compose logs elasticsearch
docker-compose logs logstash
docker-compose logs kibana
```

#### **内存不足**

``` bash
# 编辑 .env 文件，减少 JVM 堆内存
ES_JAVA_OPTS=-Xms1g -Xmx1g
LS_JAVA_OPTS=-Xms512m -Xmx512
```

#### **认证失败**

``` bash
# 重置密码
docker exec -it elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```

#### **日志文件位置**

- Elasticsearch: `./elasticsearch/logs/elk-cluster.log`
- Logstash: `./logstash/logs/logstash-plain.log`
- Kibana: `./kibana/logs/kibana.log`

## **性能优化**

### **内存调优**

``` bash
# .env 文件中调整 JVM 堆内存
ES_JAVA_OPTS=-Xms4g -Xmx4g  # 建议设置为物理内存的一半
LS_JAVA_OPTS=-Xms2g -Xmx2g
```
