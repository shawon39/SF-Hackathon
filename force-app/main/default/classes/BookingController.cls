/**
 * Controller for managing booking operations in the Dropillo Space & Asset Hub
 * Handles real-time availability, booking creation, and booking management
 */
public with sharing class BookingController {
    
    /**
     * Get available rooms with real-time availability check
     * @param startDateTime Start time for availability check
     * @param endDateTime End time for availability check
     * @param capacity Minimum capacity required
     * @param amenities Required amenities (comma-separated)
     * @return List of available rooms with details
     */
    @AuraEnabled(cacheable=false)
    public static List<RoomAvailability> getAvailableRooms(String startDateTime, String endDateTime, Integer capacity, String amenities) {
        try {
            DateTime startDT = parseDateTime(startDateTime);
            DateTime endDT = parseDateTime(endDateTime);
            
            // Get all active rooms
            List<Room__c> allRooms = [
                SELECT Id, Name, External_Room_ID__c, Room_Type__c, Capacity__c, 
                       Amenities__c, Floor__c, Is_Active__c
                FROM Room__c 
                WHERE Is_Active__c = true
                ORDER BY Room_Type__c, Capacity__c
            ];
            
            // Filter by capacity if specified
            if (capacity != null && capacity > 0) {
                List<Room__c> filteredRooms = new List<Room__c>();
                for (Room__c room : allRooms) {
                    if (room.Capacity__c >= capacity) {
                        filteredRooms.add(room);
                    }
                }
                allRooms = filteredRooms;
            }
            
            // Filter by amenities if specified
            if (String.isNotBlank(amenities)) {
                List<String> requiredAmenities = amenities.split(',');
                List<Room__c> filteredRooms = new List<Room__c>();
                for (Room__c room : allRooms) {
                    if (String.isNotBlank(room.Amenities__c)) {
                        List<Object> roomAmenities = (List<Object>) JSON.deserializeUntyped(room.Amenities__c);
                        Set<String> roomAmenitiesSet = new Set<String>();
                        for (Object amenity : roomAmenities) {
                            roomAmenitiesSet.add(String.valueOf(amenity).trim().toLowerCase());
                        }
                        
                        Boolean hasAllAmenities = true;
                        for (String reqAmenity : requiredAmenities) {
                            if (!roomAmenitiesSet.contains(reqAmenity.trim().toLowerCase())) {
                                hasAllAmenities = false;
                                break;
                            }
                        }
                        if (hasAllAmenities) {
                            filteredRooms.add(room);
                        }
                    }
                }
                allRooms = filteredRooms;
            }
            
            // Check availability for each room
            Set<Id> roomIds = new Set<Id>();
            for (Room__c room : allRooms) {
                roomIds.add(room.Id);
            }
            
            // Find conflicting bookings
            List<Booking__c> conflictingBookings = [
                SELECT Room__c 
                FROM Booking__c 
                WHERE Room__c IN :roomIds
                AND Status__c IN ('Pending', 'Confirmed', 'In_Use')
                AND ((Start_DateTime__c <= :startDT AND End_DateTime__c > :startDT)
                     OR (Start_DateTime__c < :endDT AND End_DateTime__c >= :endDT)
                     OR (Start_DateTime__c >= :startDT AND End_DateTime__c <= :endDT))
            ];
            
            Set<Id> bookedRoomIds = new Set<Id>();
            for (Booking__c booking : conflictingBookings) {
                bookedRoomIds.add(booking.Room__c);
            }
            
            // Build response with availability status
            List<RoomAvailability> availableRooms = new List<RoomAvailability>();
            for (Room__c room : allRooms) {
                RoomAvailability roomAvail = new RoomAvailability();
                roomAvail.roomId = room.Id;
                roomAvail.name = room.Name;
                roomAvail.externalId = room.External_Room_ID__c;
                roomAvail.roomType = room.Room_Type__c;
                roomAvail.capacity = Integer.valueOf(room.Capacity__c);
                roomAvail.floor = room.Floor__c;
                roomAvail.isAvailable = !bookedRoomIds.contains(room.Id);
                
                // Parse amenities JSON
                if (String.isNotBlank(room.Amenities__c)) {
                    try {
                        List<Object> amenitiesList = (List<Object>) JSON.deserializeUntyped(room.Amenities__c);
                        roomAvail.amenities = new List<String>();
                        for (Object amenity : amenitiesList) {
                            roomAvail.amenities.add(String.valueOf(amenity));
                        }
                    } catch (Exception e) {
                        roomAvail.amenities = new List<String>();
                    }
                } else {
                    roomAvail.amenities = new List<String>();
                }
                
                availableRooms.add(roomAvail);
            }
            
            return availableRooms;
            
        } catch (Exception e) {
            throw new BookingException('Error fetching available rooms: ' + e.getMessage());
        }
    }
    
    /**
     * Get available equipment with real-time availability check
     * @param startDateTime Start time for availability check
     * @param endDateTime End time for availability check
     * @param equipmentType Type of equipment to filter by
     * @return List of available equipment with details
     */
    @AuraEnabled(cacheable=false)
    public static List<EquipmentAvailability> getAvailableEquipment(String startDateTime, String endDateTime, String equipmentType) {
        try {
            DateTime startDT = parseDateTime(startDateTime);
            DateTime endDT = parseDateTime(endDateTime);
            
            // Get all active equipment
            String query = 'SELECT Id, Name, External_Equipment_ID__c, Equipment_Type__c, Serial_Number__c, Is_Available__c, Current_Location__c FROM Equipment__c WHERE Is_Active__c = true AND Is_Available__c = true';
            
            if (String.isNotBlank(equipmentType)) {
                query += ' AND Equipment_Type__c = :equipmentType';
            }
            
            query += ' ORDER BY Equipment_Type__c, Name';
            
            List<Equipment__c> allEquipment = Database.query(query);
            
            // Check availability for each equipment
            Set<Id> equipmentIds = new Set<Id>();
            for (Equipment__c equipment : allEquipment) {
                equipmentIds.add(equipment.Id);
            }
            
            // Find conflicting bookings
            List<Booking__c> conflictingBookings = [
                SELECT Equipment__c 
                FROM Booking__c 
                WHERE Equipment__c IN :equipmentIds
                AND Status__c IN ('Pending', 'Confirmed', 'In_Use')
                AND ((Start_DateTime__c <= :startDT AND End_DateTime__c > :startDT)
                     OR (Start_DateTime__c < :endDT AND End_DateTime__c >= :endDT)
                     OR (Start_DateTime__c >= :startDT AND End_DateTime__c <= :endDT))
            ];
            
            Set<Id> bookedEquipmentIds = new Set<Id>();
            for (Booking__c booking : conflictingBookings) {
                bookedEquipmentIds.add(booking.Equipment__c);
            }
            
            // Build response with availability status
            List<EquipmentAvailability> availableEquipment = new List<EquipmentAvailability>();
            for (Equipment__c equipment : allEquipment) {
                EquipmentAvailability equipAvail = new EquipmentAvailability();
                equipAvail.equipmentId = equipment.Id;
                equipAvail.name = equipment.Name;
                equipAvail.externalId = equipment.External_Equipment_ID__c;
                equipAvail.equipmentType = equipment.Equipment_Type__c;
                equipAvail.serialNumber = equipment.Serial_Number__c;
                equipAvail.currentLocation = equipment.Current_Location__c;
                equipAvail.isAvailable = !bookedEquipmentIds.contains(equipment.Id);
                
                availableEquipment.add(equipAvail);
            }
            
            return availableEquipment;
            
        } catch (Exception e) {
            throw new BookingException('Error fetching available equipment: ' + e.getMessage());
        }
    }
    
    /**
     * Create a new booking
     * @param bookingType 'Room' or 'Equipment'
     * @param resourceId ID of the room or equipment
     * @param startDateTime Booking start time
     * @param endDateTime Booking end time
     * @param purpose Purpose of the booking
     * @param attendeeCount Number of attendees (for room bookings)
     * @return Created booking record
     */
    @AuraEnabled
    public static BookingResult createBooking(String bookingType, String resourceId, String startDateTime, String endDateTime, String purpose, Integer attendeeCount) {
        try {
            // Validate input
            if (String.isBlank(bookingType) || String.isBlank(resourceId) || String.isBlank(startDateTime) || String.isBlank(endDateTime)) {
                throw new BookingException('Missing required booking information');
            }
            
            DateTime startDT = parseDateTime(startDateTime);
            DateTime endDT = parseDateTime(endDateTime);
            
            // Validate booking time
            if (startDT >= endDT) {
                throw new BookingException('End time must be after start time');
            }
            
            if (startDT < System.now()) {
                throw new BookingException('Cannot book resources for past dates');
            }
            
            // Check if resource is available
            Boolean isAvailable = false;
            if (bookingType == 'Room') {
                List<RoomAvailability> rooms = getAvailableRooms(startDateTime, endDateTime, null, null);
                for (RoomAvailability room : rooms) {
                    if (room.roomId == resourceId && room.isAvailable) {
                        isAvailable = true;
                        break;
                    }
                }
            } else if (bookingType == 'Equipment') {
                List<EquipmentAvailability> equipment = getAvailableEquipment(startDateTime, endDateTime, null);
                for (EquipmentAvailability equip : equipment) {
                    if (equip.equipmentId == resourceId && equip.isAvailable) {
                        isAvailable = true;
                        break;
                    }
                }
            }
            
            if (!isAvailable) {
                throw new BookingException('Selected resource is not available for the specified time slot');
            }
            
            // Create booking record
            Booking__c newBooking = new Booking__c();
            newBooking.Booking_User__c = UserInfo.getUserId();
            newBooking.Booking_Type__c = bookingType;
            newBooking.Start_DateTime__c = startDT;
            newBooking.End_DateTime__c = endDT;
            newBooking.Status__c = 'Pending';
            newBooking.Purpose__c = purpose;
            newBooking.Attendee_Count__c = attendeeCount;
            newBooking.Notification_Sent__c = false;
            
            if (bookingType == 'Room') {
                newBooking.Room__c = resourceId;
                newBooking.Return_Status__c = 'Not_Applicable';
            } else {
                newBooking.Equipment__c = resourceId;
                newBooking.Return_Status__c = 'Not_Returned';
            }
            
            insert newBooking;
            
            // Auto-confirm booking
            newBooking.Status__c = 'Confirmed';
            update newBooking;
            
            BookingResult result = new BookingResult();
            result.isSuccess = true;
            result.bookingId = newBooking.Id;
            result.message = 'Booking created successfully';
            
            return result;
            
        } catch (Exception e) {
            BookingResult result = new BookingResult();
            result.isSuccess = false;
            result.message = e.getMessage();
            return result;
        }
    }
    
    /**
     * Get all bookings made by the current user
     * @return List of user's bookings
     */
    @AuraEnabled(cacheable=true)
    public static List<BookingDetails> getUserBookings() {
        try {
            String currentUserId = UserInfo.getUserId();
            
            List<Booking__c> bookings = [
                SELECT Id, Name, Booking_Type__c, Room__c, Equipment__c, Start_DateTime__c, 
                       End_DateTime__c, Status__c, Purpose__c, Attendee_Count__c, Return_Status__c,
                       Room__r.Name, Room__r.Room_Type__c, Room__r.Floor__c,
                       Equipment__r.Name, Equipment__r.Equipment_Type__c, Equipment__r.Current_Location__c,
                       CreatedDate, LastModifiedDate
                FROM Booking__c 
                WHERE Booking_User__c = :currentUserId
                ORDER BY Start_DateTime__c DESC
            ];
            
            List<BookingDetails> bookingDetailsList = new List<BookingDetails>();
            for (Booking__c booking : bookings) {
                try {
                    BookingDetails details = new BookingDetails();
                    details.bookingId = booking.Id;
                    details.bookingNumber = booking.Name;
                    details.bookingType = booking.Booking_Type__c;
                    details.startDateTime = booking.Start_DateTime__c;
                    details.endDateTime = booking.End_DateTime__c;
                    details.status = booking.Status__c;
                    details.purpose = booking.Purpose__c;
                    details.attendeeCount = booking.Attendee_Count__c != null ? Integer.valueOf(booking.Attendee_Count__c) : null;
                    details.returnStatus = booking.Return_Status__c;
                    
                    if (booking.Room__c != null && booking.Room__r != null) {
                        details.resourceName = booking.Room__r.Name;
                        details.resourceType = booking.Room__r.Room_Type__c;
                        details.location = booking.Room__r.Floor__c;
                    } else if (booking.Equipment__c != null && booking.Equipment__r != null) {
                        details.resourceName = booking.Equipment__r.Name;
                        details.resourceType = booking.Equipment__r.Equipment_Type__c;
                        details.location = booking.Equipment__r.Current_Location__c;
                    }
                    
                    bookingDetailsList.add(details);
                } catch (Exception innerE) {
                    // Continue processing other bookings if one fails
                }
            }
            
            return bookingDetailsList;
            
        } catch (Exception e) {
            throw new BookingException('Error fetching user bookings: ' + e.getMessage());
        }
    }
    
    /**
     * Cancel a booking
     * @param bookingId ID of the booking to cancel
     * @return Result of cancellation
     */
    @AuraEnabled
    public static BookingResult cancelBooking(String bookingId) {
        try {
            Booking__c booking = [
                SELECT Id, Status__c, Start_DateTime__c, Booking_User__c 
                FROM Booking__c 
                WHERE Id = :bookingId 
                LIMIT 1
            ];
            
            // Check if user owns the booking
            if (booking.Booking_User__c != UserInfo.getUserId()) {
                throw new BookingException('You can only cancel your own bookings');
            }
            
            // Check if booking can be cancelled
            if (booking.Status__c == 'Cancelled') {
                throw new BookingException('Booking is already cancelled');
            }
            
            if (booking.Status__c == 'Completed') {
                throw new BookingException('Cannot cancel completed booking');
            }
            
            // Update booking status
            booking.Status__c = 'Cancelled';
            update booking;
            
            BookingResult result = new BookingResult();
            result.isSuccess = true;
            result.message = 'Booking cancelled successfully';
            
            return result;
            
        } catch (Exception e) {
            BookingResult result = new BookingResult();
            result.isSuccess = false;
            result.message = e.getMessage();
            return result;
        }
    }
    
    /**
     * Get equipment types for filtering
     * @return List of unique equipment types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getEquipmentTypes() {
        List<String> equipmentTypes = new List<String>();
        
        for (AggregateResult ar : [
            SELECT Equipment_Type__c 
            FROM Equipment__c 
            WHERE Is_Active__c = true 
            GROUP BY Equipment_Type__c 
            ORDER BY Equipment_Type__c
        ]) {
            equipmentTypes.add((String) ar.get('Equipment_Type__c'));
        }
        
        return equipmentTypes;
    }
    
    /**
     * Debug method to test getUserBookings functionality
     */
    @AuraEnabled(cacheable=true)
    public static String debugGetUserBookings() {
        try {
            String currentUserId = UserInfo.getUserId();
            String debugInfo = 'Current User ID: ' + currentUserId + '\n';
            
            // Check if user has access to Booking__c object
            List<Booking__c> allBookings = [SELECT Id, Name, Booking_User__c FROM Booking__c LIMIT 5];
            debugInfo += 'Total bookings in system: ' + allBookings.size() + '\n';
            
            List<BookingDetails> userBookings = getUserBookings();
            debugInfo += 'User bookings found: ' + userBookings.size() + '\n';
            
            return debugInfo;
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
    // Wrapper classes for LWC responses
    
    public class RoomAvailability {
        @AuraEnabled public String roomId;
        @AuraEnabled public String name;
        @AuraEnabled public String externalId;
        @AuraEnabled public String roomType;
        @AuraEnabled public Integer capacity;
        @AuraEnabled public String floor;
        @AuraEnabled public List<String> amenities;
        @AuraEnabled public Boolean isAvailable;
    }
    
    public class EquipmentAvailability {
        @AuraEnabled public String equipmentId;
        @AuraEnabled public String name;
        @AuraEnabled public String externalId;
        @AuraEnabled public String equipmentType;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String currentLocation;
        @AuraEnabled public Boolean isAvailable;
    }
    
    public class BookingResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String bookingId;
        @AuraEnabled public String message;
    }
    
    public class BookingDetails {
        @AuraEnabled public String bookingId;
        @AuraEnabled public String bookingNumber;
        @AuraEnabled public String bookingType;
        @AuraEnabled public String resourceName;
        @AuraEnabled public String resourceType;
        @AuraEnabled public String location;
        @AuraEnabled public DateTime startDateTime;
        @AuraEnabled public DateTime endDateTime;
        @AuraEnabled public String status;
        @AuraEnabled public String purpose;
        @AuraEnabled public Integer attendeeCount;
        @AuraEnabled public String returnStatus;
    }
    
    /**
     * Helper method to parse datetime strings from various formats
     * @param dateTimeStr String representation of datetime
     * @return Parsed DateTime object
     */
    private static DateTime parseDateTime(String dateTimeStr) {
        if (String.isBlank(dateTimeStr)) {
            throw new BookingException('DateTime string cannot be blank');
        }
        
        try {
            // Replace T with space if present (ISO format)
            String cleanedStr = dateTimeStr.replace('T', ' ');
            
            // If no seconds are provided, add ":00"
            if (cleanedStr.length() == 16) { // Format: yyyy-MM-dd HH:mm
                cleanedStr += ':00';
            }
            
            return DateTime.valueOf(cleanedStr);
        } catch (Exception e) {
            throw new BookingException('Invalid date/time format: ' + dateTimeStr + '. Expected format: yyyy-MM-dd HH:mm or yyyy-MM-ddTHH:mm');
        }
    }
    
    // Custom exception class
    public class BookingException extends Exception {}
} 