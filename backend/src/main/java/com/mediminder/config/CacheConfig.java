package com.mediminder.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
@EnableCaching
public class CacheConfig {

    public static final String MEDICATIONS_CACHE = "medicationsCache";
    public static final String APPOINTMENTS_CACHE = "appointmentsCache";
    public static final String MED_LOGS_CACHE = "medLogsCache";
    public static final String USER_CACHE = "userCache";

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager(
                MEDICATIONS_CACHE,
                APPOINTMENTS_CACHE,
                MED_LOGS_CACHE,
                USER_CACHE);
        cacheManager.setCaffeine(caffeineCacheBuilder());
        return cacheManager;
    }

    private Caffeine<Object, Object> caffeineCacheBuilder() {
        return Caffeine.newBuilder()
                .expireAfterWrite(5, TimeUnit.MINUTES)
                .maximumSize(1000)
                .recordStats();
    }
}
