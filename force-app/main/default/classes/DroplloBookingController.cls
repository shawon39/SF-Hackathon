/**
 * Lightning Web Component Controller for Dropillo Booking Services
 * Exposes booking functionality to LWC components
 * 
 * @version 1.0
 * @author Dropillo Team
 */
public with sharing class DroplloBookingController {
    
    /**
     * Get available rooms for a time slot
     * @param startDateTime Start date and time
     * @param endDateTime End date and time
     * @param minCapacity Minimum capacity filter
     * @param roomType Room type filter
     * @return List of available rooms
     */
    @AuraEnabled(cacheable=true)
    public static List<RoomWrapper> getAvailableRooms(String startDateTime, String endDateTime, Integer minCapacity, String roomType) {
        try {
            DateTime startDT = DateTime.valueOf(startDateTime);
            DateTime endDT = DateTime.valueOf(endDateTime);
            
            List<Room__c> rooms = DroplloBookingService.getAvailableRooms(startDT, endDT, minCapacity);
            List<RoomWrapper> roomWrappers = new List<RoomWrapper>();
            
            for (Room__c room : rooms) {
                if (String.isBlank(roomType) || room.Room_Type__c == roomType) {
                    RoomWrapper wrapper = new RoomWrapper();
                    wrapper.id = room.Id;
                    wrapper.name = room.Name;
                    wrapper.roomType = room.Room_Type__c;
                    wrapper.capacity = room.Capacity__c != null ? Integer.valueOf(room.Capacity__c) : 0;
                    wrapper.floor = room.Floor__c;
                    
                    // Parse amenities
                    if (String.isNotBlank(room.Amenities__c)) {
                        try {
                            wrapper.amenities = (List<String>) JSON.deserialize(room.Amenities__c, List<String>.class);
                        } catch (Exception e) {
                            wrapper.amenities = new List<String>();
                        }
                    } else {
                        wrapper.amenities = new List<String>();
                    }
                    
                    roomWrappers.add(wrapper);
                }
            }
            
            return roomWrappers;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting available rooms: ' + e.getMessage());
        }
    }
    
    /**
     * Get available equipment for a time slot
     * @param startDateTime Start date and time
     * @param endDateTime End date and time
     * @param equipmentType Equipment type filter
     * @return List of available equipment
     */
    @AuraEnabled(cacheable=true)
    public static List<EquipmentWrapper> getAvailableEquipment(String startDateTime, String endDateTime, String equipmentType) {
        try {
            DateTime startDT = DateTime.valueOf(startDateTime);
            DateTime endDT = DateTime.valueOf(endDateTime);
            
            List<Equipment__c> equipment = DroplloBookingService.getAvailableEquipment(startDT, endDT, equipmentType);
            List<EquipmentWrapper> equipmentWrappers = new List<EquipmentWrapper>();
            
            for (Equipment__c equip : equipment) {
                EquipmentWrapper wrapper = new EquipmentWrapper();
                wrapper.id = equip.Id;
                wrapper.name = equip.Name;
                wrapper.equipmentType = equip.Equipment_Type__c;
                wrapper.serialNumber = equip.Serial_Number__c;
                wrapper.currentLocation = equip.Current_Location__c;
                wrapper.isAvailable = equip.Is_Available__c;
                
                equipmentWrappers.add(wrapper);
            }
            
            return equipmentWrappers;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting available equipment: ' + e.getMessage());
        }
    }
    
    /**
     * Create a new booking
     * @param bookingData Booking data from LWC
     * @return BookingResult with success status
     */
    @AuraEnabled
    public static BookingResultWrapper createBooking(BookingRequestWrapper bookingData) {
        try {
            DroplloBookingService.BookingRequest request = new DroplloBookingService.BookingRequest();
            request.userId = bookingData.userId;
            request.bookingType = bookingData.bookingType;
            request.roomId = bookingData.roomId;
            request.equipmentId = bookingData.equipmentId;
            request.startDateTime = DateTime.valueOf(bookingData.startDateTime);
            request.endDateTime = DateTime.valueOf(bookingData.endDateTime);
            request.purpose = bookingData.purpose;
            request.attendeeCount = bookingData.attendeeCount;
            request.notes = bookingData.notes;
            
            DroplloBookingService.BookingResult result = DroplloBookingService.createBooking(request);
            
            BookingResultWrapper wrapper = new BookingResultWrapper();
            wrapper.isSuccess = result.isSuccess;
            wrapper.errorMessage = result.errorMessage;
            wrapper.successMessage = result.successMessage;
            wrapper.bookingId = result.bookingId;
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating booking: ' + e.getMessage());
        }
    }
    
    /**
     * Update an existing booking
     * @param bookingId Booking ID to update
     * @param bookingData Updated booking data
     * @return BookingResult with success status
     */
    @AuraEnabled
    public static BookingResultWrapper updateBooking(String bookingId, BookingRequestWrapper bookingData) {
        try {
            DroplloBookingService.BookingRequest request = new DroplloBookingService.BookingRequest();
            request.userId = bookingData.userId;
            request.bookingType = bookingData.bookingType;
            request.roomId = bookingData.roomId;
            request.equipmentId = bookingData.equipmentId;
            request.startDateTime = DateTime.valueOf(bookingData.startDateTime);
            request.endDateTime = DateTime.valueOf(bookingData.endDateTime);
            request.purpose = bookingData.purpose;
            request.attendeeCount = bookingData.attendeeCount;
            request.notes = bookingData.notes;
            
            DroplloBookingService.BookingResult result = DroplloBookingService.updateBooking(Id.valueOf(bookingId), request);
            
            BookingResultWrapper wrapper = new BookingResultWrapper();
            wrapper.isSuccess = result.isSuccess;
            wrapper.errorMessage = result.errorMessage;
            wrapper.successMessage = result.successMessage;
            wrapper.bookingId = result.bookingId;
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating booking: ' + e.getMessage());
        }
    }
    
    /**
     * Cancel a booking
     * @param bookingId Booking ID to cancel
     * @param userId User requesting cancellation
     * @return BookingResult with success status
     */
    @AuraEnabled
    public static BookingResultWrapper cancelBooking(String bookingId, String userId) {
        try {
            DroplloBookingService.BookingResult result = DroplloBookingService.cancelBooking(
                Id.valueOf(bookingId), 
                Id.valueOf(userId)
            );
            
            BookingResultWrapper wrapper = new BookingResultWrapper();
            wrapper.isSuccess = result.isSuccess;
            wrapper.errorMessage = result.errorMessage;
            wrapper.successMessage = result.successMessage;
            wrapper.bookingId = result.bookingId;
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error cancelling booking: ' + e.getMessage());
        }
    }
    
    /**
     * Get user's bookings
     * @param userId User ID
     * @param startDate Start date for filtering
     * @param endDate End date for filtering
     * @return List of user bookings
     */
    @AuraEnabled(cacheable=true)
    public static List<BookingWrapper> getUserBookings(String userId, String startDate, String endDate) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            DateTime startDateTime = DateTime.newInstance(startDt, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDt.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            List<Booking__c> bookings = [
                SELECT Id, Name, Booking_Type__c, Status__c, Start_DateTime__c, End_DateTime__c,
                       Purpose__c, Attendee_Count__c, Return_Status__c, Booking_Notes__c,
                       Room__c, Room__r.Name, Room__r.Room_Type__c, Room__r.Floor__c,
                       Equipment__c, Equipment__r.Name, Equipment__r.Equipment_Type__c
                FROM Booking__c 
                WHERE Booking_User__c = :userId
                AND Start_DateTime__c >= :startDateTime
                AND Start_DateTime__c < :endDateTime
                ORDER BY Start_DateTime__c ASC
            ];
            
            List<BookingWrapper> bookingWrappers = new List<BookingWrapper>();
            
            for (Booking__c booking : bookings) {
                BookingWrapper wrapper = new BookingWrapper();
                wrapper.id = booking.Id;
                wrapper.name = booking.Name;
                wrapper.bookingType = booking.Booking_Type__c;
                wrapper.status = booking.Status__c;
                wrapper.startDateTime = booking.Start_DateTime__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                wrapper.endDateTime = booking.End_DateTime__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                wrapper.purpose = booking.Purpose__c;
                wrapper.attendeeCount = booking.Attendee_Count__c != null ? Integer.valueOf(booking.Attendee_Count__c) : 0;
                wrapper.returnStatus = booking.Return_Status__c;
                wrapper.notes = booking.Booking_Notes__c;
                
                if (booking.Room__c != null) {
                    wrapper.resourceName = booking.Room__r.Name;
                    wrapper.resourceDetails = booking.Room__r.Room_Type__c + ' - Floor ' + booking.Room__r.Floor__c;
                } else if (booking.Equipment__c != null) {
                    wrapper.resourceName = booking.Equipment__r.Name;
                    wrapper.resourceDetails = booking.Equipment__r.Equipment_Type__c;
                }
                
                bookingWrappers.add(wrapper);
            }
            
            return bookingWrappers;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting user bookings: ' + e.getMessage());
        }
    }
    
    /**
     * Get room types for filter options
     * @return List of room types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getRoomTypes() {
        try {
            List<String> roomTypes = new List<String>();
            Schema.DescribeFieldResult fieldResult = Room__c.Room_Type__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                roomTypes.add(entry.getValue());
            }
            
            return roomTypes;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting room types: ' + e.getMessage());
        }
    }
    
    /**
     * Get equipment types for filter options
     * @return List of equipment types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getEquipmentTypes() {
        try {
            List<String> equipmentTypes = new List<String>();
            Schema.DescribeFieldResult fieldResult = Equipment__c.Equipment_Type__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                equipmentTypes.add(entry.getValue());
            }
            
            return equipmentTypes;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting equipment types: ' + e.getMessage());
        }
    }
    
    // Wrapper classes for LWC data transfer
    
    public class RoomWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String roomType;
        @AuraEnabled public Integer capacity;
        @AuraEnabled public String floor;
        @AuraEnabled public List<String> amenities;
    }
    
    public class EquipmentWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String equipmentType;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String currentLocation;
        @AuraEnabled public Boolean isAvailable;
    }
    
    public class BookingRequestWrapper {
        @AuraEnabled public String userId;
        @AuraEnabled public String bookingType;
        @AuraEnabled public String roomId;
        @AuraEnabled public String equipmentId;
        @AuraEnabled public String startDateTime;
        @AuraEnabled public String endDateTime;
        @AuraEnabled public String purpose;
        @AuraEnabled public Integer attendeeCount;
        @AuraEnabled public String notes;
    }
    
    public class BookingResultWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String successMessage;
        @AuraEnabled public String bookingId;
    }
    
    public class BookingWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String bookingType;
        @AuraEnabled public String status;
        @AuraEnabled public String startDateTime;
        @AuraEnabled public String endDateTime;
        @AuraEnabled public String purpose;
        @AuraEnabled public Integer attendeeCount;
        @AuraEnabled public String returnStatus;
        @AuraEnabled public String notes;
        @AuraEnabled public String resourceName;
        @AuraEnabled public String resourceDetails;
    }
} 