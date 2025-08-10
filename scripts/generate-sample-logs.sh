#!/bin/bash

# ELK Stack 示例日志生成脚本
# 生成多种类型的示例日志用于测试ELK Stack功能
# Author: ELK Team
# Version: 2.0.0

set -e

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/sample-logs"

# 日志文件路径
APP_LOG="$LOG_DIR/app.log"
NGINX_ACCESS_LOG="$LOG_DIR/nginx-access.log"
NGINX_ERROR_LOG="$LOG_DIR/nginx-error.log"
SYSTEM_LOG="$LOG_DIR/system.log"
ERROR_LOG="$LOG_DIR/error.log"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 创建日志目录
mkdir -p "$LOG_DIR"

# 生成应用日志（JSON格式）
generate_app_logs() {
    log_info "生成应用日志..."
    cat > "$APP_LOG" << 'EOF'
{"timestamp":"2025-08-10T10:00:00.000Z","level":"INFO","service":"web-api","message":"应用启动成功","version":"2.1.0","pid":1234,"thread":"main"}
{"timestamp":"2025-08-10T10:01:00.000Z","level":"INFO","service":"web-api","message":"数据库连接成功","database":"mysql","connection_pool":"10","thread":"db-init"}
{"timestamp":"2025-08-10T10:02:00.000Z","level":"INFO","service":"web-api","message":"缓存服务启动","cache_type":"redis","memory":"512MB","thread":"cache-init"}
{"timestamp":"2025-08-10T10:05:00.000Z","level":"INFO","service":"web-api","message":"用户登录成功","user_id":"user123","ip":"192.168.1.100","session":"sess_abc123","thread":"http-nio-8080-exec-1"}
{"timestamp":"2025-08-10T10:06:30.000Z","level":"DEBUG","service":"web-api","message":"SQL查询执行","query":"SELECT * FROM users WHERE id=?","params":"[123]","duration":"15ms","thread":"http-nio-8080-exec-2"}
{"timestamp":"2025-08-10T10:07:00.000Z","level":"INFO","service":"web-api","message":"订单创建","order_id":"ORD001","user_id":"user123","amount":"99.99","currency":"CNY","thread":"http-nio-8080-exec-3"}
{"timestamp":"2025-08-10T10:08:15.000Z","level":"WARN","service":"web-api","message":"数据库连接缓慢","response_time":"2.5s","threshold":"2.0s","database":"mysql","thread":"http-nio-8080-exec-4"}
{"timestamp":"2025-08-10T10:10:00.000Z","level":"WARN","service":"web-api","message":"内存使用率较高","memory_usage":"85%","gc_count":"5","heap_size":"1024MB","thread":"memory-monitor"}
{"timestamp":"2025-08-10T10:12:30.000Z","level":"ERROR","service":"web-api","message":"支付接口调用失败","error":"connection timeout","order_id":"ORD002","payment_gateway":"alipay","retry_count":"3","thread":"payment-processor"}
{"timestamp":"2025-08-10T10:15:00.000Z","level":"ERROR","service":"web-api","message":"数据库连接丢失","error":"Connection reset by peer","connection_id":"conn_456","auto_reconnect":"true","thread":"db-connection-monitor"}
{"timestamp":"2025-08-10T10:18:00.000Z","level":"INFO","service":"web-api","message":"系统健康检查","status":"healthy","uptime":"18m","active_sessions":"25","thread":"health-checker"}
{"timestamp":"2025-08-10T10:20:00.000Z","level":"INFO","service":"web-api","message":"用户退出登录","user_id":"user123","session_duration":"15m","thread":"http-nio-8080-exec-5"}
{"timestamp":"2025-08-10T10:22:00.000Z","level":"INFO","service":"web-api","message":"定时任务执行","task":"data_cleanup","duration":"2.3s","records_processed":"1500","thread":"scheduled-task-1"}
{"timestamp":"2025-08-10T10:25:00.000Z","level":"FATAL","service":"web-api","message":"系统崩溃","error":"OutOfMemoryError","heap_dump":"heap_dump_20250810_1025.hprof","thread":"main"}
EOF
}

# 生成Nginx访问日志
generate_nginx_access_logs() {
    log_info "生成Nginx访问日志..."
    cat > "$NGINX_ACCESS_LOG" << 'EOF'
192.168.1.100 - - [10/Aug/2025:10:00:00 +0000] "GET / HTTP/1.1" 200 2326 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
192.168.1.101 - - [10/Aug/2025:10:01:00 +0000] "POST /api/login HTTP/1.1" 200 156 "http://localhost/" "curl/7.68.0"
192.168.1.102 - - [10/Aug/2025:10:02:00 +0000] "GET /api/users HTTP/1.1" 401 23 "-" "PostmanRuntime/7.26.8"
192.168.1.100 - user123 [10/Aug/2025:10:03:00 +0000] "GET /dashboard HTTP/1.1" 200 8945 "http://localhost/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
192.168.1.103 - - [10/Aug/2025:10:04:00 +0000] "POST /api/orders HTTP/1.1" 500 67 "http://localhost/shop" "axios/0.21.1"
192.168.1.100 - user123 [10/Aug/2025:10:05:00 +0000] "GET /api/profile HTTP/1.1" 200 512 "http://localhost/dashboard" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
192.168.1.104 - - [10/Aug/2025:10:06:00 +0000] "GET /api/products?page=1&limit=20 HTTP/1.1" 200 1024 "-" "python-requests/2.25.1"
192.168.1.105 - - [10/Aug/2025:10:07:00 +0000] "PUT /api/products/123 HTTP/1.1" 403 45 "http://localhost/admin" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
192.168.1.100 - user123 [10/Aug/2025:10:08:00 +0000] "POST /api/logout HTTP/1.1" 200 28 "http://localhost/dashboard" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
192.168.1.106 - - [10/Aug/2025:10:09:00 +0000] "GET /health HTTP/1.1" 200 15 "-" "ELB-HealthChecker/2.0"
192.168.1.107 - - [10/Aug/2025:10:10:00 +0000] "GET /favicon.ico HTTP/1.1" 404 162 "http://localhost/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
EOF
}

# 生成Nginx错误日志
generate_nginx_error_logs() {
    log_info "生成Nginx错误日志..."
    cat > "$NGINX_ERROR_LOG" << 'EOF'
2025/08/10 10:00:00 [notice] 1#1: nginx/1.21.6
2025/08/10 10:00:00 [notice] 1#1: built by gcc 9.4.0 (Ubuntu 9.4.0-1ubuntu1~20.04.2)
2025/08/10 10:00:01 [notice] 1#1: OS: Linux 5.4.0-74-generic
2025/08/10 10:00:01 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/08/10 10:00:01 [notice] 1#1: start worker processes
2025/08/10 10:00:01 [notice] 1#1: start worker process 7
2025/08/10 10:02:30 [error] 7#7: *1 connect() failed (111: Connection refused) while connecting to upstream, client: 192.168.1.102, server: localhost, request: "GET /api/users HTTP/1.1", upstream: "http://127.0.0.1:8080/api/users", host: "localhost"
2025/08/10 10:04:15 [error] 7#7: *2 upstream prematurely closed connection while reading response header from upstream, client: 192.168.1.103, server: localhost, request: "POST /api/orders HTTP/1.1", upstream: "http://127.0.0.1:8080/api/orders", host: "localhost"
2025/08/10 10:06:45 [warn] 7#7: *3 upstream server temporarily disabled while reading response header from upstream, client: 192.168.1.104, server: localhost, request: "GET /api/products HTTP/1.1", upstream: "http://127.0.0.1:8080/api/products", host: "localhost"
2025/08/10 10:08:20 [error] 7#7: *4 recv() failed (104: Connection reset by peer) while reading response header from upstream, client: 192.168.1.105, server: localhost, request: "PUT /api/products/123 HTTP/1.1", upstream: "http://127.0.0.1:8080/api/products/123", host: "localhost"
2025/08/10 10:12:10 [error] 7#7: *5 upstream timed out (110: Connection timed out) while connecting to upstream, client: 192.168.1.106, server: localhost, request: "POST /api/payment HTTP/1.1", upstream: "http://127.0.0.1:8080/api/payment", host: "localhost"
EOF
}

# 生成系统日志
generate_system_logs() {
    log_info "生成系统日志..."
    cat > "$SYSTEM_LOG" << 'EOF'
Aug 10 10:00:01 web-server systemd[1]: Started Daily apt download activities.
Aug 10 10:00:01 web-server systemd[1]: Starting Daily apt download activities...
Aug 10 10:00:15 web-server kernel: [12345.678901] CPU: 0 PID: 1234 Comm: java Not tainted 5.4.0-74-generic #83-Ubuntu
Aug 10 10:01:00 web-server cron[1001]: (root) CMD (run-parts /etc/cron.hourly)
Aug 10 10:02:30 web-server sshd[2001]: Accepted publickey for admin from 192.168.1.10 port 22 ssh2: RSA SHA256:abc123def456
Aug 10 10:03:45 web-server systemd[1]: Started Session 5 of user admin.
Aug 10 10:05:00 web-server docker[3001]: time="2025-08-10T10:05:00.123456789Z" level=info msg="Container started" containerID=abc123def456 containerName=web-api
Aug 10 10:06:15 web-server docker[3001]: time="2025-08-10T10:06:15.987654321Z" level=warning msg="Container health check failed" containerID=def456ghi789 containerName=database retries=1
Aug 10 10:08:00 web-server systemd[1]: docker.service: Main process exited, code=exited, status=1/FAILURE
Aug 10 10:08:00 web-server systemd[1]: docker.service: Failed with result 'exit-code'.
Aug 10 10:08:01 web-server systemd[1]: Stopped Docker Application Container Engine.
Aug 10 10:08:02 web-server systemd[1]: Started Docker Application Container Engine.
EOF
}

# 生成错误日志
generate_error_logs() {
    log_info "生成错误日志..."
    cat > "$ERROR_LOG" << 'EOF'
[2025-08-10 10:00:00] ERROR: Database connection failed - Host 'db.example.com' is not reachable
[2025-08-10 10:02:15] CRITICAL: Out of memory exception in module 'user_management'
[2025-08-10 10:05:30] ERROR: Failed to send email notification - SMTP server timeout
[2025-08-10 10:08:45] WARNING: High CPU usage detected - Usage: 95% for 5 minutes
[2025-08-10 10:12:00] ERROR: Payment gateway API returned HTTP 500 - Internal Server Error
[2025-08-10 10:15:20] FATAL: Application crash detected - Segmentation fault in module 'data_processor'
[2025-08-10 10:18:35] ERROR: File system full - Unable to write log files to /var/log/
[2025-08-10 10:22:10] WARNING: SSL certificate expires in 7 days - Domain: api.example.com
[2025-08-10 10:25:45] ERROR: Redis connection lost - Connection refused on port 6379
[2025-08-10 10:28:00] CRITICAL: Security breach detected - Unauthorized access attempt from IP 192.168.1.200
EOF
}

# 主函数
main() {
    echo -e "${CYAN}=== ELK Stack 示例日志生成器 v2.0.0 ===${NC}"
    echo

    generate_app_logs
    generate_nginx_access_logs
    generate_nginx_error_logs
    generate_system_logs
    generate_error_logs

    echo
    log_info "示例日志文件生成完成！"
    echo
    echo -e "${CYAN}生成的日志文件:${NC}"
    echo -e "  📱 应用日志: ${YELLOW}$APP_LOG${NC}"
    echo -e "  🌐 Nginx访问日志: ${YELLOW}$NGINX_ACCESS_LOG${NC}"
    echo -e "  ❌ Nginx错误日志: ${YELLOW}$NGINX_ERROR_LOG${NC}"
    echo -e "  🖥️  系统日志: ${YELLOW}$SYSTEM_LOG${NC}"
    echo -e "  🚨 错误日志: ${YELLOW}$ERROR_LOG${NC}"
    echo
    echo -e "${CYAN}下一步操作:${NC}"
    echo "  1. 启动ELK Stack: ./elk-manager.sh start"
    echo "  2. 在Kibana中创建索引模式查看日志数据"
    echo "  3. 配置Filebeat收集这些日志文件"
}

# 运行主函数
main

