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
 *
 * <p>All handlers return {@link ApiError} — the single standard error body
 * used across the entire API. This gives clients (Flutter, Postman, Swagger)
 * a single consistent shape to parse for every failure case.</p>
 *
 * <h2>Error map</h2>
 * <table>
 *   <tr><th>Exception</th><th>HTTP</th><th>Notes</th></tr>
 *   <tr><td>MethodArgumentNotValidException</td><td>400</td><td>Bean Validation failures; includes per-field errors</td></tr>
 *   <tr><td>BadCredentialsException</td><td>401</td><td>Wrong email or password; generic message to prevent enumeration</td></tr>
 *   <tr><td>UnauthorizedException</td><td>403</td><td>Authenticated but not the owner of the resource</td></tr>
 *   <tr><td>ResourceNotFoundException</td><td>404</td><td>Entity with given ID does not exist</td></tr>
 *   <tr><td>IllegalStateException</td><td>409</td><td>Business rule conflict (e.g. duplicate email, booking overlap)</td></tr>
 * </table>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Handle Bean Validation failures — e.g. blank name, missing businessType.
     *
     * <p>Returns {@code 400 Bad Request} with a map of field names to their
     * validation error messages inside {@link ApiError#fieldErrors()}.</p>
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(fieldError ->
                fieldErrors.put(fieldError.getField(), fieldError.getDefaultMessage())
        );
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiError.validationError(fieldErrors));
    }

    /**
     * Handle invalid login credentials — wrong email or wrong password.
     *
     * <p>Returns {@code 401 Unauthorized} with a generic message.
     * The message does not reveal <em>which</em> field is wrong; doing so
     * would allow an attacker to enumerate registered email addresses.</p>
     */
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiError> handleBadCredentials(BadCredentialsException ex) {
        return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(ApiError.of(401, "Unauthorized", "Invalid email or password"));
    }

    /**
     * Handle ownership violations — authenticated user attempting to modify
     * a resource they do not own.
     *
     * <p>Returns {@code 403 Forbidden}.</p>
     *
     * <p><strong>Why 403 and not 401?</strong> The user is authenticated (they
     * have a valid JWT) but is not authorised for this specific resource.
     * 401 Unauthorized would imply no credentials were provided at all.</p>
     */
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<ApiError> handleUnauthorized(UnauthorizedException ex) {
        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(ApiError.of(403, "Forbidden", ex.getMessage()));
    }

    /**
     * Handle requests for resources that do not exist.
     *
     * <p>Returns {@code 404 Not Found}.</p>
     */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ApiError.of(404, "Not Found", ex.getMessage()));
    }

    /**
     * Handle business rule conflicts — e.g. duplicate email registration,
     * booking date overlap, illegal status transitions.
     *
     * <p>Returns {@code 409 Conflict}.</p>
     */
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<ApiError> handleConflict(IllegalStateException ex) {
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(ApiError.of(409, "Conflict", ex.getMessage()));
    }
}
