package com.back2kasi.config;

import com.back2kasi.auth.filter.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Security configuration for the Back2Kasi platform.
 *
 * <h2>How Spring Security's filter chain works</h2>
 * <p>Every HTTP request passes through an ordered chain of filters before reaching
 * a controller. This class configures that chain. Key decisions:</p>
 *
 * <ul>
 *   <li><strong>Stateless sessions</strong> — JWTs carry all auth state.
 *       The server never creates an HTTP session ({@link SessionCreationPolicy#STATELESS}).
 *       This is mandatory for mobile / Flutter apps.</li>
 *   <li><strong>CSRF disabled</strong> — CSRF attacks rely on browser cookies.
 *       Because we use JWT in the {@code Authorization} header (not cookies), CSRF is not
 *       a threat and disabling it avoids unnecessary complexity.</li>
 *   <li><strong>Public routes</strong> — {@code /register} and {@code /login} are
 *       open to the world (no token required). Everything else is protected.</li>
 *   <li><strong>JWT filter placement</strong> — {@link JwtAuthenticationFilter} runs
 *       <em>before</em> Spring's own {@link UsernamePasswordAuthenticationFilter}
 *       so that token-authenticated requests are recognised first.</li>
 * </ul>
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    /**
     * The main security filter chain.
     *
     * <p>The {@link JwtAuthenticationFilter} is injected as a method parameter
     * (not a class field) to avoid constructor-injection cycles. Spring resolves
     * the bean and passes it here at startup.</p>
     */
    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            JwtAuthenticationFilter jwtAuthenticationFilter) throws Exception {

        http
                // Disable CSRF — not needed with JWT in Authorization header
                .csrf(AbstractHttpConfigurer::disable)

                // Stateless: no HTTP session, no cookies — JWT is the entire auth state
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // Route-level access rules
                .authorizeHttpRequests(auth -> auth
                        // Public: anyone can register or log in
                        .requestMatchers("/api/users/register", "/api/users/login").permitAll()
                        // Public: customers can browse rental units without logging in
                        .requestMatchers(HttpMethod.GET, "/api/v1/rental-units", "/api/v1/rental-units/**").permitAll()
                        // Public: Swagger UI and OpenAPI spec (disabled in prod profile)
                        .requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**").permitAll()
                        // Everything else requires a valid JWT
                        .anyRequest().authenticated()
                )

                // Insert our JWT filter before Spring's built-in username/password filter
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Expose Spring's {@link AuthenticationManager} as a bean.
     *
     * <p>Not used directly in this phase, but required by Spring Security's
     * auto-configuration and needed in future if we wire form-based login or OAuth.</p>
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * Password encoder using the BCrypt hashing algorithm.
     *
     * <p>BCrypt is the industry standard for password storage. It is adaptive
     * (work factor can be increased over time) and automatically salts each hash,
     * making rainbow-table and brute-force attacks impractical.</p>
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
