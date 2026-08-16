package com.back2kasi.rentalunit.service;

import com.back2kasi.rentalunit.dto.CreateRentalUnitRequest;
import com.back2kasi.rentalunit.dto.RentalUnitResponse;
import com.back2kasi.rentalunit.dto.UpdateRentalUnitRequest;

import java.util.List;

/**
 * Contract for all rental unit operations.
 *
 * <p>Read operations ({@link #getRentalUnitsByBusiness} and {@link #getRentalUnitById})
 * are <strong>public</strong> — they do not require an {@code ownerId} because
 * any visitor to the platform can browse available units without logging in.</p>
 *
 * <p>Write operations (create, update, delete) are <strong>owner-only</strong>
 * and receive {@code ownerId} so the implementation can enforce the full
 * ownership chain: caller → business → rental unit.</p>
 */
public interface RentalUnitService {

    /**
     * Create a new rental unit under an existing business.
     *
     * @param request the validated creation payload (includes {@code businessId})
     * @param ownerId the ID of the authenticated user making the request
     * @return the created rental unit as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if the business does not exist
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the caller does not own the business
     */
    RentalUnitResponse createRentalUnit(CreateRentalUnitRequest request, Long ownerId);

    /**
     * Retrieve all rental units for a specific business.
     *
     * <p>Public — no ownership check required.</p>
     *
     * @param businessId the primary key of the business to query
     * @return list of rental units; empty list if the business has none
     */
    List<RentalUnitResponse> getRentalUnitsByBusiness(Long businessId);

    /**
     * Retrieve a single rental unit by its ID.
     *
     * <p>Public — no ownership check required.</p>
     *
     * @param id the primary key of the rental unit
     * @return the rental unit as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if no unit exists with the given ID
     */
    RentalUnitResponse getRentalUnitById(Long id);

    /**
     * Update all mutable fields of an existing rental unit, enforcing ownership.
     *
     * @param id      the primary key of the unit to update
     * @param request the validated update payload
     * @param ownerId the ID of the authenticated user making the request
     * @return the updated unit as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if no unit exists with the given ID
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the caller does not own the parent business
     */
    RentalUnitResponse updateRentalUnit(Long id, UpdateRentalUnitRequest request, Long ownerId);

    /**
     * Permanently delete a rental unit, enforcing ownership.
     *
     * @param id      the primary key of the unit to delete
     * @param ownerId the ID of the authenticated user making the request
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if no unit exists with the given ID
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the caller does not own the parent business
     */
    void deleteRentalUnit(Long id, Long ownerId);
}
