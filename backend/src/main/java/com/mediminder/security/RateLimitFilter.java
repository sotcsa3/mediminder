package com.mediminder.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.mediminder.config.RateLimitingProperties;
import jakarta.annotation.PostConstruct;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

@Component
@RequiredArgsConstructor
@Slf4j
public class RateLimitFilter extends OncePerRequestFilter {

    private final RateLimitingProperties rateLimitingProperties;
    private Cache<String, RateLimitBucket> buckets;

    @PostConstruct
    public void init() {
        this.buckets = Caffeine.newBuilder()
                .expireAfterAccess(rateLimitingProperties.getWindowSeconds() * 2L, TimeUnit.SECONDS)
                .maximumSize(10_000)
                .build();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        if (!rateLimitingProperties.isEnabled()) {
            filterChain.doFilter(request, response);
            return;
        }

        // Skip rate limiting for excluded paths
        if (isExcludedPath(request.getRequestURI())) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientId = getClientIdentifier(request);
        int maxRequests = getMaxRequests(request);
        RateLimitBucket bucket = buckets.get(clientId, k -> new RateLimitBucket(
                rateLimitingProperties.getWindowSeconds()));

        // Check if request is allowed
        if (!bucket.tryConsume(maxRequests)) {
            log.warn("Rate limit exceeded for client: {} on path: {}", clientId, request.getRequestURI());
            response.setStatus(429); // Too Many Requests
            response.setContentType("application/json");
            response.getWriter().write(
                    "{\"error\":\"Too Many Requests\",\"message\":\"Rate limit exceeded. Please try again later.\"}");
            return;
        }

        // Add rate limit headers
        response.setHeader("X-RateLimit-Limit", String.valueOf(maxRequests));
        response.setHeader("X-RateLimit-Remaining", String.valueOf(bucket.getRemainingRequests(maxRequests)));
        response.setHeader("X-RateLimit-Reset", String.valueOf(bucket.getResetTime()));

        filterChain.doFilter(request, response);
    }

    private String getClientIdentifier(HttpServletRequest request) {
        // Use IP address as identifier, or authenticated user ID if available
        String userId = (String) request.getAttribute("userId");
        if (userId != null) {
            return "user:" + userId;
        }

        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) {
            ip = request.getRemoteAddr();
        }
        return "ip:" + ip;
    }

    private int getMaxRequests(HttpServletRequest request) {
        String userId = (String) request.getAttribute("userId");
        if (userId != null) {
            return rateLimitingProperties.getAuthenticatedMaxRequests();
        }
        return rateLimitingProperties.getUnauthenticatedMaxRequests();
    }

    private boolean isExcludedPath(String requestUri) {
        for (String excludedPath : rateLimitingProperties.getExcludedPaths()) {
            if (excludedPath.endsWith("/**")) {
                String prefix = excludedPath.substring(0, excludedPath.length() - 3);
                if (requestUri.startsWith(prefix)) {
                    return true;
                }
            } else if (requestUri.equals(excludedPath)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Simple rate limit bucket using fixed window counter
     */
    private static class RateLimitBucket {
        private final int windowSeconds;
        private final AtomicInteger count = new AtomicInteger(0);
        private volatile long windowStart;

        public RateLimitBucket(int windowSeconds) {
            this.windowSeconds = windowSeconds;
            this.windowStart = System.currentTimeMillis();
        }

        public synchronized boolean tryConsume(int maxRequests) {
            long now = System.currentTimeMillis();
            if (now - windowStart > windowSeconds * 1000L) {
                // Reset window
                windowStart = now;
                count.set(0);
            }
            if (count.get() >= maxRequests) {
                return false;
            }
            count.incrementAndGet();
            return true;
        }

        public int getRemainingRequests(int maxRequests) {
            long now = System.currentTimeMillis();
            if (now - windowStart > windowSeconds * 1000L) {
                return maxRequests;
            }
            return Math.max(0, maxRequests - count.get());
        }

        public long getResetTime() {
            return (windowStart + windowSeconds * 1000L) / 1000;
        }
    }
}
