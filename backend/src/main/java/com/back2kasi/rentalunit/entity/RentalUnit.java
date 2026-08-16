package com.back2kasi.rentalunit.entity;

import com.back2kasi.booking.entity.Booking;
import com.back2kasi.business.entity.Business;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Represents a single physical rental unit owned by a {@link Business}.
 *
 * <p>Relationship summary:</p>
 * <pre>
 *   User (1) ──────────&lt; Business (Many) ──────────&lt; RentalUnit (Many)
 * </pre>
 *
 * <p>A {@code RentalUnit} does not belong directly to a {@code User} —
 * ownership is indirect: the user owns the business, and the business owns
 * the units. All ownership checks on a rental unit must therefore verify
 * the full chain: {@code rentalUnit.getBusiness().getOwner().getId() == callerId}.</p>
 *
 * <p>A rental unit does <strong>not</strong> carry its own address — it
 * operates from the same location as its parent {@link Business}.</p>
 *
 * <p>The {@code pricePerDay} field uses {@link BigDecimal} rather than
 * {@code double} because floating-point arithmetic introduces rounding
 * errors that accumulate in financial calculations.</p>
 */
@Entity
@Table(name = "rental_units")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RentalUnit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Display label for this unit — e.g. "Unit A", "VIP Toilet 3". */
    @Column(nullable = false)
    private String name;

    /** Optional detail or marketing description visible to customers. */
    @Column
    private String description;

    /**
     * Daily rental rate in South African Rand.
     *
     * <p>Uses {@link BigDecimal} for exact decimal arithmetic.
     * Stored with {@code precision = 10, scale = 2} to represent values
     * up to R 99 999 999.99.</p>
     */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal pricePerDay;

    /**
     * Maximum number of users (or occupancy units) per booking period.
     * For a toilet this might be 1; for a cold room it might be a volume or event size.
     */
    @Column(nullable = false)
    private Integer capacity;

    /**
     * The sub-type of this rental unit (e.g. {@code VIP_TOILET}).
     * Stored as a readable string rather than an ordinal.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RentalUnitType rentalUnitType;

    /**
     * Current operational status of the unit.
     *
     * <p>Defaults to {@link RentalUnitStatus#AVAILABLE} when a unit is first created.
     * Updated manually by the owner in Sprint 4; will be automated by the
     * Booking system in Sprint 5.</p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private RentalUnitStatus status = RentalUnitStatus.AVAILABLE;

    /**
     * The business that owns and operates this rental unit.
     *
     * <p>{@code FetchType.LAZY} — the {@link Business} (and transitively its owner
     * {@code User}) is not loaded unless explicitly accessed, avoiding unnecessary
     * JOINs on list queries.</p>
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    /**
     * All bookings made for this rental unit.
     *
     * <p>{@code CascadeType.ALL} and {@code orphanRemoval = true} ensure that
     * deleting a rental unit also permanently deletes all of its bookings.</p>
     */
    @OneToMany(mappedBy = "rentalUnit", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Booking> bookings = new ArrayList<>();

    /** Set automatically by Hibernate on first save. Never updated thereafter. */
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /** Updated automatically by Hibernate on every save. */
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
