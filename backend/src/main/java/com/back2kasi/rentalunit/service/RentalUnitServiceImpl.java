package com.back2kasi.rentalunit.service;

import com.back2kasi.business.entity.Business;
import com.back2kasi.business.repository.BusinessRepository;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.rentalunit.dto.CreateRentalUnitRequest;
import com.back2kasi.rentalunit.dto.RentalUnitResponse;
import com.back2kasi.rentalunit.dto.UpdateRentalUnitRequest;
import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.rentalunit.repository.RentalUnitRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Implementation of {@link RentalUnitService}.
 *
 * <p>Ownership chain enforced on all write operations:</p>
 * <pre>
 *   User (caller) → Business (parent) → RentalUnit (target)
 * </pre>
 *
 * <p>For <strong>create</strong>: look up the business by {@code businessId},
 * then verify the business is owned by the caller.</p>
 *
 * <p>For <strong>update / delete</strong>: look up the rental unit, then verify
 * {@code unit.getBusiness().getOwner().getId() == ownerId}.</p>
 *
 * <p>Read operations are public and skip ownership checks entirely.</p>
 *
 * <p>Layer contract:</p>
 * <pre>
 *   RentalUnitController  →  RentalUnitServiceImpl  →  RentalUnitRepository  →  PostgreSQL
 * </pre>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RentalUnitServiceImpl implements RentalUnitService {

    private final RentalUnitRepository rentalUnitRepository;
    private final BusinessRepository businessRepository;

    // =========================================================
    // Create
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Steps:</p>
     * <ol>
     *   <li>Fetch the business by {@code businessId} — 404 if not found.</li>
     *   <li>Verify the business is owned by the caller — 403 if not.</li>
     *   <li>Build the {@link RentalUnit} entity with default status {@code AVAILABLE}.</li>
     *   <li>Persist and return the saved entity as a DTO.</li>
     * </ol>
     */
    @Override
    @Transactional
    public RentalUnitResponse createRentalUnit(CreateRentalUnitRequest request, Long ownerId) {
        log.info("Creating rental unit '{}' for businessId={} by ownerId={}",
                request.name(), request.businessId(), ownerId);

        Business business = businessRepository.findById(request.businessId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Business not found with id: " + request.businessId()
                ));

        verifyBusinessOwnership(business, ownerId);

        RentalUnit unit = RentalUnit.builder()
                .name(request.name())
                .description(request.description())
                .pricePerDay(request.pricePerDay())
                .capacity(request.capacity())
                .rentalUnitType(request.rentalUnitType())
                .business(business)
                .build();

        RentalUnit saved = rentalUnitRepository.save(unit);
        log.info("Rental unit created with id={} under businessId={}", saved.getId(), business.getId());

        return RentalUnitResponse.from(saved);
    }

    // =========================================================
    // Read (public — no ownership check)
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Returns all rental units for the given business regardless of status.
     * No ownership check — this is a public read endpoint.</p>
     */
    @Override
    @Transactional(readOnly = true)
    public List<RentalUnitResponse> getRentalUnitsByBusiness(Long businessId) {
        log.debug("Fetching rental units for businessId={}", businessId);

        return rentalUnitRepository.findByBusinessId(businessId)
                .stream()
                .map(RentalUnitResponse::from)
                .toList();
    }

    /**
     * {@inheritDoc}
     *
     * <p>No ownership check — this is a public read endpoint.</p>
     */
    @Override
    @Transactional(readOnly = true)
    public RentalUnitResponse getRentalUnitById(Long id) {
        log.debug("Fetching rentalUnitId={}", id);

        return RentalUnitResponse.from(findOrThrow(id));
    }

    // =========================================================
    // Update
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Applies all fields from the request to the entity (including {@code status}),
     * then lets Hibernate's dirty-checking flush the changes on transaction commit.</p>
     */
    @Override
    @Transactional
    public RentalUnitResponse updateRentalUnit(Long id, UpdateRentalUnitRequest request, Long ownerId) {
        log.info("Updating rentalUnitId={} by ownerId={}", id, ownerId);

        RentalUnit unit = findOrThrow(id);
        verifyUnitOwnership(unit, ownerId);

        unit.setName(request.name());
        unit.setDescription(request.description());
        unit.setPricePerDay(request.pricePerDay());
        unit.setCapacity(request.capacity());
        unit.setRentalUnitType(request.rentalUnitType());
        unit.setStatus(request.status());

        RentalUnit updated = rentalUnitRepository.save(unit);
        log.info("Rental unit updated: id={}", updated.getId());

        return RentalUnitResponse.from(updated);
    }

    // =========================================================
    // Delete
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Hard deletes the row from the {@code rental_units} table.
     * No soft-delete flag is used in the MVP.</p>
     */
    @Override
    @Transactional
    public void deleteRentalUnit(Long id, Long ownerId) {
        log.info("Deleting rentalUnitId={} by ownerId={}", id, ownerId);

        RentalUnit unit = findOrThrow(id);
        verifyUnitOwnership(unit, ownerId);

        rentalUnitRepository.delete(unit);
        log.info("Rental unit deleted: id={}", id);
    }

    // =========================================================
    // Private helpers
    // =========================================================

    /**
     * Fetch a rental unit by ID or throw {@link ResourceNotFoundException}.
     */
    private RentalUnit findOrThrow(Long id) {
        return rentalUnitRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Rental unit not found with id: " + id
                ));
    }

    /**
     * Verify that the given business is owned by the caller.
     *
     * @throws UnauthorizedException if the business belongs to a different user
     */
    private void verifyBusinessOwnership(Business business, Long ownerId) {
        if (!business.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException(
                    "You do not have permission to add units to this business"
            );
        }
    }

    /**
     * Verify that the rental unit's parent business is owned by the caller.
     *
     * <p>This traverses {@code unit → business → owner → id} in memory —
     * the business is already loaded via the lazy-init proxy by this point.</p>
     *
     * @throws UnauthorizedException if the parent business belongs to a different user
     */
    private void verifyUnitOwnership(RentalUnit unit, Long ownerId) {
        if (!unit.getBusiness().getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException(
                    "You do not have permission to modify this rental unit"
            );
        }
    }
}
