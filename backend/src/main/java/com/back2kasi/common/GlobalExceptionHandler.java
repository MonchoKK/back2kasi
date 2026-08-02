package com.back2kasi.common;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
