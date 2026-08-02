package com.back2kasi.user.service;

import com.back2kasi.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Service layer for all user-related business logic.
 *
 * <p>This class sits between the {@code UserController} (HTTP layer) and the
 * {@code UserRepository} (data access layer). It is the only place where
 * user business rules are enforced.</p>
 *
 * <p>Spring injects {@link UserRepository} via constructor injection.
 * The {@code @RequiredArgsConstructor} annotation (Lombok) generates
 * the constructor automatically from all {@code final} fields.</p>
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    // Business logic will be implemented here.
    // First use case: user registration.
}
