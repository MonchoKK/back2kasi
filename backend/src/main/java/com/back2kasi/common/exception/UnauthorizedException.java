package com.back2kasi.common.exception;

/**
 * Thrown when an authenticated user attempts to access or modify a resource
 * they do not own.
 *
 * <p>Handled by {@link com.back2kasi.common.GlobalExceptionHandler} and
 * translated to an HTTP {@code 403 Forbidden} response.</p>
 *
 * <p>Usage example:</p>
 * <pre>
 *     throw new UnauthorizedException("You do not have permission to modify this business");
 * </pre>
 *
 * <p><strong>403 vs 401:</strong> {@code 401 Unauthorized} means the request
 * has no valid credentials at all. {@code 403 Forbidden} means the credentials
 * are valid but the user does not have permission for this specific resource.
 * Ownership violations are always 403.</p>
 */
public class UnauthorizedException extends RuntimeException {

    public UnauthorizedException(String message) {
        super(message);
    }
}
