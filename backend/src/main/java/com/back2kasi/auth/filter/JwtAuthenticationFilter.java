package com.back2kasi.auth.filter;

import com.back2kasi.auth.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT authentication filter — runs once per HTTP request.
 *
 * <p>Spring Security's filter chain runs before any controller. This filter
 * sits at the front and does four things for every request:</p>
 *
 * <ol>
 *   <li><strong>Read</strong> the {@code Authorization: Bearer <token>} header.</li>
 *   <li><strong>Parse</strong> the token to extract the user's email.</li>
 *   <li><strong>Load</strong> the user from the database and validate the token.</li>
 *   <li><strong>Set</strong> the authenticated user in the {@code SecurityContext},
 *       so downstream code (other filters, controllers) knows who is making the request.</li>
 * </ol>
 *
 * <p>If any step fails (missing header, invalid token, expired token) the filter
 * simply passes the request along unchanged — Spring Security's own rules will
 * then reject it with a {@code 401 Unauthorized} if the route is protected.</p>
 *
 * <p>{@code OncePerRequestFilter} guarantees this runs exactly once, even in
 * servlet environments that might forward requests internally.</p>
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest  request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain         filterChain
    ) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        // 1. No Authorization header, or not a Bearer token → skip this filter.
        //    The request continues; if the route is protected, Spring Security will
        //    respond with 401 automatically.
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 2. Extract the raw JWT (everything after "Bearer ")
        final String jwt       = authHeader.substring(7);
        final String userEmail = jwtService.extractEmail(jwt);

        // 3. Only authenticate if we have an email AND the security context is empty.
        //    If the context already has an authentication object, someone else already
        //    authenticated this request (e.g. a previous filter) — don't override it.
        if (userEmail != null && SecurityContextHolder.getContext().getAuthentication() == null) {

            UserDetails userDetails = userDetailsService.loadUserByUsername(userEmail);

            if (jwtService.isTokenValid(jwt, userDetails)) {
                // 4. Token is valid — create an authentication token and set it in the context.
                //    From this point on, Spring Security treats the request as authenticated.
                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,                          // credentials — not needed after authentication
                                userDetails.getAuthorities()   // e.g. [ROLE_USER]
                        );

                // Attach request details (IP, session) to the authentication object
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                // Place authentication into the thread-local security context
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        // 5. Continue the filter chain regardless of outcome
        filterChain.doFilter(request, response);
    }
}
