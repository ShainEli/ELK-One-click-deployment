# Spring Boot ELK Demo - Spring Boot 日志收集演示

## 项目概述

这是一个使用 Spring Boot 3.5.4 和 JDK 21 构建的演示项目，用于展示 Spring 应用程序的日志收集功能。该项目生成结构化的 JSON 格式日志，便于与 ELK Stack (Elasticsearch, Logstash, Kibana) 集成。

## 技术栈

- **Spring Boot**: 3.5.4
- **Java**: JDK 21
- **数据库**: H2 (内存数据库)
- **日志框架**: Logback + logstash-logback-encoder
- **构建工具**: Maven
- **容器化**: Docker (可选)

## 功能特性

### 1. JSON 格式日志输出
- 所有日志都以结构化的 JSON 格式输出
- 包含时间戳、日志级别、服务名称、环境信息等元数据
- 支持自定义字段如 traceId、userId、operation 等

### 2. API 端点

#### `/api/hello` (GET)
- 基础的问候端点
- 参数：`name` (可选)
- 生成带有 traceId 的日志

#### `/api/health` (GET)
- 自定义健康检查端点
- 返回服务状态、JVM 信息和 traceId

#### `/api/generate-logs` (GET)
- 生成多种类型的示例日志
- 参数：`count` (默认10), `logLevel` (默认all)
- 模拟不同的业务操作和日志级别

#### `/api/simulate-error` (POST)
- 模拟各种类型的错误
- 请求体：`{"errorType": "database|network|validation|timeout"}`
- 生成错误日志用于测试

#### `/actuator/health` (GET)
- Spring Boot Actuator 健康检查
- 返回详细的组件状态信息

### 3. 日志特性
- **结构化**: JSON 格式，便于解析和搜索
- **追踪**: 每个请求都有唯一的 traceId
- **上下文**: 包含用户ID、操作类型、响应时间等业务信息
- **多级别**: 支持 DEBUG、INFO、WARN、ERROR 等日志级别

## 快速开始

### 1. 构建项目
```bash
./run.sh build
```

### 2. 运行应用
```bash
./run.sh run
```

### 3. 测试 API
```bash
./test-api.sh
```

## API 测试示例

```bash
# 基础问候
curl "http://localhost:8080/api/hello?name=ELKDemo"

# 健康检查
curl "http://localhost:8080/api/health"

# 生成日志
curl "http://localhost:8080/api/generate-logs?count=5&logLevel=info"

# 模拟错误
curl -X POST -H "Content-Type: application/json"
     -d '{"errorType":"database"}'
     "http://localhost:8080/api/simulate-error"

# Actuator 健康检查
curl "http://localhost:8080/actuator/health"
```

## 日志格式示例

```json
{
  "@timestamp": "2025-08-10T07:02:00.289003521Z",
  "@version": "1",
  "message": "Database connection error occurred",
  "logger": "com.example.elkspringdemo.controller.DemoController",
  "thread": "http-nio-8080-exec-4",
  "level": "ERROR",
  "level_value": 40000,
  "traceId": "1ef31790-a405-4a8c-8025-2e0fd3060d0e",
  "operation": "simulate-error",
  "service": "elk-spring-demo",
  "environment": "development"
}
```

## 与 ELK Stack 集成

### 方式一：文件采集 (推荐)
1. 配置 Filebeat 监控日志文件 `logs/spring-demo.log`
2. Filebeat 将日志发送到 Elasticsearch 或 Logstash
3. 在 Kibana 中创建索引模式和仪表板

### 方式二：直接发送到 Logstash
项目已配置 Logstash TCP appender (默认关闭)，可通过修改 `logback-spring.xml` 启用：
```xml
<appender-ref ref="LOGSTASH"/>
```

## 项目结构

```
spring-demo/
├── src/main/java/com/example/elkspringdemo/
│   ├── ElkSpringDemoApplication.java     # 主启动类
│   ├── controller/
│   │   └── DemoController.java           # REST API 控制器
│   ├── service/
│   │   └── LogGeneratorService.java      # 日志生成服务
│   ├── entity/
│   │   └── UserActivity.java             # JPA 实体
│   ├── repository/
│   │   └── UserActivityRepository.java   # 数据访问层
│   └── config/
│       └── AsyncConfig.java              # 异步配置
├── src/main/resources/
│   ├── application.properties            # 应用配置
│   └── logback-spring.xml               # 日志配置
├── logs/                                 # 日志文件输出目录
├── run.sh                               # 构建运行脚本
├── test-api.sh                          # API 测试脚本
└── pom.xml                              # Maven 依赖配置
```

## 配置说明

### 应用配置 (application.properties)
- 服务端口：8080
- 数据库：H2 内存数据库
- 日志级别：DEBUG (开发环境)
- Actuator 端点：启用健康检查

### 日志配置 (logback-spring.xml)
- JSON 格式输出
- 文件和控制台双重输出
- 可选的 Logstash TCP 发送
- 自定义字段支持

## 监控指标

项目通过日志记录了以下关键指标：
- **请求追踪**: 每个 API 请求的完整生命周期
- **性能监控**: 响应时间、JVM 内存使用
- **错误追踪**: 异常堆栈、错误上下文
- **业务指标**: 用户操作、数据处理状态

## 开发说明

### 添加新的日志字段
在 `logback-spring.xml` 中的 `JsonProvider` 部分添加自定义字段：
```xml
<customFields>{"service":"elk-spring-demo","environment":"development"}</customFields>
```

### 扩展 API 端点
在 `DemoController` 中添加新的端点，确保包含适当的日志记录。

### 集成测试
运行 `test-api.sh` 脚本可以快速验证所有端点是否正常工作。

## 故障排除

1. **应用启动失败**: 检查 JDK 版本是否为 21
2. **日志文件不生成**: 确认 `logs/` 目录权限
3. **API 请求失败**: 检查应用是否在 8080 端口正常启动
4. **JSON 格式错误**: 验证 logback 配置是否正确

---

*该项目是一个完整的 Spring Boot 日志收集演示，可以直接用于 ELK Stack 集成测试。
