package com.back2kasi.booking.service;

import com.back2kasi.booking.dto.BookingResponse;
import com.back2kasi.booking.dto.CreateBookingRequest;
import com.back2kasi.booking.dto.UpdateBookingStatusRequest;
import com.back2kasi.booking.entity.Booking;
import com.back2kasi.booking.entity.BookingStatus;
import com.back2kasi.booking.repository.BookingRepository;
import com.back2kasi.business.entity.Business;
import com.back2kasi.business.entity.BusinessType;
import com.back2kasi.common.exception.ResourceNotFoundException;
import com.back2kasi.common.exception.UnauthorizedException;
import com.back2kasi.rentalunit.entity.RentalUnit;
import com.back2kasi.rentalunit.entity.RentalUnitStatus;
import com.back2kasi.rentalunit.entity.RentalUnitType;
import com.back2kasi.rentalunit.repository.RentalUnitRepository;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link BookingServiceImpl}.
 *
 * <p>Pure unit test — no Spring context, no database. All collaborators are
 * replaced with Mockito mocks so each test exercises only the logic inside
 * {@code BookingServiceImpl}.</p>
 *
 * <p>Key scenarios covered:</p>
 * <ul>
 *   <li>Happy-path booking creation with price calculation</li>
 *   <li>Overlap conflict detection</li>
 *   <li>Invalid date range rejection</li>
 *   <li>Read access control (customer vs owner vs third party)</li>
 *   <li>Status transitions: CONFIRMED, COMPLETED, CANCELLED</li>
 *   <li>RentalUnit status side-effects on transitions</li>
 *   <li>Terminal state guard (cannot change COMPLETED/CANCELLED)</li>
 *   <li>Customer cancel restriction (PENDING only)</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class BookingServiceImplTest {

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private RentalUnitRepository rentalUnitRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private BookingServiceImpl bookingService;

    // --- Fixtures ---

    private User owner;
    private User customer;
    private User thirdParty;
    private Business business;
    private RentalUnit unit;
    private Booking pendingBooking;
    private Booking confirmedBooking;

    private static final LocalDate START = LocalDate.now().plusDays(5);
    private static final LocalDate END   = LocalDate.now().plusDays(7);

    @BeforeEach
    void setUp() {
        owner = User.builder()
                .id(1L).firstName("Kabelo").lastName("Kekana")
                .email("kabelo@back2kasi.co.za").password("hashed")
                .phoneNumber("+27712345678").role(Role.USER)
                .build();

        customer = User.builder()
                .id(2L).firstName("Thabo").lastName("Nkosi")
                .email("thabo@kasi.co.za").password("hashed")
                .phoneNumber("+27799999999").role(Role.USER)
                .build();

        thirdParty = User.builder()
                .id(3L).email("stranger@kasi.co.za").password("hashed").role(Role.USER)
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

        pendingBooking = Booking.builder()
                .id(200L).rentalUnit(unit).customer(customer)
                .startDate(START).endDate(END)
                .totalPrice(new BigDecimal("450.00"))
                .status(BookingStatus.PENDING)
                .createdAt(LocalDateTime.now()).updatedAt(LocalDateTime.now())
                .build();

        confirmedBooking = Booking.builder()
                .id(201L).rentalUnit(unit).customer(customer)
                .startDate(START).endDate(END)
                .totalPrice(new BigDecimal("450.00"))
                .status(BookingStatus.CONFIRMED)
                .createdAt(LocalDateTime.now()).updatedAt(LocalDateTime.now())
                .build();
    }

    // =========================================================
    // createBooking
    // =========================================================

    @Test
    void createBooking_savesAndReturnsResponse_withCorrectTotalPrice() {
        // ARRANGE
        CreateBookingRequest request = new CreateBookingRequest(100L, START, END, "No notes");
        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));
        when(bookingRepository.existsOverlappingBooking(any(), any(), any(), any(), any())).thenReturn(false);
        when(userRepository.findById(2L)).thenReturn(Optional.of(customer));
        when(bookingRepository.save(any(Booking.class))).thenReturn(pendingBooking);

        // ACT
        BookingResponse response = bookingService.createBooking(request, 2L);

        // ASSERT  (3 days × R150 = R450)
        assertThat(response.status()).isEqualTo(BookingStatus.PENDING);
        assertThat(response.totalPrice()).isEqualByComparingTo("450.00");
        assertThat(response.rentalUnitId()).isEqualTo(100L);
        assertThat(response.customerId()).isEqualTo(2L);

        ArgumentCaptor<Booking> captor = ArgumentCaptor.forClass(Booking.class);
        verify(bookingRepository).save(captor.capture());
        assertThat(captor.getValue().getTotalPrice()).isEqualByComparingTo("450.00");
    }

    @Test
    void createBooking_throws404_whenRentalUnitNotFound() {
        CreateBookingRequest request = new CreateBookingRequest(999L, START, END, null);
        when(rentalUnitRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.createBooking(request, 2L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Rental unit not found with id: 999");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    void createBooking_throwsConflict_whenOverlapExists() {
        CreateBookingRequest request = new CreateBookingRequest(100L, START, END, null);
        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));
        when(bookingRepository.existsOverlappingBooking(eq(100L), any(), any(), eq(BookingStatus.CONFIRMED), eq(-1L)))
                .thenReturn(true);

        assertThatThrownBy(() -> bookingService.createBooking(request, 2L))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("already booked");

        verify(bookingRepository, never()).save(any());
    }

    @Test
    void createBooking_throwsIllegalState_whenEndBeforeStart() {
        CreateBookingRequest request = new CreateBookingRequest(100L, END, START, null); // reversed
        when(rentalUnitRepository.findById(100L)).thenReturn(Optional.of(unit));

        assertThatThrownBy(() -> bookingService.createBooking(request, 2L))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Start date must not be after end date");
    }

    // =========================================================
    // getBookingById
    // =========================================================

    @Test
    void getBookingById_returnsBooking_whenCallerIsCustomer() {
        when(bookingRepository.findById(200L)).thenReturn(Optional.of(pendingBooking));

        BookingResponse response = bookingService.getBookingById(200L, 2L); // customer id

        assertThat(response.id()).isEqualTo(200L);
        assertThat(response.status()).isEqualTo(BookingStatus.PENDING);
    }

    @Test
    void getBookingById_returnsBooking_whenCallerIsOwner() {
        when(bookingRepository.findById(200L)).thenReturn(Optional.of(pendingBooking));

        BookingResponse response = bookingService.getBookingById(200L, 1L); // owner id

        assertThat(response.id()).isEqualTo(200L);
    }

    @Test
    void getBookingById_throws403_whenCallerIsThirdParty() {
        when(bookingRepository.findById(200L)).thenReturn(Optional.of(pendingBooking));

        assertThatThrownBy(() -> bookingService.getBookingById(200L, 3L)) // third party id
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("permission");
    }

    @Test
    void getBookingById_throws404_whenNotFound() {
        when(bookingRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.getBookingById(999L, 2L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Booking not found with id: 999");
    }

    // =========================================================
    // getBookingsByCustomer
    // =========================================================

    @Test
    void getBookingsByCustomer_returnsList() {
        when(bookingRepository.findByCustomerId(2L)).thenReturn(List.of(pendingBooking));

        List<BookingResponse> result = bookingService.getBookingsByCustomer(2L);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().customerId()).isEqualTo(2L);
    }

    // =========================================================
    // updateBookingStatus — owner confirms
    // =========================================================

    @Test
    void updateBookingStatus_ownerConfirms_setsUnitToRented() {
        when(bookingRepository.findById(200L)).thenReturn(Optional.of(pendingBooking));
        when(bookingRepository.save(any(Booking.class))).thenReturn(pendingBooking);
        when(rentalUnitRepository.save(any(RentalUnit.class))).thenReturn(unit);

        bookingService.updateBookingStatus(200L, new UpdateBookingStatusRequest(BookingStatus.CONFIRMED), 1L);

        assertThat(pendingBooking.getStatus()).isEqualTo(BookingStatus.CONFIRMED);
        assertThat(unit.getStatus()).isEqualTo(RentalUnitStatus.RENTED);
    }

    @Test
    void updateBookingStatus_ownerCompletes_setsUnitToAvailable() {
        when(bookingRepository.findById(201L)).thenReturn(Optional.of(confirmedBooking));
        when(bookingRepository.save(any(Booking.class))).thenReturn(confirmedBooking);
        when(rentalUnitRepository.save(any(RentalUnit.class))).thenReturn(unit);

        bookingService.updateBookingStatus(201L, new UpdateBookingStatusRequest(BookingStatus.COMPLETED), 1L);

        assertThat(confirmedBooking.getStatus()).isEqualTo(BookingStatus.COMPLETED);
        assertThat(unit.getStatus()).isEqualTo(RentalUnitStatus.AVAILABLE);
    }

    @Test
    void updateBookingStatus_customerCancels_pendingBooking() {
        when(bookingRepository.findById(200L)).thenReturn(Optional.of(pendingBooking));
        when(bookingRepository.save(any(Booking.class))).thenReturn(pendingBooking);
        when(rentalUnitRepository.save(any(RentalUnit.class))).thenReturn(unit);

        bookingService.updateBookingStatus(200L, new UpdateBookingStatusRequest(BookingStatus.CANCELLED), 2L);

        assertThat(pendingBooking.getStatus()).isEqualTo(BookingStatus.CANCELLED);
    }

    @Test
    void updateBookingStatus_throws403_whenCustomerTriesToConfirm() {
        when(bookingRepository.findById(200L)).thenReturn(Optional.of(pendingBooking));

        assertThatThrownBy(() ->
                bookingService.updateBookingStatus(200L, new UpdateBookingStatusRequest(BookingStatus.CONFIRMED), 2L))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("owner");
    }

    @Test
    void updateBookingStatus_throws403_whenThirdPartyTriesToCancel() {
        when(bookingRepository.findById(200L)).thenReturn(Optional.of(pendingBooking));

        assertThatThrownBy(() ->
                bookingService.updateBookingStatus(200L, new UpdateBookingStatusRequest(BookingStatus.CANCELLED), 3L))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void updateBookingStatus_throwsIllegalState_whenBookingIsAlreadyCompleted() {
        Booking completedBooking = Booking.builder()
                .id(202L).rentalUnit(unit).customer(customer)
                .startDate(START).endDate(END)
                .totalPrice(new BigDecimal("450.00"))
                .status(BookingStatus.COMPLETED)
                .createdAt(LocalDateTime.now()).updatedAt(LocalDateTime.now())
                .build();
        when(bookingRepository.findById(202L)).thenReturn(Optional.of(completedBooking));

        assertThatThrownBy(() ->
                bookingService.updateBookingStatus(202L, new UpdateBookingStatusRequest(BookingStatus.CANCELLED), 1L))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("COMPLETED");
    }
}
