package com.back2kasi.common.exception;

/**
 * Thrown when a requested resource does not exist in the database.
 *
 * <p>Handled by {@link com.back2kasi.common.GlobalExceptionHandler} and
 * translated to an HTTP {@code 404 Not Found} response.</p>
 *
 * <p>Usage example:</p>
 * <pre>
 *     throw new ResourceNotFoundException("Business not found with id: " + id);
 * </pre>
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
