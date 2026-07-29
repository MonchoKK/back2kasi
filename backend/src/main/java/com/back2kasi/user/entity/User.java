package com.back2kasi.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

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
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

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

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
