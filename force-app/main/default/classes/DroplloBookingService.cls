/**
 * Service class for managing booking operations
 * Handles availability checking, booking validation, and business logic
 * 
 * Features:
 * - Room and equipment availability checking
 * - Booking validation and conflict prevention
 * - Booking creation and management
 * - Integration with notification services
 * 
 * @version 1.0
 * @author Dropillo Team
 */
public class DroplloBookingService {
    
    /**
     * Check availability for a room in the given time slot
     * @param roomId Room ID to check
     * @param startDateTime Start date and time
     * @param endDateTime End date and time
     * @param excludeBookingId Booking ID to exclude from check (for updates)
     * @return Boolean true if available, false if conflicted
     */
    public static Boolean isRoomAvailable(Id roomId, DateTime startDateTime, DateTime endDateTime, Id excludeBookingId) {
        if (roomId == null || startDateTime == null || endDateTime == null) {
            return false;
        }
        
        if (startDateTime >= endDateTime) {
            return false;
        }
        
        String query = 'SELECT Id FROM Booking__c WHERE Room__c = :roomId AND Status__c != \'Cancelled\' AND ';
        query += '((Start_DateTime__c <= :startDateTime AND End_DateTime__c > :startDateTime) OR ';
        query += '(Start_DateTime__c < :endDateTime AND End_DateTime__c >= :endDateTime) OR ';
        query += '(Start_DateTime__c >= :startDateTime AND End_DateTime__c <= :endDateTime))';
        
        if (excludeBookingId != null) {
            query += ' AND Id != :excludeBookingId';
        }
        
        List<Booking__c> conflictingBookings = Database.query(query);
        
        return conflictingBookings.isEmpty();
    }
    
    /**
     * Check availability for equipment in the given time slot
     * @param equipmentId Equipment ID to check
     * @param startDateTime Start date and time
     * @param endDateTime End date and time
     * @param excludeBookingId Booking ID to exclude from check (for updates)
     * @return Boolean true if available, false if conflicted
     */
    public static Boolean isEquipmentAvailable(Id equipmentId, DateTime startDateTime, DateTime endDateTime, Id excludeBookingId) {
        if (equipmentId == null || startDateTime == null || endDateTime == null) {
            return false;
        }
        
        if (startDateTime >= endDateTime) {
            return false;
        }
        
        String query = 'SELECT Id FROM Booking__c WHERE Equipment__c = :equipmentId AND Status__c != \'Cancelled\' AND ';
        query += '((Start_DateTime__c <= :startDateTime AND End_DateTime__c > :startDateTime) OR ';
        query += '(Start_DateTime__c < :endDateTime AND End_DateTime__c >= :endDateTime) OR ';
        query += '(Start_DateTime__c >= :startDateTime AND End_DateTime__c <= :endDateTime))';
        
        if (excludeBookingId != null) {
            query += ' AND Id != :excludeBookingId';
        }
        
        List<Booking__c> conflictingBookings = Database.query(query);
        
        return conflictingBookings.isEmpty();
    }
    
    /**
     * Create a new booking with validation
     * @param bookingRequest Booking request data
     * @return BookingResult containing success status and booking details
     */
    public static BookingResult createBooking(BookingRequest bookingRequest) {
        BookingResult result = new BookingResult();
        
        try {
            // Validate the booking request
            ValidationResult validation = validateBookingRequest(bookingRequest);
            if (!validation.isValid) {
                result.isSuccess = false;
                result.errorMessage = validation.errorMessage;
                return result;
            }
            
            // Create the booking record
            Booking__c booking = new Booking__c();
            booking.Booking_User__c = bookingRequest.userId;
            booking.Booking_Type__c = bookingRequest.bookingType;
            booking.Start_DateTime__c = bookingRequest.startDateTime;
            booking.End_DateTime__c = bookingRequest.endDateTime;
            booking.Status__c = 'Pending';
            booking.Purpose__c = bookingRequest.purpose;
            booking.Attendee_Count__c = bookingRequest.attendeeCount;
            booking.Booking_Notes__c = bookingRequest.notes;
            booking.Notification_Sent__c = false;
            
            if (bookingRequest.bookingType == 'Room' && bookingRequest.roomId != null) {
                booking.Room__c = bookingRequest.roomId;
                booking.Return_Status__c = 'Not_Applicable';
            } else if (bookingRequest.bookingType == 'Equipment' && bookingRequest.equipmentId != null) {
                booking.Equipment__c = bookingRequest.equipmentId;
                booking.Return_Status__c = 'Not_Returned';
            }
            
            insert booking;
            
            // Update booking status to confirmed after successful insert
            booking.Status__c = 'Confirmed';
            update booking;
            
            result.isSuccess = true;
            result.bookingId = booking.Id;
            result.booking = booking;
            result.successMessage = 'Booking created successfully';
            
        } catch (DmlException e) {
            result.isSuccess = false;
            result.errorMessage = 'Failed to create booking: ' + e.getMessage();
            System.debug('Booking creation failed: ' + e.getMessage());
        } catch (Exception e) {
            result.isSuccess = false;
            result.errorMessage = 'Unexpected error: ' + e.getMessage();
            System.debug('Booking creation exception: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Update an existing booking
     * @param bookingId Booking ID to update
     * @param bookingRequest Updated booking data
     * @return BookingResult containing success status and updated booking details
     */
    public static BookingResult updateBooking(Id bookingId, BookingRequest bookingRequest) {
        BookingResult result = new BookingResult();
        
        try {
            // Validate the booking request for update
            ValidationResult validation = validateBookingRequest(bookingRequest, bookingId);
            if (!validation.isValid) {
                result.isSuccess = false;
                result.errorMessage = validation.errorMessage;
                return result;
            }
            
            // Get existing booking
            Booking__c booking = [SELECT Id, Status__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            
            // Update the booking fields
            booking.Start_DateTime__c = bookingRequest.startDateTime;
            booking.End_DateTime__c = bookingRequest.endDateTime;
            booking.Purpose__c = bookingRequest.purpose;
            booking.Attendee_Count__c = bookingRequest.attendeeCount;
            booking.Booking_Notes__c = bookingRequest.notes;
            
            update booking;
            
            result.isSuccess = true;
            result.bookingId = booking.Id;
            result.booking = booking;
            result.successMessage = 'Booking updated successfully';
            
        } catch (QueryException e) {
            result.isSuccess = false;
            result.errorMessage = 'Booking not found';
        } catch (DmlException e) {
            result.isSuccess = false;
            result.errorMessage = 'Failed to update booking: ' + e.getMessage();
        } catch (Exception e) {
            result.isSuccess = false;
            result.errorMessage = 'Unexpected error: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Cancel a booking
     * @param bookingId Booking ID to cancel
     * @param userId User requesting the cancellation
     * @return BookingResult containing success status
     */
    public static BookingResult cancelBooking(Id bookingId, Id userId) {
        BookingResult result = new BookingResult();
        
        try {
            Booking__c booking = [SELECT Id, Status__c, Booking_User__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            
            // Verify user can cancel this booking
            if (booking.Booking_User__c != userId) {
                result.isSuccess = false;
                result.errorMessage = 'You can only cancel your own bookings';
                return result;
            }
            
            if (booking.Status__c == 'Cancelled') {
                result.isSuccess = false;
                result.errorMessage = 'Booking is already cancelled';
                return result;
            }
            
            booking.Status__c = 'Cancelled';
            update booking;
            
            result.isSuccess = true;
            result.bookingId = booking.Id;
            result.successMessage = 'Booking cancelled successfully';
            
        } catch (QueryException e) {
            result.isSuccess = false;
            result.errorMessage = 'Booking not found';
        } catch (DmlException e) {
            result.isSuccess = false;
            result.errorMessage = 'Failed to cancel booking: ' + e.getMessage();
        } catch (Exception e) {
            result.isSuccess = false;
            result.errorMessage = 'Unexpected error: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Validate booking request data
     * @param bookingRequest Booking request to validate
     * @param excludeBookingId Booking ID to exclude from availability check (for updates)
     * @return ValidationResult containing validation status
     */
    private static ValidationResult validateBookingRequest(BookingRequest bookingRequest, Id excludeBookingId) {
        ValidationResult result = new ValidationResult();
        result.isValid = true;
        
        // Basic validation
        if (bookingRequest == null) {
            result.isValid = false;
            result.errorMessage = 'Booking request is required';
            return result;
        }
        
        if (bookingRequest.userId == null) {
            result.isValid = false;
            result.errorMessage = 'User is required';
            return result;
        }
        
        if (bookingRequest.startDateTime == null || bookingRequest.endDateTime == null) {
            result.isValid = false;
            result.errorMessage = 'Start and end date/time are required';
            return result;
        }
        
        if (bookingRequest.startDateTime >= bookingRequest.endDateTime) {
            result.isValid = false;
            result.errorMessage = 'End date/time must be after start date/time';
            return result;
        }
        
        if (bookingRequest.startDateTime < DateTime.now()) {
            result.isValid = false;
            result.errorMessage = 'Cannot book in the past';
            return result;
        }
        
        if (String.isBlank(bookingRequest.bookingType)) {
            result.isValid = false;
            result.errorMessage = 'Booking type is required';
            return result;
        }
        
        // Type-specific validation
        if (bookingRequest.bookingType == 'Room') {
            if (bookingRequest.roomId == null) {
                result.isValid = false;
                result.errorMessage = 'Room is required for room bookings';
                return result;
            }
            
            // Check room availability
            if (!isRoomAvailable(bookingRequest.roomId, bookingRequest.startDateTime, bookingRequest.endDateTime, excludeBookingId)) {
                result.isValid = false;
                result.errorMessage = 'Room is not available for the selected time slot';
                return result;
            }
        } else if (bookingRequest.bookingType == 'Equipment') {
            if (bookingRequest.equipmentId == null) {
                result.isValid = false;
                result.errorMessage = 'Equipment is required for equipment bookings';
                return result;
            }
            
            // Check equipment availability
            if (!isEquipmentAvailable(bookingRequest.equipmentId, bookingRequest.startDateTime, bookingRequest.endDateTime, excludeBookingId)) {
                result.isValid = false;
                result.errorMessage = 'Equipment is not available for the selected time slot';
                return result;
            }
        } else {
            result.isValid = false;
            result.errorMessage = 'Invalid booking type. Must be Room or Equipment';
            return result;
        }
        
        return result;
    }
    
    /**
     * Overloaded method for validation without exclude booking ID
     */
    private static ValidationResult validateBookingRequest(BookingRequest bookingRequest) {
        return validateBookingRequest(bookingRequest, null);
    }
    
    /**
     * Get available rooms for a time slot
     * @param startDateTime Start date and time
     * @param endDateTime End date and time
     * @param minCapacity Minimum capacity required (optional)
     * @return List of available rooms
     */
    public static List<Room__c> getAvailableRooms(DateTime startDateTime, DateTime endDateTime, Integer minCapacity) {
        String query = 'SELECT Id, Name, Room_Type__c, Capacity__c, Amenities__c, Floor__c ';
        query += 'FROM Room__c WHERE Is_Active__c = true';
        
        if (minCapacity != null && minCapacity > 0) {
            query += ' AND Capacity__c >= :minCapacity';
        }
        
        List<Room__c> allRooms = Database.query(query);
        List<Room__c> availableRooms = new List<Room__c>();
        
        for (Room__c room : allRooms) {
            if (isRoomAvailable(room.Id, startDateTime, endDateTime, null)) {
                availableRooms.add(room);
            }
        }
        
        return availableRooms;
    }
    
    /**
     * Get available equipment for a time slot
     * @param startDateTime Start date and time
     * @param endDateTime End date and time
     * @param equipmentType Equipment type filter (optional)
     * @return List of available equipment
     */
    public static List<Equipment__c> getAvailableEquipment(DateTime startDateTime, DateTime endDateTime, String equipmentType) {
        String query = 'SELECT Id, Name, Equipment_Type__c, Serial_Number__c, Current_Location__c ';
        query += 'FROM Equipment__c WHERE Is_Active__c = true AND Is_Available__c = true';
        
        if (String.isNotBlank(equipmentType)) {
            query += ' AND Equipment_Type__c = :equipmentType';
        }
        
        List<Equipment__c> allEquipment = Database.query(query);
        List<Equipment__c> availableEquipment = new List<Equipment__c>();
        
        for (Equipment__c equipment : allEquipment) {
            if (isEquipmentAvailable(equipment.Id, startDateTime, endDateTime, null)) {
                availableEquipment.add(equipment);
            }
        }
        
        return availableEquipment;
    }
    
    // Inner classes for request/response handling
    
    /**
     * Booking request wrapper class
     */
    public class BookingRequest {
        public Id userId;
        public String bookingType; // 'Room' or 'Equipment'
        public Id roomId;
        public Id equipmentId;
        public DateTime startDateTime;
        public DateTime endDateTime;
        public String purpose;
        public Integer attendeeCount;
        public String notes;
    }
    
    /**
     * Booking result wrapper class
     */
    public class BookingResult {
        public Boolean isSuccess = false;
        public String errorMessage;
        public String successMessage;
        public Id bookingId;
        public Booking__c booking;
    }
    
    /**
     * Validation result wrapper class
     */
    public class ValidationResult {
        public Boolean isValid = false;
        public String errorMessage;
    }
} 