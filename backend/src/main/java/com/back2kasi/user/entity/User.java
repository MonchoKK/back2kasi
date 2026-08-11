package com.back2kasi.user.entity;

import com.back2kasi.business.entity.Business;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Represents a registered user on the Back2Kasi platform.
 *
 * <p>A User is simply a user. Whether they act as a business owner depends on
 * whether they own any {@code Business} entities — not on their role field.
 * The role field controls platform-level access only (e.g. ADMIN vs USER).</p>
 *
 * <p>Relationship summary:</p>
 * <pre>
 *   User (1) ──────────< Business (Many)
 * </pre>
 * <p>A user who owns one or more businesses is effectively a business owner;
 * a user who owns none is effectively a customer. Both are the same entity.</p>
 *
 * <p>This entity implements {@link UserDetails} so that Spring Security can use it
 * directly. {@link #getUsername()} returns the email (our unique login identity),
 * and {@link #getAuthorities()} maps the {@link Role} enum to Spring's
 * {@code ROLE_} convention (e.g. {@code ROLE_USER}).</p>
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String phoneNumber;

    /**
     * Platform-level role. Defaults to {@link Role#USER} for every registrant.
     * Business ownership is determined by the User → Business relationship,
     * not by this field.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    /**
     * All businesses owned by this user.
     *
     * <p>{@code mappedBy = "owner"} tells JPA that the {@code Business.owner}
     * field owns the FK column — no extra join table is created.</p>
     *
     * <p>{@code CascadeType.ALL} and {@code orphanRemoval = true} ensure that
     * deleting a user also deletes all of their businesses automatically.</p>
     */
    @OneToMany(mappedBy = "owner", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Business> businesses = new ArrayList<>();

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    // =========================================================
    // UserDetails implementation
    // =========================================================

    /**
     * Returns the authorities granted to the user.
     *
     * <p>Spring Security's convention is to prefix role names with {@code ROLE_}.
     * So {@link Role#USER} becomes {@code ROLE_USER}, and a controller annotated
     * with {@code @PreAuthorize("hasRole('USER')")} will accept this token.</p>
     */
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    /**
     * The username in Spring Security's terms is our email address —
     * the unique identifier we use to look up and authenticate users.
     */
    @Override
    public String getUsername() {
        return email;
    }

    // The four boolean flags below return true for now.
    // Account-locking, credential-expiry, and suspension logic will be
    // introduced in a future sprint if business rules require it.

    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isAccountNonLocked()      { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled()               { return true; }
}
