package com.back2kasi.user.service;

import com.back2kasi.auth.dto.AuthResponse;
import com.back2kasi.auth.dto.LoginRequest;
import com.back2kasi.auth.service.JwtService;
import com.back2kasi.user.dto.RegisterRequest;
import com.back2kasi.user.entity.Role;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.lenient;

/**
 * Unit tests for {@link UserService}.
 *
 * <p>This is a <strong>pure unit test</strong>: no Spring context is loaded,
 * no database is involved. Both collaborators ({@link UserRepository} and
 * {@link PasswordEncoder}) are replaced with Mockito mocks so that each test
 * exercises only the logic inside {@code UserService} itself.</p>
 *
 * <p>Key Mockito concepts used here:</p>
 * <ul>
 *   <li>{@code @Mock} — creates a fake (mock) of a dependency.</li>
 *   <li>{@code @InjectMocks} — creates the real object under test and injects the mocks into it.</li>
 *   <li>{@code when(...).thenReturn(...)} — stubs a mock to return a specific value.</li>
 *   <li>{@code verify(...)} — asserts that a method was called on a mock.</li>
 *   <li>{@link ArgumentCaptor} — captures the argument passed to a mock so we can inspect it.</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    // --- Mocks (fakes that replace the real implementations) ---

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    // --- Subject under test (gets the mocks injected automatically) ---

    @InjectMocks
    private UserService userService;

    // =========================================================
    // Happy path
    // =========================================================

    /**
     * When a brand-new email is submitted, the service must:
     * <ol>
     *   <li>Hash the plain-text password before storing it.</li>
     *   <li>Assign the default {@link Role#USER} role.</li>
     *   <li>Call {@code save()} on the repository exactly once with a correctly populated entity.</li>
     * </ol>
     */
    @Test
    void register_savesUser_whenEmailIsNew() {
        // --- ARRANGE ---
        // Build a realistic registration request
        RegisterRequest request = buildRequest(
                "Kabelo", "Kekana",
                "kabelo@back2kasi.co.za", "secret123", "+27712345678"
        );

        // Stub: the email does NOT already exist in the database
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(false);

        // Stub: the password encoder returns a predictable hash
        when(passwordEncoder.encode(request.getPassword())).thenReturn("hashed_secret123");

        // --- ACT ---
        userService.register(request);

        // --- ASSERT ---
        // Capture the User entity that was passed to save()
        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository, times(1)).save(userCaptor.capture());

        User savedUser = userCaptor.getValue();
        assertThat(savedUser.getFirstName()).isEqualTo("Kabelo");
        assertThat(savedUser.getLastName()).isEqualTo("Kekana");
        assertThat(savedUser.getEmail()).isEqualTo("kabelo@back2kasi.co.za");
        assertThat(savedUser.getPassword()).isEqualTo("hashed_secret123"); // plain text was replaced
        assertThat(savedUser.getPhoneNumber()).isEqualTo("+27712345678");
        assertThat(savedUser.getRole()).isEqualTo(Role.USER);              // default role assigned
    }

    // =========================================================
    // Duplicate email — business rule enforcement
    // =========================================================

    /**
     * When an email address is already registered, the service must throw an
     * {@link IllegalStateException} and must NOT attempt to save anything to
     * the database.
     *
     * <p>The {@code GlobalExceptionHandler} maps this exception → {@code 409 Conflict}.</p>
     */
    @Test
    void register_throwsIllegalStateException_whenEmailAlreadyExists() {
        // --- ARRANGE ---
        RegisterRequest request = buildRequest(
                "Kabelo", "Kekana",
                "existing@back2kasi.co.za", "secret123", "0712345678"
        );

        // Stub: this email is ALREADY in the database
        when(userRepository.existsByEmail(request.getEmail())).thenReturn(true);

        // --- ACT & ASSERT ---
        assertThatThrownBy(() -> userService.register(request))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("existing@back2kasi.co.za");

        // Verify that save() was never called — we must not persist a duplicate
        verify(userRepository, never()).save(any());
    }

    // =========================================================
    // Login — happy path
    // =========================================================

    /**
     * When valid credentials are submitted:
     * <ol>
     *   <li>The user is found by email.</li>
     *   <li>BCrypt comparison succeeds.</li>
     *   <li>A token is generated and returned inside an {@link AuthResponse}.</li>
     * </ol>
     */
    @Test
    void login_returnsAuthResponse_whenCredentialsAreValid() {
        // --- ARRANGE ---
        LoginRequest request = buildLoginRequest("kabelo@back2kasi.co.za", "secret123");

        User storedUser = User.builder()
                .id(1L)
                .email("kabelo@back2kasi.co.za")
                .password("hashed_secret123")
                .role(Role.USER)
                .build();

        when(userRepository.findByEmail(request.getEmail())).thenReturn(java.util.Optional.of(storedUser));
        when(passwordEncoder.matches(request.getPassword(), storedUser.getPassword())).thenReturn(true);
        when(jwtService.generateToken(storedUser)).thenReturn("generated.jwt.token");
        when(jwtService.getExpirationSeconds()).thenReturn(86_400L);

        // --- ACT ---
        AuthResponse response = userService.login(request);

        // --- ASSERT ---
        assertThat(response.getToken()).isEqualTo("generated.jwt.token");
        assertThat(response.getTokenType()).isEqualTo("Bearer");
        assertThat(response.getExpiresIn()).isEqualTo(86_400L);
    }

    // =========================================================
    // Login — error cases
    // =========================================================

    /**
     * When the email does not exist in the database, login must throw
     * {@link BadCredentialsException} with a generic message.
     *
     * <p>The same exception type is used for both bad-email and bad-password so that
     * the API never reveals which field was wrong (enumeration attack prevention).</p>
     */
    @Test
    void login_throwsBadCredentialsException_whenEmailNotFound() {
        LoginRequest request = buildLoginRequest("nobody@back2kasi.co.za", "secret123");

        when(userRepository.findByEmail(request.getEmail())).thenReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> userService.login(request))
                .isInstanceOf(BadCredentialsException.class);
    }

    /**
     * When the email exists but the password does not match the stored hash,
     * login must throw {@link BadCredentialsException}.
     */
    @Test
    void login_throwsBadCredentialsException_whenPasswordIsWrong() {
        LoginRequest request = buildLoginRequest("kabelo@back2kasi.co.za", "wrongpassword");

        User storedUser = User.builder()
                .id(1L)
                .email("kabelo@back2kasi.co.za")
                .password("hashed_secret123")
                .role(Role.USER)
                .build();

        when(userRepository.findByEmail(request.getEmail())).thenReturn(java.util.Optional.of(storedUser));
        // BCrypt comparison returns false — wrong password
        when(passwordEncoder.matches(request.getPassword(), storedUser.getPassword())).thenReturn(false);

        assertThatThrownBy(() -> userService.login(request))
                .isInstanceOf(BadCredentialsException.class);
    }

    // =========================================================
    // Helpers
    // =========================================================

    /**
     * Builds a mock {@link RegisterRequest} using {@code lenient()} stubbing.
     *
     * <p>Why {@code lenient()}? Mockito's default strict mode throws
     * {@link org.mockito.exceptions.misusing.UnnecessaryStubbingException}
     * if a stub is set up but never called during a test. In the
     * duplicate-email scenario the service throws {@link IllegalStateException}
     * immediately after {@code existsByEmail()} returns {@code true}, so it
     * never reaches {@code getFirstName()}, {@code getLastName()}, etc.
     * Using {@code lenient()} tells Mockito: "I know these stubs may not all
     * fire — that is intentional."</p>
     */
    private RegisterRequest buildRequest(
            String firstName, String lastName,
            String email, String password, String phoneNumber
    ) {
        RegisterRequest request = mock(RegisterRequest.class);
        lenient().when(request.getFirstName()).thenReturn(firstName);
        lenient().when(request.getLastName()).thenReturn(lastName);
        lenient().when(request.getEmail()).thenReturn(email);
        lenient().when(request.getPassword()).thenReturn(password);
        lenient().when(request.getPhoneNumber()).thenReturn(phoneNumber);
        return request;
    }

    private LoginRequest buildLoginRequest(String email, String password) {
        LoginRequest request = mock(LoginRequest.class);
        lenient().when(request.getEmail()).thenReturn(email);
        lenient().when(request.getPassword()).thenReturn(password);
        return request;
    }
}
