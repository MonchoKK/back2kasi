package com.back2kasi.business.entity;

import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Represents a rental business registered on the Back2Kasi platform.
 *
 * <p>Relationship summary:</p>
 * <pre>
 *   User (1) ──────────&lt; Business (Many)
 * </pre>
 *
 * <p>A {@link User} who owns one or more businesses is effectively a business owner;
 * a user who owns none is effectively a customer. Business ownership is determined
 * entirely by this relationship — not by a special role on the user.</p>
 *
 * <p>The {@code owner} column stores the FK reference to the {@code users} table.
 * Cascade type {@code ALL} with {@code orphanRemoval = true} on the inverse
 * {@code User.businesses} side means that deleting a user also deletes their
 * businesses automatically.</p>
 */
@Entity
@Table(name = "businesses")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Business {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** The public display name of the business. */
    @Column(nullable = false)
    private String name;

    /** Optional tagline or description visible to customers. */
    @Column
    private String description;

    /** The physical street address of the business. */
    @Column(nullable = false)
    private String address;

    /** The business contact phone number. */
    @Column(nullable = false)
    private String phoneNumber;

    /**
     * The category of rental service offered.
     *
     * <p>Stored as a readable string (e.g. {@code "TOILET_RENTAL"}) rather than
     * an ordinal so that future enum reordering does not corrupt existing rows.</p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BusinessType businessType;

    /**
     * The user who owns and manages this business.
     *
     * <p>{@code FetchType.LAZY} — the owner is not loaded from the database unless
     * explicitly accessed. This avoids unnecessary joins on every business query.</p>
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    /**
     * All rental units that belong to this business.
     *
     * <p>{@code CascadeType.ALL} and {@code orphanRemoval = true} ensure that
     * deleting a business also permanently deletes all of its rental units.</p>
     */
    @OneToMany(mappedBy = "business", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<RentalUnit> rentalUnits = new ArrayList<>();

    /** Automatically set by Hibernate on first save. Never updated thereafter. */
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /** Automatically updated by Hibernate on every save. */
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
