package com.back2kasi.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Security configuration for the Back2Kasi platform.
 *
 * <p><strong>Current state (MVP — no JWT yet):</strong><br>
 * All endpoints are permitted without authentication. Spring Security is present
 * only for {@link BCryptPasswordEncoder} — it is not yet enforcing access control.</p>
 *
 * <p><strong>Next phase:</strong><br>
 * This class will be updated to require a valid JWT token on all protected routes
 * once JWT authentication is implemented.</p>
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    /**
     * Permit all requests during MVP development.
     *
     * <p>Spring Security's default behaviour locks every endpoint behind HTTP Basic auth.
     * This filter chain overrides that default and opens everything up temporarily,
     * so Postman testing and local development work without credentials.</p>
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(auth -> auth
                        .anyRequest().permitAll()
                );
        return http.build();
    }

    /**
     * Password encoder using the BCrypt hashing algorithm.
     *
     * <p>BCrypt is the industry standard for password storage. It is adaptive
     * (work factor can be increased over time) and automatically salts each hash,
     * making rainbow-table and brute-force attacks impractical.</p>
     *
     * <p>Declaring this as a {@code @Bean} means Spring can inject it anywhere
     * in the application — currently into {@code UserService}.</p>
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
