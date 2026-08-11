package com.back2kasi.business.service;

import com.back2kasi.business.dto.BusinessResponse;
import com.back2kasi.business.dto.CreateBusinessRequest;
import com.back2kasi.business.dto.UpdateBusinessRequest;

import java.util.List;

/**
 * Contract for all business-related operations.
 *
 * <p>Defining a service interface (rather than just a concrete class) provides
 * several benefits:</p>
 * <ul>
 *   <li>Tests can swap the real implementation for a mock without modifying
 *       any code that depends on {@code BusinessService}.</li>
 *   <li>The interface acts as a formal contract — it documents what the service
 *       layer must do, independently of how it does it.</li>
 *   <li>Follows the naming standard defined in {@code DEVELOPMENT_STANDARDS.md}:
 *       {@code BusinessService} (interface) and {@code BusinessServiceImpl} (implementation).</li>
 * </ul>
 *
 * <p>Every method receives {@code ownerId} — the ID of the currently authenticated
 * user. The implementation is responsible for enforcing ownership rules.</p>
 */
public interface BusinessService {

    /**
     * Register a new business owned by the given user.
     *
     * @param request the validated creation payload
     * @param ownerId the ID of the authenticated user who will own this business
     * @return the created business as a response DTO
     */
    BusinessResponse createBusiness(CreateBusinessRequest request, Long ownerId);

    /**
     * Retrieve all businesses owned by the given user.
     *
     * @param ownerId the ID of the authenticated user
     * @return list of the user's businesses; empty list if they own none
     */
    List<BusinessResponse> getMyBusinesses(Long ownerId);

    /**
     * Retrieve a single business by its ID, enforcing ownership.
     *
     * @param id      the business primary key
     * @param ownerId the ID of the authenticated user making the request
     * @return the business as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if no business exists with the given ID
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the business is not owned by this user
     */
    BusinessResponse getBusinessById(Long id, Long ownerId);

    /**
     * Update all mutable fields of an existing business, enforcing ownership.
     *
     * @param id      the primary key of the business to update
     * @param request the validated update payload
     * @param ownerId the ID of the authenticated user making the request
     * @return the updated business as a response DTO
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if no business exists with the given ID
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the business is not owned by this user
     */
    BusinessResponse updateBusiness(Long id, UpdateBusinessRequest request, Long ownerId);

    /**
     * Permanently delete a business, enforcing ownership.
     *
     * @param id      the primary key of the business to delete
     * @param ownerId the ID of the authenticated user making the request
     * @throws com.back2kasi.common.exception.ResourceNotFoundException if no business exists with the given ID
     * @throws com.back2kasi.common.exception.UnauthorizedException     if the business is not owned by this user
     */
    void deleteBusiness(Long id, Long ownerId);
}
