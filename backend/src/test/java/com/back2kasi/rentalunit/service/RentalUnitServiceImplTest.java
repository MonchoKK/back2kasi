package com.back2kasi.rentalunit.service;

import com.back2kasi.business.entity.Business;
import com.back2kasi.business.entity.BusinessType;
import com.back2kasi.business.repository.BusinessRepository;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.rentalunit.dto.CreateRentalUnitRequest;
import com.back2kasi.rentalunit.dto.RentalUnitResponse;
import com.back2kasi.rentalunit.dto.UpdateRentalUnitRequest;
import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.rentalunit.entity.RentalUnitStatus;
import com.back2kasi.rentalunit.entity.RentalUnitType;
import com.back2kasi.rentalunit.repository.RentalUnitRepository;
import com.back2kasi.user.entity.Role;
import com.back2kasi.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link RentalUnitServiceImpl}.
 *
 * <p>Pure unit test — no Spring context, no database. All collaborators are
 * replaced with Mockito mocks so each test exercises only the logic inside
 * {@code RentalUnitServiceImpl}.</p>
 *
 * <p>Key scenarios covered:</p>
 * <ul>
 *   <li>Happy-path CRUD</li>
 *   <li>{@link ResourceNotFoundException} when business or unit is not found</li>
 *   <li>{@link UnauthorizedException} on ownership mismatch (both business and unit)</li>
 *   <li>Public reads (no ownership check)</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class RentalUnitServiceImplTest {

    @Mock
    private RentalUnitRepository rentalUnitRepository;

    @Mock
    private BusinessRepository businessRepository;

    @InjectMocks
    private RentalUnitServiceImpl rentalUnitService;

    // --- Fixtures ---

    private User owner;
    private User otherUser;
    private Business business;
    private RentalUnit unit;

    @BeforeEach
    void setUp() {
        owner = User.builder()
                .id(1L).firstName("Kabelo").lastName("Kekana")
                .email("kabelo@back2kasi.co.za").password("hashed")
                .phoneNumber("+27712345678").role(Role.USER)
                .build();

        otherUser = User.builder()
                .id(2L).email("other@back2kasi.co.za")
                .password("hashed").role(Role.USER)
                .build();

        business = Business.builder()
                .id(10L).name("Kasi Toilets").address("123 Soweto Rd")
                .phoneNumber("+27711234567").businessType(BusinessType.TOILET_RENTAL)
                .owner(owner)
                .createdAt(LocalDateTime.now()).updatedAt(LocalDateTime.now())
                .build();

        unit = RentalUnit.builder()
                .id(100L).name("Unit A").description("Standard toilet")
                .pricePerDay(new BigDecimal("150.00")).capacity(1)
                .rentalUnitType(RentalUnitType.STANDARD_TOILET)
                .status(RentalUnitStatus.AVAILABLE)
                .business(business)
                .createdAt(LocalDateTime.now()).updatedAt(LocalDateTime.now())
                .build();
    }

    // =========================================================
    // createRentalUnit
    // =========================================================

    @Test
    void createRentalUnit_savesAndReturnsResponse_whenOwnerMatchesBusiness() {
        // ARRANGE
        CreateRentalUnitRequest request = new CreateRentalUnitRequest(
                10L, "Unit A", "Standard toilet",
                new BigDecimal("150.00"), 1, RentalUnitType.STANDARD_TOILET
        );
        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));
        when(rentalUnitRepository.save(any(RentalUnit.class))).thenReturn(unit);

        // ACT
        RentalUnitResponse response = rentalUnitService.createRentalUnit(request, 1L);

        // ASSERT
        assertThat(response.name()).isEqualTo("Unit A");
        assertThat(response.status()).isEqualTo(RentalUnitStatus.AVAILABLE);
        assertThat(response.businessId()).isEqualTo(10L);

        ArgumentCaptor<RentalUnit> captor = ArgumentCaptor.forClass(RentalUnit.class);
        verify(rentalUnitRepository).save(captor.capture());
        assertThat(captor.getValue().getBusiness()).isEqualTo(business);
    }

    @Test
    void createRentalUnit_throws404_whenBusinessNotFound() {
        CreateRentalUnitRequest request = new CreateRentalUnitRequest(
                999L, "Unit A", null,
                new BigDecimal("150.00"), 1, RentalUnitType.STANDARD_TOILET
        );
        when(businessRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> rentalUnitService.createRentalUnit(request, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Business not found with id: 999");

        verify(rentalUnitRepository, never()).save(any());
    }

    @Test
    void createRentalUnit_throws403_whenCallerDoesNotOwnBusiness() {
        CreateRentalUnitRequest request = new CreateRentalUnitRequest(
                10L, "Unit A", null,
                new BigDecimal("150.00"), 1, RentalUnitType.STANDARD_TOILET
        );
        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));

        // Caller is otherUser (id=2), but business is owned by owner (id=1)
        assertThatThrownBy(() -> rentalUnitService.createRentalUnit(request, 2L))
                .isInstanceOf(UnauthorizedException.class);

        verify(rentalUnitRepository, never()).save(any());
    }

    // =========================================================
    // getRentalUnitsByBusiness
    // =========================================================

    @Test
    void getRentalUnitsByBusiness_returnsList() {
        when(rentalUnitRepository.findByBusinessId(10L)).thenReturn(List.of(unit));

        List<RentalUnitResponse> result = rentalUnitService.getRentalUnitsByBusiness(10L);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().name()).isEqualTo("Unit A");
    }

    @Test
    void getRentalUnitsByBusiness_returnsEmptyList_whenNoneExist() {
        when(rentalUnitRepository.findByBusinessId(10L)).thenReturn(List.of());

        assertThat(rentalUnitService.getRentalUnitsByBusiness(10L)).isEmpty();
    }

    // =========================================================
    // getRentalUnitById
    // =========================================================

    @Test
    void getRentalUnitById_returnsResponse_whenFound() {
        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));

        RentalUnitResponse response = rentalUnitService.getRentalUnitById(100L);

        assertThat(response.id()).isEqualTo(100L);
        assertThat(response.name()).isEqualTo("Unit A");
    }

    @Test
    void getRentalUnitById_throws404_whenNotFound() {
        when(rentalUnitRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> rentalUnitService.getRentalUnitById(999L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Rental unit not found with id: 999");
    }

    // =========================================================
    // updateRentalUnit
    // =========================================================

    @Test
    void updateRentalUnit_updatesFieldsAndReturnsResponse_whenOwnerMatches() {
        UpdateRentalUnitRequest request = new UpdateRentalUnitRequest(
                "Unit A Updated", "New description",
                new BigDecimal("200.00"), 2,
                RentalUnitType.VIP_TOILET, RentalUnitStatus.UNDER_MAINTENANCE
        );

        RentalUnit updatedUnit = RentalUnit.builder()
                .id(100L).name("Unit A Updated").description("New description")
                .pricePerDay(new BigDecimal("200.00")).capacity(2)
                .rentalUnitType(RentalUnitType.VIP_TOILET)
                .status(RentalUnitStatus.UNDER_MAINTENANCE)
                .business(business)
                .createdAt(unit.getCreatedAt()).updatedAt(LocalDateTime.now())
                .build();

        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));
        when(rentalUnitRepository.save(any(RentalUnit.class))).thenReturn(updatedUnit);

        RentalUnitResponse response = rentalUnitService.updateRentalUnit(100L, request, 1L);

        assertThat(response.name()).isEqualTo("Unit A Updated");
        assertThat(response.status()).isEqualTo(RentalUnitStatus.UNDER_MAINTENANCE);
        assertThat(response.pricePerDay()).isEqualByComparingTo("200.00");
    }

    @Test
    void updateRentalUnit_throws403_whenOwnerMismatch() {
        UpdateRentalUnitRequest request = new UpdateRentalUnitRequest(
                "Hack", null, new BigDecimal("1.00"), 1,
                RentalUnitType.STANDARD_TOILET, RentalUnitStatus.AVAILABLE
        );
        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));

        assertThatThrownBy(() -> rentalUnitService.updateRentalUnit(100L, request, 2L))
                .isInstanceOf(UnauthorizedException.class);

        verify(rentalUnitRepository, never()).save(any());
    }

    // =========================================================
    // deleteRentalUnit
    // =========================================================

    @Test
    void deleteRentalUnit_deletesSuccessfully_whenOwnerMatches() {
        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));

        rentalUnitService.deleteRentalUnit(100L, 1L);

        verify(rentalUnitRepository).delete(unit);
    }

    @Test
    void deleteRentalUnit_throws403_whenOwnerMismatch() {
        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));

        assertThatThrownBy(() -> rentalUnitService.deleteRentalUnit(100L, 2L))
                .isInstanceOf(UnauthorizedException.class);

        verify(rentalUnitRepository, never()).delete(any());
    }

    @Test
    void deleteRentalUnit_throws404_whenNotFound() {
        when(rentalUnitRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> rentalUnitService.deleteRentalUnit(999L, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Rental unit not found with id: 999");

        verify(rentalUnitRepository, never()).delete(any());
    }
}
