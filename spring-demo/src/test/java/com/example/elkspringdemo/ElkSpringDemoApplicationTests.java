package com.example.elkspringdemo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class ElkSpringDemoApplicationTests {

    @Test
    void contextLoads() {
        // 测试Spring Boot应用上下文是否能正常加载
    }

}
