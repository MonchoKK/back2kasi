package com.back2kasi.user.controller;

import com.back2kasi.auth.dto.AuthResponse;
import com.back2kasi.auth.dto.LoginRequest;
import com.back2kasi.user.dto.RegisterRequest;
import com.back2kasi.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for user-related HTTP endpoints.
 *
 * <p>This controller is the entry point for all HTTP requests related to users.
 * Its only responsibility is to handle the HTTP concerns: reading the request,
 * delegating to the service layer, and returning the appropriate response.</p>
 *
 * <p>It contains no business logic. All rules live in {@link UserService}.</p>
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * Register a new user account.
     *
     * <p>{@code @Valid} triggers Bean Validation on the request body.
     * If any constraint fails (e.g. blank email, short password),
     * Spring automatically returns a {@code 400 Bad Request} before
     * this method body even executes.</p>
     *
     * @param request the validated registration payload
     * @return {@code 201 Created} on success
     */
    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody @Valid RegisterRequest request) {
        userService.register(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body("User registered successfully");
    }

    /**
     * Authenticate a user and return a JWT.
     *
     * <p>On success, the response contains a signed JWT that Flutter stores
     * and sends as {@code Authorization: Bearer <token>} on protected requests.</p>
     *
     * <p>On failure (wrong email or password), the {@code GlobalExceptionHandler}
     * maps the thrown {@code BadCredentialsException} to {@code 401 Unauthorized}.
     * Both failure cases return the same error message to prevent enumeration attacks.</p>
     *
     * @param request the validated login payload
     * @return {@code 200 OK} with an {@link AuthResponse} containing the JWT
     */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody @Valid LoginRequest request) {
        AuthResponse response = userService.login(request);
        return ResponseEntity.ok(response);
    }
}
