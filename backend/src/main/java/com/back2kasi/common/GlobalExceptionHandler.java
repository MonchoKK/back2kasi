package com.back2kasi.common;

import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

/**
 * Global exception handler for all REST controllers.
 *
 * <p>{@code @RestControllerAdvice} intercepts exceptions thrown by any
 * {@code @RestController} and maps them to meaningful HTTP responses —
 * rather than letting Spring return a generic 500 Internal Server Error.</p>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Handle duplicate resource conflicts (e.g. email already registered).
     *
     * <p>Maps {@link IllegalStateException} → {@code 409 Conflict}.</p>
     */
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, String>> handleConflict(IllegalStateException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
    }

    /**
     * Handle requests for resources that do not exist (e.g. business not found).
     *
     * <p>Maps {@link ResourceNotFoundException} → {@code 404 Not Found}.</p>
     */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(ResourceNotFoundException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    /**
     * Handle ownership violations (authenticated user attempting to modify
     * a resource they do not own).
     *
     * <p>Maps {@link UnauthorizedException} → {@code 403 Forbidden}.</p>
     *
     * <p><strong>Why 403 and not 401?</strong> The user is authenticated (they
     * have a valid JWT) but is not authorised for this specific resource.
     * 401 Unauthorized would imply no credentials were provided at all.</p>
     */
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, String>> handleUnauthorized(UnauthorizedException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }

    /**
     * Handle invalid login credentials (wrong email or wrong password).
     *
     * <p>Maps {@link BadCredentialsException} → {@code 401 Unauthorized}.</p>
     *
     * <p>The response message is intentionally generic: {@code "Invalid email or password"}.
     * Revealing <em>which</em> field is wrong would allow an attacker to enumerate
     * registered email addresses.</p>
     */
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, String>> handleBadCredentials(BadCredentialsException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("error", "Invalid email or password");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
    }

    /**
     * Handle Bean Validation failures (e.g. blank email, short password).
     *
     * <p>Maps {@link MethodArgumentNotValidException} → {@code 400 Bad Request}
     * with a map of field names to their validation error messages.</p>
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(fieldError ->
                errors.put(fieldError.getField(), fieldError.getDefaultMessage())
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errors);
    }
}
