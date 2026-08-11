package com.back2kasi.business.service;

import com.back2kasi.business.dto.BusinessResponse;
import com.back2kasi.business.dto.CreateBusinessRequest;
import com.back2kasi.business.dto.UpdateBusinessRequest;
import com.back2kasi.business.entity.Business;
import com.back2kasi.business.entity.BusinessType;
import com.back2kasi.business.repository.BusinessRepository;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.user.entity.Role;
import com.back2kasi.user.entity.User;
import com.back2kasi.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link BusinessServiceImpl}.
 *
 * <p>This is a <strong>pure unit test</strong>: no Spring context is loaded,
 * no database is involved. All collaborators are replaced with Mockito mocks
 * so each test exercises only the logic inside {@code BusinessServiceImpl}.</p>
 *
 * <p>Key areas covered:</p>
 * <ul>
 *   <li>Happy-path CRUD operations</li>
 *   <li>ResourceNotFoundException on missing business</li>
 *   <li>UnauthorizedException on ownership mismatch</li>
 *   <li>Correct field mapping between DTO and entity</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class BusinessServiceImplTest {

    @Mock
    private BusinessRepository businessRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private BusinessServiceImpl businessService;

    // --- Shared test fixtures ---

    private User owner;
    private User otherUser;
    private Business business;

    @BeforeEach
    void setUp() {
        owner = User.builder()
                .id(1L)
                .firstName("Kabelo")
                .lastName("Kekana")
                .email("kabelo@back2kasi.co.za")
                .password("hashed")
                .phoneNumber("+27712345678")
                .role(Role.USER)
                .build();

        otherUser = User.builder()
                .id(2L)
                .email("other@back2kasi.co.za")
                .password("hashed")
                .role(Role.USER)
                .build();

        business = Business.builder()
                .id(10L)
                .name("Kasi Toilets")
                .description("Portable toilet hire")
                .address("123 Soweto Rd")
                .phoneNumber("+27711234567")
                .businessType(BusinessType.TOILET_RENTAL)
                .owner(owner)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    // =========================================================
    // createBusiness
    // =========================================================

    /**
     * A valid creation request must result in a saved entity whose fields
     * exactly match the request payload, and the response must reflect them.
     */
    @Test
    void createBusiness_savesAndReturnsResponse_whenOwnerExists() {
        // ARRANGE
        CreateBusinessRequest request = new CreateBusinessRequest(
                "Kasi Toilets", "Portable toilet hire",
                "123 Soweto Rd", "+27711234567", BusinessType.TOILET_RENTAL
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(owner));
        when(businessRepository.save(any(Business.class))).thenReturn(business);

        // ACT
        BusinessResponse response = businessService.createBusiness(request, 1L);

        // ASSERT
        assertThat(response.name()).isEqualTo("Kasi Toilets");
        assertThat(response.businessType()).isEqualTo(BusinessType.TOILET_RENTAL);
        assertThat(response.ownerId()).isEqualTo(1L);

        // Verify the entity passed to save has the right owner
        ArgumentCaptor<Business> captor = ArgumentCaptor.forClass(Business.class);
        verify(businessRepository).save(captor.capture());
        assertThat(captor.getValue().getOwner()).isEqualTo(owner);
    }

    /**
     * If the owner user ID is not in the database, the service must throw
     * ResourceNotFoundException (should not happen in practice since JWT
     * filter ensures the user exists — tested defensively).
     */
    @Test
    void createBusiness_throwsResourceNotFound_whenOwnerNotFound() {
        // ARRANGE
        CreateBusinessRequest request = new CreateBusinessRequest(
                "Kasi Toilets", null, "123 Soweto Rd",
                "+27711234567", BusinessType.TOILET_RENTAL
        );
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        // ACT + ASSERT
        assertThatThrownBy(() -> businessService.createBusiness(request, 99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("User not found");

        verify(businessRepository, never()).save(any());
    }

    // =========================================================
    // getMyBusinesses
    // =========================================================

    /**
     * The service must return all businesses belonging to the given owner
     * mapped to response DTOs.
     */
    @Test
    void getMyBusinesses_returnsListForOwner() {
        // ARRANGE
        Business second = Business.builder()
                .id(11L)
                .name("Cold Kings")
                .address("456 Alex Rd")
                .phoneNumber("+27722222222")
                .businessType(BusinessType.COLD_ROOM_RENTAL)
                .owner(owner)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        when(businessRepository.findByOwnerId(1L)).thenReturn(List.of(business, second));

        // ACT
        List<BusinessResponse> result = businessService.getMyBusinesses(1L);

        // ASSERT
        assertThat(result).hasSize(2);
        assertThat(result).extracting(BusinessResponse::name)
                .containsExactly("Kasi Toilets", "Cold Kings");
    }

    /**
     * When an owner has no businesses, the list must be empty (not null, not an exception).
     */
    @Test
    void getMyBusinesses_returnsEmptyList_whenOwnerHasNone() {
        when(businessRepository.findByOwnerId(1L)).thenReturn(List.of());

        List<BusinessResponse> result = businessService.getMyBusinesses(1L);

        assertThat(result).isEmpty();
    }

    // =========================================================
    // getBusinessById
    // =========================================================

    /**
     * When the business exists and the caller is the owner, the correct
     * response DTO must be returned.
     */
    @Test
    void getBusinessById_returnsResponse_whenOwnerMatches() {
        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));

        BusinessResponse response = businessService.getBusinessById(10L, 1L);

        assertThat(response.id()).isEqualTo(10L);
        assertThat(response.name()).isEqualTo("Kasi Toilets");
    }

    /**
     * When no business with the given ID exists, ResourceNotFoundException must be thrown.
     */
    @Test
    void getBusinessById_throwsResourceNotFound_whenBusinessDoesNotExist() {
        when(businessRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> businessService.getBusinessById(999L, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Business not found with id: 999");
    }

    /**
     * When the business exists but belongs to a different user,
     * UnauthorizedException must be thrown.
     */
    @Test
    void getBusinessById_throwsUnauthorized_whenOwnerMismatch() {
        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));

        // otherUser has id=2, business is owned by owner (id=1)
        assertThatThrownBy(() -> businessService.getBusinessById(10L, 2L))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("permission");
    }

    // =========================================================
    // updateBusiness
    // =========================================================

    /**
     * When the owner updates their business, all mutable fields must be
     * applied to the entity before it is saved.
     */
    @Test
    void updateBusiness_updatesFieldsAndReturnsResponse_whenOwnerMatches() {
        // ARRANGE
        UpdateBusinessRequest request = new UpdateBusinessRequest(
                "Updated Name", "New description",
                "999 New St", "+27700000001", BusinessType.COLD_ROOM_RENTAL
        );

        Business updatedBusiness = Business.builder()
                .id(10L).name("Updated Name").description("New description")
                .address("999 New St").phoneNumber("+27700000001")
                .businessType(BusinessType.COLD_ROOM_RENTAL)
                .owner(owner).createdAt(business.getCreatedAt()).updatedAt(LocalDateTime.now())
                .build();

        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));
        when(businessRepository.save(any(Business.class))).thenReturn(updatedBusiness);

        // ACT
        BusinessResponse response = businessService.updateBusiness(10L, request, 1L);

        // ASSERT
        assertThat(response.name()).isEqualTo("Updated Name");
        assertThat(response.businessType()).isEqualTo(BusinessType.COLD_ROOM_RENTAL);
        verify(businessRepository).save(business); // same entity, mutated
    }

    /**
     * A non-owner must not be able to update someone else's business.
     */
    @Test
    void updateBusiness_throwsUnauthorized_whenOwnerMismatch() {
        UpdateBusinessRequest request = new UpdateBusinessRequest(
                "Hack", null, "Evil Rd", "+27700000000", BusinessType.TOILET_RENTAL
        );
        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));

        assertThatThrownBy(() -> businessService.updateBusiness(10L, request, 2L))
                .isInstanceOf(UnauthorizedException.class);

        verify(businessRepository, never()).save(any());
    }

    // =========================================================
    // deleteBusiness
    // =========================================================

    /**
     * When the owner deletes their business, the repository's delete
     * method must be called exactly once with the correct entity.
     */
    @Test
    void deleteBusiness_deletesSuccessfully_whenOwnerMatches() {
        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));

        businessService.deleteBusiness(10L, 1L);

        verify(businessRepository).delete(business);
    }

    /**
     * A non-owner must not be able to delete someone else's business.
     */
    @Test
    void deleteBusiness_throwsUnauthorized_whenOwnerMismatch() {
        when(businessRepository.findById(10L)).thenReturn(Optional.of(business));

        assertThatThrownBy(() -> businessService.deleteBusiness(10L, 2L))
                .isInstanceOf(UnauthorizedException.class);

        verify(businessRepository, never()).delete(any());
    }

    /**
     * Deleting a non-existent business must throw ResourceNotFoundException
     * before any delete is attempted.
     */
    @Test
    void deleteBusiness_throwsResourceNotFound_whenBusinessDoesNotExist() {
        when(businessRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> businessService.deleteBusiness(999L, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Business not found with id: 999");

        verify(businessRepository, never()).delete(any());
    }
}
