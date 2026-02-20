package com.mediminder.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.rate-limit")
@Getter
@Setter
public class RateLimitingProperties {

    /**
     * Enable/disable rate limiting
     */
    private boolean enabled = true;

    /**
     * Maximum requests per window for authenticated users
     */
    private int authenticatedMaxRequests = 100;

    /**
     * Maximum requests per window for unauthenticated users (stricter)
     */
    private int unauthenticatedMaxRequests = 20;

    /**
     * Time window in seconds
     */
    private int windowSeconds = 60;

    /**
     * Paths to exclude from rate limiting (e.g., health checks)
     */
    private String[] excludedPaths = { "/health", "/error", "/swagger-ui/**", "/v3/api-docs/**" };
}
