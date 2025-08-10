# Spring Boot ELK 日志收集Demo - 快速开始指南

## 🎯 项目概述

这是一个完整的Spring Boot 3.5.4 + JDK 21应用示例，专门用于演示如何与ELK Stack集成进行日志收集和分析。项目包含了完整的日志记录、链路追踪、错误模拟和性能监控功能。

## 🚀 一键启动

### 方式1：集成启动（推荐）
```bash
# 启动ELK Stack + Spring Boot Demo
./start-demo.sh start

# 生成测试日志
./start-demo.sh logs

# 查看服务状态
./start-demo.sh status
```

### 方式2：分步启动
```bash
# 1. 启动ELK Stack
./scripts/elk-manager.sh setup

# 2. 构建并启动Spring Boot应用
cd spring-demo
./run.sh setup

# 3. 生成测试日志
./test-api.sh all
```

## 📊 访问地址

| 服务 | 地址 | 用途 |
|------|------|------|
| Spring Boot应用 | http://localhost:8080 | 主应用 |
| 健康检查 | http://localhost:8080/actuator/health | 应用状态 |
| H2 数据库控制台 | http://localhost:8080/h2-console | 数据库管理 |
| Kibana | http://localhost:5601 | 日志分析 |
| Elasticsearch | http://localhost:9200 | 数据存储 |

**默认登录信息：**
- Kibana用户名：`elastic`
- Kibana密码：`elastic123456`

## 🔧 核心功能

### API接口测试
```bash
# 基础功能测试
curl "http://localhost:8080/api/hello?name=测试用户"

# 生成不同级别的日志
curl "http://localhost:8080/api/generate-logs?count=20&logLevel=all"

# 模拟错误（用于测试错误日志）
curl -X POST "http://localhost:8080/api/simulate-error" \
     -H "Content-Type: application/json" \
     -d '{"errorType":"runtime"}'

# 健康检查
curl "http://localhost:8080/api/health"
```

### 日志特性
- ✅ **结构化日志**：JSON格式，便于ELK解析
- ✅ **链路追踪**：使用MDC记录traceId和业务信息
- ✅ **多级别日志**：DEBUG/INFO/WARN/ERROR完整覆盖
- ✅ **双重输出**：文件日志 + 直接TCP发送到Logstash
- ✅ **异常处理**：完整的错误日志和堆栈信息

### 日志输出格式示例
```json
{
  "@timestamp": "2025-08-10T10:30:45.123Z",
  "level": "INFO",
  "thread": "http-nio-8080-exec-1",
  "logger": "com.example.elkspringdemo.controller.DemoController",
  "message": "Received hello request for name: 测试用户",
  "traceId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "user-123",
  "operation": "HELLO_REQUEST",
  "service": "elk-spring-demo",
  "environment": "development"
}
```

## 📈 在Kibana中查看日志

### 1. 创建索引模式
1. 访问 http://localhost:5601
2. 登录（elastic/elastic123456）
3. 进入 "Stack Management" → "Index Patterns"
4. 创建索引模式：`spring-boot-logs-*` 或 `filebeat-*`

### 2. 常用查询
```json
# 查看Spring Boot应用日志
service:"elk-spring-demo"

# 查看错误日志
level:"ERROR" AND service:"elk-spring-demo"

# 追踪特定用户的操作
userId:"user-123"

# 查看特定操作类型
operation:"HELLO_REQUEST"

# 时间范围查询
@timestamp:[now-1h TO now] AND service:"elk-spring-demo"
```

### 3. 创建仪表板
- 日志级别分布饼图
- 请求量时间趋势图
- 错误率监控
- 响应时间统计
- 用户活动热力图

## 🛠️ 开发和扩展

### 添加自定义日志
```java
@RestController
public class CustomController {
    private static final Logger logger = LoggerFactory.getLogger(CustomController.class);

    @GetMapping("/custom")
    public ResponseEntity<?> customMethod() {
        String traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        MDC.put("operation", "CUSTOM_OPERATION");

        try {
            logger.info("执行自定义操作");
            // 业务逻辑...
            return ResponseEntity.ok("成功");
        } catch (Exception e) {
            logger.error("自定义操作失败", e);
            return ResponseEntity.internalServerError().body("失败");
        } finally {
            MDC.clear();
        }
    }
}
```

### 修改日志配置
编辑 `src/main/resources/logback-spring.xml`：
```xml
<!-- 添加自定义字段 -->
<customFields>{"service":"your-service","version":"2.0.0"}</customFields>

<!-- 修改Logstash地址 -->
<destination>your-logstash-host:5000</destination>
```

## 🔍 故障排除

### 常见问题
1. **应用无法连接Logstash**
   ```bash
   # 检查Logstash是否监听5000端口
   netstat -an | grep 5000
   telnet localhost 5000
   ```

2. **Kibana中看不到日志**
   ```bash
   # 检查Elasticsearch索引
   curl "http://localhost:9200/_cat/indices?v"

   # 检查Logstash日志
   docker-compose logs logstash
   ```

3. **Spring Boot应用启动失败**
   ```bash
   # 检查Java版本
   java -version  # 需要JDK 21

   # 检查端口占用
   lsof -i :8080
   ```

### 调试模式
```bash
# 启用详细日志
export LOGGING_LEVEL_COM_EXAMPLE_ELKSPRINGDEMO=DEBUG
./run.sh run

# 查看应用日志
tail -f logs/spring-demo.log
```

## 📝 项目结构

```
spring-demo/
├── src/main/java/com/example/elkspringdemo/
│   ├── ElkSpringDemoApplication.java          # 启动类
│   ├── controller/DemoController.java         # REST控制器
│   ├── service/LogGeneratorService.java       # 日志生成服务
│   ├── entity/UserActivity.java              # 数据实体
│   └── repository/UserActivityRepository.java # 数据访问
├── src/main/resources/
│   ├── application.properties                 # 应用配置
│   └── logback-spring.xml                    # 日志配置
├── run.sh                                    # 构建运行脚本
├── test-api.sh                               # API测试脚本
└── README.md                                 # 详细文档
```

## 📚 相关文档

- [Spring Boot官方文档](https://spring.io/projects/spring-boot)
- [Logback配置指南](https://logback.qos.ch/manual/configuration.html)
- [ELK Stack文档](https://www.elastic.co/guide/)
- [详细README](./spring-demo/README.md)

---

**祝您使用愉快！如有问题，请查看详细文档或提交Issue。** 🎉
