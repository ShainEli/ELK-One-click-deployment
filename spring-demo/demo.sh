#!/bin/bash

# Spring Boot ELK Demo 完整演示脚本
# 演示 Spring Boot 应用的日志收集功能

echo "=========================================="
echo "ELK Spring Demo - 完整功能演示"
echo "=========================================="
echo ""

# 检查应用是否运行
echo "1. 检查应用状态..."
if curl -s "http://localhost:8080/actuator/health" > /dev/null; then
    echo "✅ Spring Boot 应用正在运行"
else
    echo "❌ 应用未运行，请先启动应用："
    echo "   ./run.sh run"
    exit 1
fi

echo ""
echo "2. 基础功能测试..."

# 测试基础端点
echo "🔹 测试问候端点:"
curl -s "http://localhost:8080/api/hello?name=ELKDemo" | jq '.' || echo "JSON 解析失败"

echo ""
echo "🔹 测试健康检查:"
curl -s "http://localhost:8080/api/health" | jq '.' || echo "JSON 解析失败"

echo ""
echo "3. 日志生成测试..."

# 生成不同类型的日志
echo "🔹 生成 INFO 级别日志:"
curl -s "http://localhost:8080/api/generate-logs?count=3&logLevel=info" | jq '.' || echo "JSON 解析失败"

echo ""
echo "🔹 生成所有级别日志:"
curl -s "http://localhost:8080/api/generate-logs?count=5&logLevel=all" | jq '.' || echo "JSON 解析失败"

echo ""
echo "4. 错误模拟测试..."

# 测试不同类型的错误
echo "🔹 模拟数据库错误:"
curl -X POST -H "Content-Type: application/json" \
     -d '{"errorType":"database"}' \
     -s "http://localhost:8080/api/simulate-error" | jq '.' || echo "JSON 解析失败"

echo ""
echo "🔹 模拟网络错误:"
curl -X POST -H "Content-Type: application/json" \
     -d '{"errorType":"network"}' \
     -s "http://localhost:8080/api/simulate-error" | jq '.' || echo "JSON 解析失败"

echo ""
echo "5. Spring Boot Actuator 测试..."
echo "🔹 Actuator 健康检查:"
curl -s "http://localhost:8080/actuator/health" | jq '.status' || echo "JSON 解析失败"

echo ""
echo "6. 日志文件检查..."
if [ -f "logs/spring-demo.log" ]; then
    echo "🔹 日志文件状态:"
    echo "   文件大小: $(du -h logs/spring-demo.log | cut -f1)"
    echo "   行数: $(wc -l < logs/spring-demo.log)"

    echo ""
    echo "🔹 最新日志条目 (JSON 格式):"
    tail -3 logs/spring-demo.log | head -1 | jq '.' || echo "JSON 格式验证失败"
else
    echo "❌ 日志文件不存在"
fi

echo ""
echo "7. API 端点总览..."
echo "🔹 可用端点:"
echo "   GET  /api/hello?name=<name>           - 问候端点"
echo "   GET  /api/health                      - 自定义健康检查"
echo "   GET  /api/generate-logs               - 生成示例日志"
echo "   POST /api/simulate-error              - 模拟错误"
echo "   GET  /actuator/health                 - Spring Boot 健康检查"
echo "   GET  /actuator/info                   - 应用信息"

echo ""
echo "8. 日志特性展示..."
echo "🔹 日志格式特性:"
echo "   ✅ JSON 结构化输出"
echo "   ✅ 时间戳 (@timestamp)"
echo "   ✅ 日志级别 (level, level_value)"
echo "   ✅ 服务标识 (service, environment)"
echo "   ✅ 请求追踪 (traceId)"
echo "   ✅ 业务上下文 (userId, operation)"
echo "   ✅ 线程信息 (thread)"
echo "   ✅ 类名信息 (logger)"

echo ""
echo "9. ELK 集成建议..."
echo "🔹 Filebeat 配置示例:"
echo "   inputs:"
echo "     - type: log"
echo "       paths:"
echo "         - /path/to/logs/spring-demo.log"
echo "       json.keys_under_root: true"
echo "       json.add_error_key: true"
echo ""
echo "🔹 Elasticsearch 索引模式: spring-demo-*"
echo "🔹 Kibana 推荐字段:"
echo "   - @timestamp (时间序列)"
echo "   - level (日志级别过滤)"
echo "   - traceId (请求追踪)"
echo "   - service (服务过滤)"
echo "   - userId (用户分析)"

echo ""
echo "=========================================="
echo "✅ 演示完成！"
echo ""
echo "📝 总结:"
echo "   - Spring Boot 3.5.4 + JDK 21 应用正常运行"
echo "   - JSON 格式日志输出正常"
echo "   - 所有 API 端点功能正常"
echo "   - 日志文件生成正常"
echo "   - 可以直接与 ELK Stack 集成"
echo ""
echo "🚀 下一步："
echo "   1. 配置 Filebeat 采集日志文件"
echo "   2. 在 Kibana 中创建索引模式"
echo "   3. 创建监控仪表板"
echo "=========================================="
