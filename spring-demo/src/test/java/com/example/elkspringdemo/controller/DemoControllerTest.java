package com.example.elkspringdemo.controller;

import com.example.elkspringdemo.service.LogGeneratorService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(DemoController.class)
class DemoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LogGeneratorService logGeneratorService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testHelloEndpoint() throws Exception {
        mockMvc.perform(get("/api/hello")
                .param("name", "TestUser"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Hello, TestUser!"))
                .andExpect(jsonPath("$.traceId").exists());
    }

    @Test
    void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.traceId").exists());
    }

    @Test
    void testSimulateErrorEndpoint() throws Exception {
        Map<String, String> errorRequest = Map.of("errorType", "validation");

        mockMvc.perform(post("/api/simulate-error")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(errorRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.error").value("Validation failed"));
    }

    @Test
    void testGenerateLogsEndpoint() throws Exception {
        mockMvc.perform(get("/api/generate-logs")
                .param("count", "5")
                .param("logLevel", "info"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Generated 5 logs successfully"));
    }
}
