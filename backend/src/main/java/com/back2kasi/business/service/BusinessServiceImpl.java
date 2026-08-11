package com.back2kasi.business.service;

import com.back2kasi.business.dto.BusinessResponse;
import com.back2kasi.business.dto.CreateBusinessRequest;
import com.back2kasi.business.dto.UpdateBusinessRequest;
import com.back2kasi.business.entity.Business;
import com.back2kasi.business.repository.BusinessRepository;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Implementation of {@link BusinessService}.
 *
 * <p>This class sits between the {@code BusinessController} (HTTP layer) and the
 * {@code BusinessRepository} (data access layer). It is the single place where
 * all business-domain rules are enforced:</p>
 * <ul>
 *   <li><strong>Ownership enforcement</strong> — every mutating operation (update, delete)
 *       first verifies that the authenticated user owns the target business.</li>
 *   <li><strong>Not-found handling</strong> — queries that return no result throw
 *       {@link ResourceNotFoundException}, which maps to HTTP 404.</li>
 *   <li><strong>Forbidden access</strong> — ownership mismatches throw
 *       {@link UnauthorizedException}, which maps to HTTP 403.</li>
 * </ul>
 *
 * <p>Layer contract:</p>
 * <pre>
 *   BusinessController  →  BusinessServiceImpl  →  BusinessRepository  →  PostgreSQL
 *       HTTP layer           Business rules           Data access
 * </pre>
 *
 * <p>No layer reaches past its immediate neighbour.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BusinessServiceImpl implements BusinessService {

    private final BusinessRepository businessRepository;
    private final UserRepository userRepository;

    // =========================================================
    // Create
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Steps:</p>
     * <ol>
     *   <li>Load the owner from {@code UserRepository} — throws if user not found
     *       (should not happen in practice since the JWT filter already verified them,
     *       but guarded defensively).</li>
     *   <li>Build the {@link Business} entity from the DTO.</li>
     *   <li>Persist via {@code BusinessRepository}.</li>
     *   <li>Map and return the saved entity as a {@link BusinessResponse}.</li>
     * </ol>
     */
    @Override
    @Transactional
    public BusinessResponse createBusiness(CreateBusinessRequest request, Long ownerId) {
        log.info("Creating business '{}' for ownerId={}", request.name(), ownerId);

        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "User not found with id: " + ownerId
                ));

        Business business = Business.builder()
                .name(request.name())
                .description(request.description())
                .address(request.address())
                .phoneNumber(request.phoneNumber())
                .businessType(request.businessType())
                .owner(owner)
                .build();

        Business saved = businessRepository.save(business);
        log.info("Business created with id={} for ownerId={}", saved.getId(), ownerId);

        return BusinessResponse.from(saved);
    }

    // =========================================================
    // Read
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Returns only businesses where {@code owner_id = ownerId}. An owner
     * can never see businesses belonging to other users via this endpoint.</p>
     */
    @Override
    @Transactional(readOnly = true)
    public List<BusinessResponse> getMyBusinesses(Long ownerId) {
        log.debug("Fetching businesses for ownerId={}", ownerId);

        return businessRepository.findByOwnerId(ownerId)
                .stream()
                .map(BusinessResponse::from)
                .toList();
    }

    /**
     * {@inheritDoc}
     *
     * <p>Two-step lookup:</p>
     * <ol>
     *   <li>Fetch by {@code id} — throws {@link ResourceNotFoundException} if absent.</li>
     *   <li>Verify {@code business.owner.id == ownerId} — throws {@link UnauthorizedException}
     *       if not owned by the caller.</li>
     * </ol>
     *
     * <p>The two-step approach gives precise error messages. A single
     * {@code existsByIdAndOwnerId} check would return the same result for
     * "not found" and "wrong owner", making debugging harder.</p>
     */
    @Override
    @Transactional(readOnly = true)
    public BusinessResponse getBusinessById(Long id, Long ownerId) {
        log.debug("Fetching businessId={} for ownerId={}", id, ownerId);

        Business business = findOrThrow(id);
        verifyOwnership(business, ownerId);

        return BusinessResponse.from(business);
    }

    // =========================================================
    // Update
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Applies every field from {@link UpdateBusinessRequest} to the entity
     * and lets Hibernate's dirty-checking flush the changes on transaction commit.</p>
     */
    @Override
    @Transactional
    public BusinessResponse updateBusiness(Long id, UpdateBusinessRequest request, Long ownerId) {
        log.info("Updating businessId={} for ownerId={}", id, ownerId);

        Business business = findOrThrow(id);
        verifyOwnership(business, ownerId);

        business.setName(request.name());
        business.setDescription(request.description());
        business.setAddress(request.address());
        business.setPhoneNumber(request.phoneNumber());
        business.setBusinessType(request.businessType());

        Business updated = businessRepository.save(business);
        log.info("Business updated: id={}", updated.getId());

        return BusinessResponse.from(updated);
    }

    // =========================================================
    // Delete
    // =========================================================

    /**
     * {@inheritDoc}
     *
     * <p>Hard deletes the row from the {@code businesses} table.
     * No soft-delete flag is used in the MVP.</p>
     */
    @Override
    @Transactional
    public void deleteBusiness(Long id, Long ownerId) {
        log.info("Deleting businessId={} for ownerId={}", id, ownerId);

        Business business = findOrThrow(id);
        verifyOwnership(business, ownerId);

        businessRepository.delete(business);
        log.info("Business deleted: id={}", id);
    }

    // =========================================================
    // Private helpers
    // =========================================================

    /**
     * Fetch a business by its ID or throw {@link ResourceNotFoundException}.
     *
     * <p>Centralises the "find or 404" pattern so it cannot diverge between
     * {@code getBusinessById}, {@code updateBusiness}, and {@code deleteBusiness}.</p>
     */
    private Business findOrThrow(Long id) {
        return businessRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Business not found with id: " + id
                ));
    }

    /**
     * Verify that the given business is owned by the given user ID.
     *
     * @throws UnauthorizedException if the business belongs to a different user
     */
    private void verifyOwnership(Business business, Long ownerId) {
        if (!business.getOwner().getId().equals(ownerId)) {
            throw new UnauthorizedException(
                    "You do not have permission to access this business"
            );
        }
    }
}
