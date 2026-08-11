package com.back2kasi.business.dto;

import com.back2kasi.business.entity.Business;
import com.back2kasi.business.entity.BusinessType;

import java.time.LocalDateTime;

/**
 * Outbound DTO representing a business returned to the client.
 *
 * <p>The full {@link Business} entity is never exposed directly. Instead, this
 * record defines the stable, public API shape. Key design decisions:</p>
 * <ul>
 *   <li>Only {@code ownerId} is included — not the full {@link com.back2kasi.user.entity.User}
 *       object — to avoid leaking sensitive user data (email, password hash, etc.).</li>
 *   <li>Audit timestamps ({@code createdAt}, {@code updatedAt}) are included so
 *       clients can display "registered since" or sort by recency.</li>
 * </ul>
 *
 * <p>The static factory method {@link #from(Business)} is the single, canonical
 * place to map a {@link Business} entity to this DTO. Any time the mapping
 * logic changes, it only needs to change here.</p>
 */
public record BusinessResponse(
        Long id,
        String name,
        String description,
        String address,
        String phoneNumber,
        BusinessType businessType,
        Long ownerId,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    /**
     * Map a {@link Business} entity to a {@link BusinessResponse} DTO.
     *
     * @param business the entity to map; must not be {@code null}
     * @return a fully populated response DTO
     */
    public static BusinessResponse from(Business business) {
        return new BusinessResponse(
                business.getId(),
                business.getName(),
                business.getDescription(),
                business.getAddress(),
                business.getPhoneNumber(),
                business.getBusinessType(),
                business.getOwner().getId(),
                business.getCreatedAt(),
                business.getUpdatedAt()
        );
    }
}
