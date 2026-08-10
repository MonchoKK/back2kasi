package com.back2kasi.user.service;

import com.back2kasi.auth.dto.AuthResponse;
import com.back2kasi.auth.dto.LoginRequest;
import com.back2kasi.auth.service.JwtService;
import com.back2kasi.user.dto.RegisterRequest;
import com.back2kasi.user.entity.Role;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Service layer for all user-related business logic.
 *
 * <p>This class sits between the {@code UserController} (HTTP layer) and the
 * {@code UserRepository} (data access layer). It is the only place where
 * user business rules are enforced.</p>
 *
 * <p>It also implements {@link UserDetailsService} — the single interface
 * Spring Security requires to load a user by username (email in our case).
 * The {@code JwtAuthenticationFilter} calls {@link #loadUserByUsername(String)}
 * on every request that carries a JWT, to verify the token against a live user.</p>
 */
@Service
@RequiredArgsConstructor
public class UserService implements UserDetailsService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    // =========================================================
    // UserDetailsService — required by Spring Security
    // =========================================================

    /**
     * Load a user by their email address.
     *
     * <p>Called by {@code JwtAuthenticationFilter} to validate an incoming JWT.
     * Spring Security uses the returned {@link UserDetails} to check whether the
     * token's subject matches a real, active user in the database.</p>
     *
     * @param email the unique email address (Spring Security calls the parameter "username")
     * @return the {@link User} entity, which implements {@link UserDetails}
     * @throws UsernameNotFoundException if no user exists with the given email
     */
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "No account found with email: " + email
                ));
    }

    // =========================================================
    // Registration
    // =========================================================

    /**
     * Register a new user on the platform.
     *
     * <p>Registration rules enforced here:</p>
     * <ol>
     *   <li>Email must not already be in use — duplicate accounts are rejected.</li>
     *   <li>Password is hashed with BCrypt before being stored — never plain text.</li>
     *   <li>Every new user is assigned the {@link Role#USER} role by default.</li>
     * </ol>
     *
     * @param request the validated registration payload from the controller
     * @throws IllegalStateException if the email address is already registered
     */
    public void register(RegisterRequest request) {

        // 1. Reject duplicate email addresses
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalStateException(
                    "An account with this email address already exists: " + request.getEmail()
            );
        }

        // 2. Hash the password — never store plain text
        String hashedPassword = passwordEncoder.encode(request.getPassword());

        // 3. Build the User entity from the DTO
        User user = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .password(hashedPassword)
                .phoneNumber(request.getPhoneNumber())
                .role(Role.USER)
                .build();

        // 4. Persist to the database
        userRepository.save(user);
    }

    // =========================================================
    // Login
    // =========================================================

    /**
     * Authenticate a user and return a JWT.
     *
     * <p>Login rules enforced here:</p>
     * <ol>
     *   <li>Email must exist in the database.</li>
     *   <li>The supplied password must match the stored BCrypt hash.</li>
     *   <li>Both failure cases return the same {@link BadCredentialsException}
     *       with the same message — this prevents an attacker from using the
     *       API to discover which emails are registered (enumeration attack).</li>
     * </ol>
     *
     * @param request the validated login payload from the controller
     * @return an {@link AuthResponse} containing the signed JWT
     * @throws BadCredentialsException if the email is not found or the password is wrong
     */
    public AuthResponse login(LoginRequest request) {

        // 1. Look up user — same error whether the email doesn't exist OR password is wrong
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        // 2. BCrypt comparison: matches(plain, hash)
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        // 3. Generate and return the signed JWT
        String token = jwtService.generateToken(user);

        return new AuthResponse(token, "Bearer", jwtService.getExpirationSeconds());
    }
}
