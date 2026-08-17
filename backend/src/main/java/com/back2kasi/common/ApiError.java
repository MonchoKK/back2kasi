package com.back2kasi.common;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Standard error response body returned by all API endpoints.
 *
 * <p>Every error response across the Back2Kasi API shares this structure,
 * regardless of error type. This gives the Flutter client (and any other
 * consumer) a single parser for all failure cases.</p>
 *
 * <h2>Shape examples</h2>
 *
 * <p><strong>Validation failure (400):</strong></p>
 * <pre>{@code
 * {
 *   "status":     400,
 *   "error":      "Bad Request",
 *   "message":    "Validation failed",
 *   "timestamp":  "2026-08-17T15:00:00",
 *   "fieldErrors": { "name": "Unit name is required" }
 * }
 * }</pre>
 *
 * <p><strong>Resource not found (404):</strong></p>
 * <pre>{@code
 * {
 *   "status":    404,
 *   "error":     "Not Found",
 *   "message":   "Business not found with id: 99",
 *   "timestamp": "2026-08-17T15:00:00"
 * }
 * }</pre>
 *
 * <p>{@code fieldErrors} is omitted from the JSON output when {@code null}
 * (Jackson {@code @JsonInclude(NON_NULL)}) so non-validation errors stay clean.</p>
 *
 * @param status      HTTP status code (e.g. 404)
 * @param error       HTTP reason phrase (e.g. "Not Found")
 * @param message     human-readable explanation of what went wrong
 * @param timestamp   when the error occurred (server time)
 * @param fieldErrors per-field validation messages; {@code null} for non-validation errors
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(
        int status,
        String error,
        String message,
        LocalDateTime timestamp,
        Map<String, String> fieldErrors
) {

    /**
     * Convenience factory for non-validation errors (no field-level detail).
     *
     * @param status  HTTP status code
     * @param error   HTTP reason phrase
     * @param message human-readable explanation
     * @return a fully populated {@link ApiError} with {@code fieldErrors = null}
     */
    public static ApiError of(int status, String error, String message) {
        return new ApiError(status, error, message, LocalDateTime.now(), null);
    }

    /**
     * Convenience factory for validation errors (includes per-field messages).
     *
     * @param fieldErrors map of field name → validation message
     * @return a 400 Bad Request {@link ApiError} with field-level detail
     */
    public static ApiError validationError(Map<String, String> fieldErrors) {
        return new ApiError(400, "Bad Request", "Validation failed",
                LocalDateTime.now(), fieldErrors);
    }
}
