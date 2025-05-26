/**
 * Service class for suggesting alternative time slots when preferred slots are unavailable
 * Bonus feature to enhance user experience
 */
public class AlternativeSlotService {
    
    /**
     * Suggest alternative time slots for room booking
     * @param roomId ID of the room to book
     * @param preferredStart Preferred start time
     * @param preferredEnd Preferred end time
     * @param numberOfSuggestions Number of alternative slots to suggest
     * @return List of alternative time slots
     */
    @AuraEnabled(cacheable=false)
    public static List<TimeSlotSuggestion> suggestAlternativeRoomSlots(String roomId, String preferredStart, String preferredEnd, Integer numberOfSuggestions) {
        try {
            DateTime startDT = parseDateTime(preferredStart);
            DateTime endDT = parseDateTime(preferredEnd);
            Long durationMinutes = (endDT.getTime() - startDT.getTime()) / (1000 * 60);
            
            if (numberOfSuggestions == null || numberOfSuggestions <= 0) {
                numberOfSuggestions = 3;
            }
            
            List<TimeSlotSuggestion> suggestions = new List<TimeSlotSuggestion>();
            
            // Get existing bookings for the room for the next 7 days
            DateTime searchStart = startDT.date();
            DateTime searchEnd = searchStart.addDays(7);
            
            List<Booking__c> existingBookings = [
                SELECT Start_DateTime__c, End_DateTime__c
                FROM Booking__c
                WHERE Room__c = :roomId
                AND Status__c IN ('Pending', 'Confirmed', 'In_Use')
                AND Start_DateTime__c >= :searchStart
                AND End_DateTime__c <= :searchEnd
                ORDER BY Start_DateTime__c ASC
            ];
            
            // Generate time slots for business hours (9 AM to 6 PM)
            List<DateTime> potentialSlots = generateBusinessHourSlots(searchStart, searchEnd, Integer.valueOf(durationMinutes));
            
            // Filter out conflicting slots
            for (DateTime slotStart : potentialSlots) {
                DateTime slotEnd = slotStart.addMinutes(Integer.valueOf(durationMinutes));
                
                Boolean isAvailable = true;
                for (Booking__c booking : existingBookings) {
                    if (isTimeSlotConflicting(slotStart, slotEnd, booking.Start_DateTime__c, booking.End_DateTime__c)) {
                        isAvailable = false;
                        break;
                    }
                }
                
                if (isAvailable && suggestions.size() < numberOfSuggestions) {
                    TimeSlotSuggestion suggestion = new TimeSlotSuggestion();
                    suggestion.startDateTime = slotStart;
                    suggestion.endDateTime = slotEnd;
                    suggestion.formattedStart = slotStart.format('MMM dd, yyyy HH:mm');
                    suggestion.formattedEnd = slotEnd.format('MMM dd, yyyy HH:mm');
                    suggestion.dayOfWeek = slotStart.format('EEEE');
                    suggestion.isToday = slotStart.date() == Date.today();
                    suggestion.isTomorrow = slotStart.date() == Date.today().addDays(1);
                    
                    suggestions.add(suggestion);
                }
                
                if (suggestions.size() >= numberOfSuggestions) {
                    break;
                }
            }
            
            return suggestions;
            
        } catch (Exception e) {
            throw new AlternativeSlotException('Error generating alternative slots: ' + e.getMessage());
        }
    }
    
    /**
     * Generate potential time slots during business hours
     * @param startDate Start date for search
     * @param endDate End date for search
     * @param durationMinutes Duration of the booking in minutes
     * @return List of potential start times
     */
    private static List<DateTime> generateBusinessHourSlots(DateTime startDate, DateTime endDate, Integer durationMinutes) {
        List<DateTime> slots = new List<DateTime>();
        
        DateTime currentDate = startDate;
        while (currentDate <= endDate) {
            // Skip weekends
            String dayOfWeek = currentDate.format('EEEE');
            if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
                
                // Generate slots from 9 AM to 6 PM with 30-minute intervals
                for (Integer hour = 9; hour < 18; hour++) {
                    for (Integer minute = 0; minute < 60; minute += 30) {
                        DateTime slotStart = DateTime.newInstance(currentDate.date(), Time.newInstance(hour, minute, 0, 0));
                        DateTime slotEnd = slotStart.addMinutes(durationMinutes);
                        
                        // Ensure the slot ends before 6 PM
                        if (slotEnd.hour() <= 18) {
                            // Only suggest future slots
                            if (slotStart > System.now()) {
                                slots.add(slotStart);
                            }
                        }
                    }
                }
            }
            currentDate = currentDate.addDays(1);
        }
        
        return slots;
    }
    
    /**
     * Check if two time slots are conflicting
     * @param start1 Start time of first slot
     * @param end1 End time of first slot
     * @param start2 Start time of second slot
     * @param end2 End time of second slot
     * @return True if slots conflict, false otherwise
     */
    private static Boolean isTimeSlotConflicting(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
        return (start1 < end2 && end1 > start2);
    }
    
    /**
     * Helper method to parse datetime strings from various formats
     * @param dateTimeStr String representation of datetime
     * @return Parsed DateTime object
     */
    private static DateTime parseDateTime(String dateTimeStr) {
        if (String.isBlank(dateTimeStr)) {
            throw new AlternativeSlotException('DateTime string cannot be blank');
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
            throw new AlternativeSlotException('Invalid date/time format: ' + dateTimeStr + '. Expected format: yyyy-MM-dd HH:mm or yyyy-MM-ddTHH:mm');
        }
    }
    
    /**
     * Wrapper class for time slot suggestions
     */
    public class TimeSlotSuggestion {
        @AuraEnabled public DateTime startDateTime;
        @AuraEnabled public DateTime endDateTime;
        @AuraEnabled public String formattedStart;
        @AuraEnabled public String formattedEnd;
        @AuraEnabled public String dayOfWeek;
        @AuraEnabled public Boolean isToday;
        @AuraEnabled public Boolean isTomorrow;
    }
    
    /**
     * Custom exception for alternative slot service
     */
    public class AlternativeSlotException extends Exception {}
}