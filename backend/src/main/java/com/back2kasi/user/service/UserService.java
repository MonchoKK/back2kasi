package com.back2kasi.user.service;

import com.back2kasi.user.dto.RegisterRequest;
import com.back2kasi.user.entity.Role;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Service layer for all user-related business logic.
 *
 * <p>This class sits between the {@code UserController} (HTTP layer) and the
 * {@code UserRepository} (data access layer). It is the only place where
 * user business rules are enforced.</p>
 *
 * <p>Both {@link UserRepository} and {@link PasswordEncoder} are injected via
 * constructor injection. Spring resolves and provides both at startup.</p>
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

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
}
