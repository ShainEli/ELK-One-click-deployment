package com.example.elkspringdemo.controller;

import com.example.elkspringdemo.service.LogGeneratorService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class DemoController {

    private static final Logger logger = LoggerFactory.getLogger(DemoController.class);

    @Autowired
    private LogGeneratorService logGeneratorService;

    @GetMapping("/hello")
    public ResponseEntity<Map<String, String>> hello(@RequestParam(defaultValue = "World") String name) {
        String traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        MDC.put("userId", "user-" + System.currentTimeMillis() % 1000);

        try {
            logger.info("Received hello request for name: {}", name);

            Map<String, String> response = Map.of(
                "message", "Hello, " + name + "!",
                "timestamp", String.valueOf(System.currentTimeMillis()),
                "traceId", traceId
            );

            logger.info("Successfully processed hello request for name: {}, response: {}", name, response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error processing hello request for name: {}", name, e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Internal server error", "traceId", traceId));
        } finally {
            MDC.clear();
        }
    }

    @PostMapping("/simulate-error")
    public ResponseEntity<Map<String, String>> simulateError(@RequestBody Map<String, Object> request) {
        String traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        MDC.put("operation", "simulate-error");

        try {
            String errorType = (String) request.getOrDefault("errorType", "runtime");
            logger.warn("Simulating error of type: {}", errorType);

            switch (errorType) {
                case "runtime":
                    throw new RuntimeException("Simulated runtime exception");
                case "validation":
                    logger.error("Validation error: Invalid input data");
                    return ResponseEntity.badRequest()
                            .body(Map.of("error", "Validation failed", "traceId", traceId));
                case "database":
                    logger.error("Database connection error occurred");
                    return ResponseEntity.internalServerError()
                            .body(Map.of("error", "Database error", "traceId", traceId));
                default:
                    logger.debug("Unknown error type requested: {}", errorType);
                    return ResponseEntity.ok(Map.of("message", "No error simulated", "traceId", traceId));
            }
        } catch (Exception e) {
            logger.error("Exception occurred during error simulation", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage(), "traceId", traceId));
        } finally {
            MDC.clear();
        }
    }

    @GetMapping("/generate-logs")
    public ResponseEntity<Map<String, String>> generateLogs(
            @RequestParam(defaultValue = "10") int count,
            @RequestParam(defaultValue = "all") String logLevel) {

        String traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        MDC.put("operation", "generate-logs");

        try {
            logger.info("Starting log generation: count={}, logLevel={}", count, logLevel);
            logGeneratorService.generateLogs(count, logLevel);

            Map<String, String> response = Map.of(
                "message", "Generated " + count + " logs successfully",
                "logLevel", logLevel,
                "traceId", traceId
            );

            logger.info("Log generation completed successfully: {}", response);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error during log generation", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Log generation failed", "traceId", traceId));
        } finally {
            MDC.clear();
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        String traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        MDC.put("operation", "health-check");

        try {
            Map<String, Object> healthInfo = Map.of(
                "status", "UP",
                "timestamp", System.currentTimeMillis(),
                "traceId", traceId,
                "version", "1.0.0",
                "jvm", Map.of(
                    "memory", Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory(),
                    "maxMemory", Runtime.getRuntime().maxMemory()
                )
            );

            logger.debug("Health check performed successfully");
            return ResponseEntity.ok(healthInfo);
        } finally {
            MDC.clear();
        }
    }
}
