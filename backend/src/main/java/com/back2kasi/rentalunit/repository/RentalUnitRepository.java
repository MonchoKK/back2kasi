package com.back2kasi.rentalunit.repository;

import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.rentalunit.entity.RentalUnitStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

/**
 * Data access layer for {@link RentalUnit} entities.
 *
 * <p>Extends {@link JpaRepository} for full CRUD and pagination.
 * Custom query methods are expressed as method names —
 * Spring Data JPA translates them into SQL at startup.</p>
 *
 * <p>Key queries and their SQL equivalents:</p>
 * <ul>
 *   <li>{@code findByBusinessId} → {@code WHERE business_id = ?}</li>
 *   <li>{@code findByBusinessIdAndStatus} → {@code WHERE business_id = ? AND status = ?}</li>
 *   <li>{@code existsByIdAndBusiness_OwnerId} → {@code SELECT EXISTS(WHERE id = ? AND business.owner_id = ?)}</li>
 * </ul>
 *
 * <p>The underscore in {@code Business_OwnerId} is Spring Data's path-traversal
 * separator — it navigates {@code RentalUnit → business → owner → id}.</p>
 */
public interface RentalUnitRepository extends JpaRepository<RentalUnit, Long> {

    /**
     * Find all rental units belonging to a specific business.
     *
     * @param businessId the primary key of the owning business
     * @return list of rental units; empty list if the business has none
     */
    List<RentalUnit> findByBusinessId(Long businessId);

    /**
     * Find all rental units for a business filtered by their current status.
     *
     * <p>Useful for customers who want to browse only {@code AVAILABLE} units
     * without fetching all units and filtering in application code.</p>
     *
     * @param businessId the primary key of the owning business
     * @param status     the status to filter by
     * @return filtered list of rental units
     */
    List<RentalUnit> findByBusinessIdAndStatus(Long businessId, RentalUnitStatus status);

    /**
     * Check whether the given rental unit is owned (indirectly) by the given user.
     *
     * <p>Spring Data navigates the {@code RentalUnit → business → owner → id} path,
     * generating a JOIN query. This verifies the full ownership chain in a single
     * database round-trip rather than loading entities and checking in Java.</p>
     *
     * <p>SQL equivalent:
     * {@code SELECT EXISTS(SELECT 1 FROM rental_units ru JOIN businesses b ON ru.business_id = b.id WHERE ru.id = ? AND b.owner_id = ?)}</p>
     *
     * @param id      the rental unit primary key
     * @param ownerId the primary key of the expected ultimate owner (the {@code User})
     * @return {@code true} if the unit exists AND its business is owned by the given user
     */
    boolean existsByIdAndBusiness_OwnerId(Long id, Long ownerId);

    /**
     * Find all rental units with a given status, across all businesses.
     *
     * <p>Used by the public browse endpoint to list all {@code AVAILABLE}
     * units platform-wide. SQL: {@code WHERE status = ?}</p>
     *
     * @param status the status to filter by
     * @return list of matching rental units; empty if none match
     */
    List<RentalUnit> findByStatus(RentalUnitStatus status);

    /**
     * Fetch a rental unit with a pessimistic write lock (SELECT ... FOR UPDATE).
     * Prevents race conditions during booking confirmations and status changes.
     *
     * @param id the primary key of the rental unit
     * @return optional containing the locked unit if found
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM RentalUnit r WHERE r.id = :id")
    Optional<RentalUnit> findByIdWithLock(@Param("id") Long id);
}
