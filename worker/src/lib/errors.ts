export class HttpError extends Error {
  public readonly status: number;
  public readonly error: string;
  public readonly fieldErrors?: Record<string, string>;

  constructor(
    status: number,
    error: string,
    message: string,
    fieldErrors?: Record<string, string>
  ) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.error = error;
    this.fieldErrors = fieldErrors;
  }
}

export class ValidationError extends HttpError {
  constructor(fieldErrors: Record<string, string>, message = 'Validation failed') {
    super(400, 'Bad Request', message, fieldErrors);
  }
}

export class BadCredentialsError extends HttpError {
  constructor(message = 'Invalid email or password') {
    super(401, 'Unauthorized', message);
  }
}

export class UnauthorizedError extends HttpError {
  constructor(message = 'You do not have permission to access this resource') {
    super(403, 'Forbidden', message);
  }
}

export class ResourceNotFoundError extends HttpError {
  constructor(message: string) {
    super(404, 'Not Found', message);
  }
}

export class ConflictError extends HttpError {
  constructor(message: string) {
    super(409, 'Conflict', message);
  }
}

export function formatApiError(
  status: number,
  error: string,
  message: string,
  fieldErrors?: Record<string, string>
) {
  return {
    status,
    error,
    message,
    timestamp: new Date().toISOString(),
    ...(fieldErrors ? { fieldErrors } : {}),
  };
}
