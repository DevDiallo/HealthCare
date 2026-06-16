package com.healthcare.auth.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "app.security.jwt")
public class AppProperties {

    private String secret;
    private long expiration;
    private long refreshExpiration;
}