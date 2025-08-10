package com.example.elkspringdemo.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.Random;
import java.util.concurrent.CompletableFuture;

@Service
public class LogGeneratorService {

    private static final Logger logger = LoggerFactory.getLogger(LogGeneratorService.class);
    private final Random random = new Random();

    private final String[] sampleMessages = {
        "Processing user request",
        "Database query executed",
        "Cache hit for key",
        "External API call initiated",
        "File upload completed",
        "Email notification sent",
        "Background job scheduled",
        "Session created for user",
        "Configuration updated",
        "Metrics collected"
    };

    private final String[] sampleUsers = {
        "user123", "admin", "guest", "john.doe", "jane.smith",
        "test.user", "developer", "analyst", "manager", "operator"
    };

    private final String[] sampleOperations = {
        "CREATE", "READ", "UPDATE", "DELETE", "SEARCH",
        "EXPORT", "IMPORT", "VALIDATE", "PROCESS", "ANALYZE"
    };

    public void generateLogs(int count, String logLevel) {
        logger.info("Starting log generation: count={}, logLevel={}", count, logLevel);

        for (int i = 0; i < count; i++) {
            generateSingleLog(logLevel, i + 1);

            // Add random delay between logs
            try {
                Thread.sleep(random.nextInt(100) + 10);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                logger.warn("Log generation interrupted");
                break;
            }
        }

        logger.info("Completed log generation: {} logs created", count);
    }

    private void generateSingleLog(String logLevel, int sequenceNumber) {
        String userId = sampleUsers[random.nextInt(sampleUsers.length)];
        String operation = sampleOperations[random.nextInt(sampleOperations.length)];
        String message = sampleMessages[random.nextInt(sampleMessages.length)];

        MDC.put("userId", userId);
        MDC.put("operation", operation);
        MDC.put("sequenceNumber", String.valueOf(sequenceNumber));
        MDC.put("responseTime", String.valueOf(random.nextInt(500) + 10));

        try {
            switch (logLevel.toLowerCase()) {
                case "debug":
                    logger.debug("[{}] {} - {}", operation, message, "Debug details for sequence " + sequenceNumber);
                    break;
                case "info":
                    logger.info("[{}] {} - Processing completed for user: {}", operation, message, userId);
                    break;
                case "warn":
                    logger.warn("[{}] {} - Warning condition detected for user: {}", operation, message, userId);
                    break;
                case "error":
                    logger.error("[{}] {} - Error occurred for user: {} at sequence {}", operation, message, userId, sequenceNumber);
                    break;
                case "all":
                default:
                    // Generate random log level
                    int levelChoice = random.nextInt(4);
                    switch (levelChoice) {
                        case 0:
                            logger.debug("[{}] {} - Debug info for sequence {}", operation, message, sequenceNumber);
                            break;
                        case 1:
                            logger.info("[{}] {} - Successfully processed for user: {}", operation, message, userId);
                            break;
                        case 2:
                            logger.warn("[{}] {} - Warning: Performance issue detected", operation, message);
                            break;
                        case 3:
                            logger.error("[{}] {} - Critical error for user: {}", operation, message, userId);
                            break;
                    }
                    break;
            }
        } finally {
            // Clean up MDC for specific keys, but keep traceId if it exists
            MDC.remove("userId");
            MDC.remove("operation");
            MDC.remove("sequenceNumber");
            MDC.remove("responseTime");
        }
    }

    @Async
    public CompletableFuture<Void> generateLogsAsync(int count, String logLevel) {
        logger.info("Starting async log generation: count={}, logLevel={}", count, logLevel);
        generateLogs(count, logLevel);
        return CompletableFuture.completedFuture(null);
    }

    public void simulateBusinessWorkflow() {
        String workflowId = "WF-" + System.currentTimeMillis();
        MDC.put("workflowId", workflowId);
        MDC.put("operation", "BUSINESS_WORKFLOW");

        try {
            logger.info("Starting business workflow: {}", workflowId);

            // Step 1: Validation
            MDC.put("step", "VALIDATION");
            logger.debug("Validating input parameters for workflow: {}", workflowId);
            simulateProcessingTime(50, 200);

            // Step 2: Data Processing
            MDC.put("step", "DATA_PROCESSING");
            logger.info("Processing data for workflow: {}", workflowId);
            simulateProcessingTime(100, 500);

            // Step 3: External Service Call
            MDC.put("step", "EXTERNAL_CALL");
            logger.info("Calling external service for workflow: {}", workflowId);
            simulateProcessingTime(200, 800);

            // Randomly simulate an error
            if (random.nextInt(10) < 2) { // 20% chance of error
                logger.error("External service call failed for workflow: {}", workflowId);
                throw new RuntimeException("External service unavailable");
            }

            // Step 4: Completion
            MDC.put("step", "COMPLETION");
            logger.info("Workflow completed successfully: {}", workflowId);

        } catch (Exception e) {
            logger.error("Workflow failed: {}", workflowId, e);
        } finally {
            MDC.remove("workflowId");
            MDC.remove("step");
        }
    }

    private void simulateProcessingTime(int minMs, int maxMs) {
        try {
            int processingTime = random.nextInt(maxMs - minMs) + minMs;
            Thread.sleep(processingTime);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
