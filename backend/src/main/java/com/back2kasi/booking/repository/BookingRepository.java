package com.back2kasi.booking.repository;

import com.back2kasi.booking.entity.Booking;
import com.back2kasi.booking.entity.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

/**
 * Data-access interface for {@link Booking} entities.
 *
 * <p>Extends {@link JpaRepository} for standard CRUD operations. Custom finder
 * methods use Spring Data's derived-query naming convention where possible; the
 * overlap check uses an explicit {@code @Query} because the date-range predicate
 * cannot be expressed with derived names alone.</p>
 */
@Repository
public interface BookingRepository extends JpaRepository<Booking, Long> {

    /**
     * Find all bookings made by a specific customer.
     *
     * @param customerId the primary key of the customer
     * @return list of bookings, most-recently-created first (natural DB order)
     */
    List<Booking> findByCustomerId(Long customerId);

    /**
     * Find all bookings for rental units belonging to a specific business owner.
     *
     * <p>Traverses: {@code Booking → rentalUnit → business → owner → id}.
     * This lets an owner see all bookings across all their units in one query.</p>
     *
     * @param ownerId the primary key of the business owner
     * @return list of bookings across all of this owner's rental units
     */
    List<Booking> findByRentalUnitBusinessOwnerId(Long ownerId);

    /**
     * Find all bookings for a specific rental unit.
     *
     * @param rentalUnitId the primary key of the rental unit
     * @return list of bookings for that unit
     */
    List<Booking> findByRentalUnitId(Long rentalUnitId);

    /**
     * Check whether a date range overlaps any existing {@code CONFIRMED} booking
     * for the given rental unit.
     *
     * <p>Overlap condition — two ranges {@code [A, B]} and {@code [C, D]} overlap
     * when {@code A <= D} AND {@code B >= C}. The query excludes the booking
     * identified by {@code excludeBookingId} so that updating an existing booking
     * does not falsely conflict with itself. Pass {@code -1L} (or any non-existent
     * ID) when creating a new booking.</p>
     *
     * @param rentalUnitId    the primary key of the unit to check
     * @param startDate       the proposed start date (inclusive)
     * @param endDate         the proposed end date (inclusive)
     * @param status          the status to filter on (typically {@code CONFIRMED})
     * @param excludeBookingId booking ID to exclude from the check (use {@code -1L} for new bookings)
     * @return {@code true} if a conflicting booking exists
     */
    @Query("""
            SELECT COUNT(b) > 0
            FROM Booking b
            WHERE b.rentalUnit.id = :rentalUnitId
              AND b.status = :status
              AND b.id <> :excludeBookingId
              AND b.startDate <= :endDate
              AND b.endDate >= :startDate
            """)
    boolean existsOverlappingBooking(
            @Param("rentalUnitId") Long rentalUnitId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("status") BookingStatus status,
            @Param("excludeBookingId") Long excludeBookingId
    );
}
