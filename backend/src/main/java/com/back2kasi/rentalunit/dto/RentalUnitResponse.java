package com.back2kasi.rentalunit.dto;

import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.rentalunit.entity.RentalUnitStatus;
import com.back2kasi.rentalunit.entity.RentalUnitType;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Outbound DTO representing a rental unit returned to the client.
 *
 * <p>The full {@link RentalUnit} entity is never exposed directly. This record
 * defines the stable, public API shape. Key design decisions:</p>
 * <ul>
 *   <li>Only {@code businessId} is included — not the full {@link com.back2kasi.business.entity.Business}
 *       object — to avoid leaking unrelated business data to the caller.</li>
 *   <li>{@code pricePerDay} is expressed as {@link BigDecimal} for exact decimal
 *       representation on both sides of the API boundary.</li>
 *   <li>The static factory method {@link #from(RentalUnit)} is the single canonical
 *       mapping point — any schema change only needs updating here.</li>
 * </ul>
 */
public record RentalUnitResponse(
        Long id,
        String name,
        String description,
        BigDecimal pricePerDay,
        Integer capacity,
        RentalUnitType rentalUnitType,
        RentalUnitStatus status,
        Long businessId,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    /**
     * Map a {@link RentalUnit} entity to a {@link RentalUnitResponse} DTO.
     *
     * @param unit the entity to map; must not be {@code null}
     * @return a fully populated response DTO
     */
    public static RentalUnitResponse from(RentalUnit unit) {
        return new RentalUnitResponse(
                unit.getId(),
                unit.getName(),
                unit.getDescription(),
                unit.getPricePerDay(),
                unit.getCapacity(),
                unit.getRentalUnitType(),
                unit.getStatus(),
                unit.getBusiness().getId(),
                unit.getCreatedAt(),
                unit.getUpdatedAt()
        );
    }
}
