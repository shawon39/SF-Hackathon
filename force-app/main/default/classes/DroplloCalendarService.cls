/**
 * Calendar Service for managing calendar views and availability data
 * Provides functionality for calendar displays and time slot management
 * 
 * Features:
 * - Calendar view data for rooms and equipment
 * - Time slot availability checking
 * - Booking calendar integration
 * - Alternative time slot suggestions
 * 
 * @version 1.0
 * @author Dropillo Team
 */
public class DroplloCalendarService {
    
    /**
     * Get calendar data for rooms for a specific date range
     * @param startDate Start date for calendar
     * @param endDate End date for calendar
     * @param roomIds Specific room IDs to include (optional)
     * @return CalendarData containing rooms and their bookings
     */
    public static CalendarData getRoomCalendarData(Date startDate, Date endDate, List<Id> roomIds) {
        CalendarData calendarData = new CalendarData();
        calendarData.startDate = startDate;
        calendarData.endDate = endDate;
        calendarData.resourceType = 'Room';
        
        try {
            // Get rooms
            String roomQuery = 'SELECT Id, Name, Room_Type__c, Capacity__c, Floor__c, Amenities__c ';
            roomQuery += 'FROM Room__c WHERE Is_Active__c = true';
            
            if (roomIds != null && !roomIds.isEmpty()) {
                roomQuery += ' AND Id IN :roomIds';
            }
            
            roomQuery += ' ORDER BY Room_Type__c, Name';
            
            List<Room__c> rooms = Database.query(roomQuery);
            
            // Get bookings for the date range
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            List<Booking__c> bookings = [
                SELECT Id, Name, Room__c, Booking_User__c, Start_DateTime__c, End_DateTime__c, 
                       Status__c, Purpose__c, Attendee_Count__c,
                       Booking_User__r.Name
                FROM Booking__c 
                WHERE Room__c IN :rooms 
                AND Status__c != 'Cancelled'
                AND Start_DateTime__c < :endDateTime
                AND End_DateTime__c > :startDateTime
                ORDER BY Start_DateTime__c
            ];
            
            // Build calendar data
            calendarData.resources = new List<CalendarResource>();
            
            for (Room__c room : rooms) {
                CalendarResource resource = new CalendarResource();
                resource.id = room.Id;
                resource.name = room.Name;
                resource.type = room.Room_Type__c;
                resource.capacity = room.Capacity__c != null ? Integer.valueOf(room.Capacity__c) : 0;
                resource.details = 'Floor: ' + (room.Floor__c != null ? room.Floor__c : 'N/A');
                
                // Parse amenities
                if (String.isNotBlank(room.Amenities__c)) {
                    try {
                        resource.amenities = (List<String>) JSON.deserialize(room.Amenities__c, List<String>.class);
                    } catch (Exception e) {
                        resource.amenities = new List<String>();
                    }
                } else {
                    resource.amenities = new List<String>();
                }
                
                // Get bookings for this room
                resource.bookings = new List<CalendarBooking>();
                for (Booking__c booking : bookings) {
                    if (booking.Room__c == room.Id) {
                        CalendarBooking calBooking = new CalendarBooking();
                        calBooking.id = booking.Id;
                        calBooking.name = booking.Name;
                        calBooking.startDateTime = booking.Start_DateTime__c;
                        calBooking.endDateTime = booking.End_DateTime__c;
                        calBooking.status = booking.Status__c;
                        calBooking.purpose = booking.Purpose__c;
                        calBooking.bookedBy = booking.Booking_User__r.Name;
                        calBooking.attendeeCount = booking.Attendee_Count__c != null ? Integer.valueOf(booking.Attendee_Count__c) : 0;
                        
                        resource.bookings.add(calBooking);
                    }
                }
                
                calendarData.resources.add(resource);
            }
            
            calendarData.isSuccess = true;
            
        } catch (Exception e) {
            calendarData.isSuccess = false;
            calendarData.errorMessage = 'Failed to get room calendar data: ' + e.getMessage();
            System.debug('Calendar service error: ' + e.getMessage());
        }
        
        return calendarData;
    }
    
    /**
     * Get calendar data for equipment for a specific date range
     * @param startDate Start date for calendar
     * @param endDate End date for calendar
     * @param equipmentIds Specific equipment IDs to include (optional)
     * @return CalendarData containing equipment and their bookings
     */
    public static CalendarData getEquipmentCalendarData(Date startDate, Date endDate, List<Id> equipmentIds) {
        CalendarData calendarData = new CalendarData();
        calendarData.startDate = startDate;
        calendarData.endDate = endDate;
        calendarData.resourceType = 'Equipment';
        
        try {
            // Get equipment
            String equipmentQuery = 'SELECT Id, Name, Equipment_Type__c, Serial_Number__c, Current_Location__c, Is_Available__c ';
            equipmentQuery += 'FROM Equipment__c WHERE Is_Active__c = true';
            
            if (equipmentIds != null && !equipmentIds.isEmpty()) {
                equipmentQuery += ' AND Id IN :equipmentIds';
            }
            
            equipmentQuery += ' ORDER BY Equipment_Type__c, Name';
            
            List<Equipment__c> equipment = Database.query(equipmentQuery);
            
            // Get bookings for the date range
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            List<Booking__c> bookings = [
                SELECT Id, Name, Equipment__c, Booking_User__c, Start_DateTime__c, End_DateTime__c, 
                       Status__c, Purpose__c, Return_Status__c,
                       Booking_User__r.Name
                FROM Booking__c 
                WHERE Equipment__c IN :equipment 
                AND Status__c != 'Cancelled'
                AND Start_DateTime__c < :endDateTime
                AND End_DateTime__c > :startDateTime
                ORDER BY Start_DateTime__c
            ];
            
            // Build calendar data
            calendarData.resources = new List<CalendarResource>();
            
            for (Equipment__c equip : equipment) {
                CalendarResource resource = new CalendarResource();
                resource.id = equip.Id;
                resource.name = equip.Name;
                resource.type = equip.Equipment_Type__c;
                resource.details = 'Serial: ' + (equip.Serial_Number__c != null ? equip.Serial_Number__c : 'N/A') + 
                                 ', Location: ' + (equip.Current_Location__c != null ? equip.Current_Location__c : 'N/A');
                resource.isAvailable = equip.Is_Available__c;
                resource.amenities = new List<String>();
                
                // Get bookings for this equipment
                resource.bookings = new List<CalendarBooking>();
                for (Booking__c booking : bookings) {
                    if (booking.Equipment__c == equip.Id) {
                        CalendarBooking calBooking = new CalendarBooking();
                        calBooking.id = booking.Id;
                        calBooking.name = booking.Name;
                        calBooking.startDateTime = booking.Start_DateTime__c;
                        calBooking.endDateTime = booking.End_DateTime__c;
                        calBooking.status = booking.Status__c;
                        calBooking.purpose = booking.Purpose__c;
                        calBooking.bookedBy = booking.Booking_User__r.Name;
                        calBooking.returnStatus = booking.Return_Status__c;
                        
                        resource.bookings.add(calBooking);
                    }
                }
                
                calendarData.resources.add(resource);
            }
            
            calendarData.isSuccess = true;
            
        } catch (Exception e) {
            calendarData.isSuccess = false;
            calendarData.errorMessage = 'Failed to get equipment calendar data: ' + e.getMessage();
            System.debug('Calendar service error: ' + e.getMessage());
        }
        
        return calendarData;
    }
    
    /**
     * Get available time slots for a resource
     * @param resourceId Room or Equipment ID
     * @param resourceType 'Room' or 'Equipment'
     * @param targetDate Date to check
     * @param duration Duration in hours
     * @return List of available time slots
     */
    public static List<TimeSlot> getAvailableTimeSlots(Id resourceId, String resourceType, Date targetDate, Integer duration) {
        List<TimeSlot> availableSlots = new List<TimeSlot>();
        
        try {
            // Define business hours (8 AM to 8 PM)
            Integer startHour = 8;
            Integer endHour = 20;
            
            // Get existing bookings for the date
            DateTime dayStart = DateTime.newInstance(targetDate, Time.newInstance(startHour, 0, 0, 0));
            DateTime dayEnd = DateTime.newInstance(targetDate, Time.newInstance(endHour, 0, 0, 0));
            
            String queryField = resourceType == 'Room' ? 'Room__c' : 'Equipment__c';
            String query = 'SELECT Start_DateTime__c, End_DateTime__c FROM Booking__c ';
            query += 'WHERE ' + queryField + ' = :resourceId ';
            query += 'AND Status__c != \'Cancelled\' ';
            query += 'AND Start_DateTime__c < :dayEnd ';
            query += 'AND End_DateTime__c > :dayStart ';
            query += 'ORDER BY Start_DateTime__c';
            
            List<Booking__c> existingBookings = Database.query(query);
            
            // Generate available slots
            DateTime currentTime = dayStart;
            
            for (Booking__c booking : existingBookings) {
                DateTime bookingStart = booking.Start_DateTime__c;
                DateTime bookingEnd = booking.End_DateTime__c;
                
                // Check if there's a gap before this booking
                if (currentTime.addHours(duration) <= bookingStart) {
                    while (currentTime.addHours(duration) <= bookingStart && currentTime.hour() < endHour - duration) {
                        TimeSlot slot = new TimeSlot();
                        slot.startDateTime = currentTime;
                        slot.endDateTime = currentTime.addHours(duration);
                        slot.duration = duration;
                        slot.isAvailable = true;
                        availableSlots.add(slot);
                        
                        currentTime = currentTime.addHours(1); // Move to next hour
                    }
                }
                
                // Move current time to after this booking
                if (bookingEnd > currentTime) {
                    currentTime = bookingEnd;
                }
            }
            
            // Check for remaining slots at the end of the day
            while (currentTime.addHours(duration) <= dayEnd) {
                TimeSlot slot = new TimeSlot();
                slot.startDateTime = currentTime;
                slot.endDateTime = currentTime.addHours(duration);
                slot.duration = duration;
                slot.isAvailable = true;
                availableSlots.add(slot);
                
                currentTime = currentTime.addHours(1);
            }
            
        } catch (Exception e) {
            System.debug('Error getting available time slots: ' + e.getMessage());
        }
        
        return availableSlots;
    }
    
    /**
     * Suggest alternative time slots when preferred slot is not available
     * @param resourceType 'Room' or 'Equipment'
     * @param preferredStart Preferred start time
     * @param duration Duration in hours
     * @param criteria Search criteria for alternatives
     * @return List of alternative suggestions
     */
    public static List<AlternativeSlot> suggestAlternativeSlots(String resourceType, DateTime preferredStart, Integer duration, AlternativeSearchCriteria criteria) {
        List<AlternativeSlot> alternatives = new List<AlternativeSlot>();
        
        try {
            Date targetDate = preferredStart.date();
            
            // Search for alternatives on the same day first
            if (resourceType == 'Room') {
                alternatives.addAll(findAlternativeRooms(preferredStart, duration, criteria));
            } else if (resourceType == 'Equipment') {
                alternatives.addAll(findAlternativeEquipment(preferredStart, duration, criteria));
            }
            
            // If no alternatives found on same day, check next few days
            if (alternatives.isEmpty() && criteria.searchNextDays > 0) {
                for (Integer i = 1; i <= criteria.searchNextDays; i++) {
                    DateTime nextDayStart = preferredStart.addDays(i);
                    
                    if (resourceType == 'Room') {
                        alternatives.addAll(findAlternativeRooms(nextDayStart, duration, criteria));
                    } else if (resourceType == 'Equipment') {
                        alternatives.addAll(findAlternativeEquipment(nextDayStart, duration, criteria));
                    }
                    
                    if (alternatives.size() >= 5) break; // Limit to 5 alternatives
                }
            }
            
        } catch (Exception e) {
            System.debug('Error suggesting alternative slots: ' + e.getMessage());
        }
        
        return alternatives;
    }
    
    /**
     * Find alternative room suggestions
     */
    private static List<AlternativeSlot> findAlternativeRooms(DateTime preferredStart, Integer duration, AlternativeSearchCriteria criteria) {
        List<AlternativeSlot> alternatives = new List<AlternativeSlot>();
        
        // Get available rooms with similar capacity
        List<Room__c> availableRooms = DroplloBookingService.getAvailableRooms(
            preferredStart, 
            preferredStart.addHours(duration), 
            criteria.minCapacity
        );
        
        for (Room__c room : availableRooms) {
            List<TimeSlot> timeSlots = getAvailableTimeSlots(room.Id, 'Room', preferredStart.date(), duration);
            
            for (TimeSlot slot : timeSlots) {
                AlternativeSlot alternative = new AlternativeSlot();
                alternative.resourceId = room.Id;
                alternative.resourceName = room.Name;
                alternative.resourceType = 'Room';
                alternative.startDateTime = slot.startDateTime;
                alternative.endDateTime = slot.endDateTime;
                alternative.capacity = room.Capacity__c != null ? Integer.valueOf(room.Capacity__c) : 0;
                alternative.details = 'Floor: ' + (room.Floor__c != null ? room.Floor__c : 'N/A');
                
                // Calculate time difference from preferred slot
                Long timeDiffMinutes = Math.abs(slot.startDateTime.getTime() - preferredStart.getTime()) / (1000 * 60);
                alternative.timeDifferenceMinutes = Integer.valueOf(timeDiffMinutes);
                
                alternatives.add(alternative);
                
                if (alternatives.size() >= 10) return alternatives; // Limit results
            }
        }
        
        return alternatives;
    }
    
    /**
     * Find alternative equipment suggestions
     */
    private static List<AlternativeSlot> findAlternativeEquipment(DateTime preferredStart, Integer duration, AlternativeSearchCriteria criteria) {
        List<AlternativeSlot> alternatives = new List<AlternativeSlot>();
        
        // Get available equipment of the same type
        List<Equipment__c> availableEquipment = DroplloBookingService.getAvailableEquipment(
            preferredStart, 
            preferredStart.addHours(duration), 
            criteria.equipmentType
        );
        
        for (Equipment__c equipment : availableEquipment) {
            List<TimeSlot> timeSlots = getAvailableTimeSlots(equipment.Id, 'Equipment', preferredStart.date(), duration);
            
            for (TimeSlot slot : timeSlots) {
                AlternativeSlot alternative = new AlternativeSlot();
                alternative.resourceId = equipment.Id;
                alternative.resourceName = equipment.Name;
                alternative.resourceType = 'Equipment';
                alternative.startDateTime = slot.startDateTime;
                alternative.endDateTime = slot.endDateTime;
                alternative.details = 'Type: ' + equipment.Equipment_Type__c + ', Serial: ' + equipment.Serial_Number__c;
                
                // Calculate time difference from preferred slot
                Long timeDiffMinutes = Math.abs(slot.startDateTime.getTime() - preferredStart.getTime()) / (1000 * 60);
                alternative.timeDifferenceMinutes = Integer.valueOf(timeDiffMinutes);
                
                alternatives.add(alternative);
                
                if (alternatives.size() >= 10) return alternatives; // Limit results
            }
        }
        
        return alternatives;
    }
    
    // Inner classes for data structures
    
    /**
     * Calendar data wrapper
     */
    public class CalendarData {
        public Boolean isSuccess = false;
        public String errorMessage;
        public Date startDate;
        public Date endDate;
        public String resourceType;
        public List<CalendarResource> resources;
    }
    
    /**
     * Calendar resource (Room or Equipment)
     */
    public class CalendarResource {
        public Id id;
        public String name;
        public String type;
        public Integer capacity;
        public String details;
        public Boolean isAvailable = true;
        public List<String> amenities;
        public List<CalendarBooking> bookings;
    }
    
    /**
     * Calendar booking
     */
    public class CalendarBooking {
        public Id id;
        public String name;
        public DateTime startDateTime;
        public DateTime endDateTime;
        public String status;
        public String purpose;
        public String bookedBy;
        public Integer attendeeCount;
        public String returnStatus;
    }
    
    /**
     * Time slot
     */
    public class TimeSlot {
        public DateTime startDateTime;
        public DateTime endDateTime;
        public Integer duration;
        public Boolean isAvailable;
    }
    
    /**
     * Alternative slot suggestion
     */
    public class AlternativeSlot {
        public Id resourceId;
        public String resourceName;
        public String resourceType;
        public DateTime startDateTime;
        public DateTime endDateTime;
        public Integer capacity;
        public String details;
        public Integer timeDifferenceMinutes;
    }
    
    /**
     * Search criteria for alternatives
     */
    public class AlternativeSearchCriteria {
        public Integer minCapacity;
        public String equipmentType;
        public Integer searchNextDays = 3;
        public List<String> preferredAmenities;
    }
} 