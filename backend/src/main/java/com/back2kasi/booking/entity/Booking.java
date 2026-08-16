package com.back2kasi.booking.entity;

import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Represents a customer's reservation of a {@link RentalUnit} for a date range.
 *
 * <p>Relationship summary:</p>
 * <pre>
 *   User (customer) (1) ──────────< Booking (Many)
 *   RentalUnit      (1) ──────────< Booking (Many)
 * </pre>
 *
 * <p>Ownership check path for write operations:</p>
 * <pre>
 *   caller == booking.customer          → customer operations (cancel only)
 *   caller == booking.rentalUnit.business.owner → owner operations (confirm, complete, cancel)
 * </pre>
 *
 * <p>{@code totalPrice} is computed at creation time as
 * {@code pricePerDay × ChronoUnit.DAYS.between(startDate, endDate)} and stored
 * so that future price changes on the unit do not retroactively alter existing
 * bookings.</p>
 *
 * <p>Both {@code startDate} and {@code endDate} are inclusive. A single-day
 * booking has {@code startDate == endDate}, billed at one day's rate.</p>
 */
@Entity
@Table(name = "bookings")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * The rental unit being booked.
     *
     * <p>{@code FetchType.LAZY} — the unit (and transitively its business and owner)
     * is not loaded unless explicitly accessed. Avoids unnecessary JOINs on list queries.</p>
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "rental_unit_id", nullable = false)
    private RentalUnit rentalUnit;

    /**
     * The customer who made this booking.
     *
     * <p>This is the authenticated user at creation time — not the business owner.</p>
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false)
    private User customer;

    /** Inclusive start date of the rental period. */
    @Column(nullable = false)
    private LocalDate startDate;

    /** Inclusive end date of the rental period. */
    @Column(nullable = false)
    private LocalDate endDate;

    /**
     * Total price locked in at booking creation time.
     *
     * <p>Computed as {@code rentalUnit.pricePerDay × days} and stored so that
     * future price changes on the unit do not affect this booking.</p>
     */
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal totalPrice;

    /**
     * Current lifecycle state of this booking.
     *
     * <p>Starts at {@link BookingStatus#PENDING}. Transitions are enforced
     * in {@code BookingServiceImpl}.</p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private BookingStatus status = BookingStatus.PENDING;

    /** Optional note from the customer (e.g. special requirements). */
    @Column
    private String notes;

    /** Set automatically by Hibernate on first save. Never updated thereafter. */
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /** Updated automatically by Hibernate on every save. */
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
