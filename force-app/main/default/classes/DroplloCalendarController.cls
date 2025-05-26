/**
 * Lightning Web Component Controller for Dropillo Calendar Services
 * Exposes calendar and availability functionality to LWC components
 * 
 * @version 1.0
 * @author Dropillo Team
 */
public with sharing class DroplloCalendarController {
    
    /**
     * Get calendar data for rooms
     * @param startDate Start date for calendar view
     * @param endDate End date for calendar view
     * @param roomIds Optional list of room IDs to filter
     * @return Calendar data for rooms
     */
    @AuraEnabled(cacheable=true)
    public static CalendarDataWrapper getRoomCalendarData(String startDate, String endDate, List<String> roomIds) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            List<Id> roomIdsList = new List<Id>();
            
            if (roomIds != null && !roomIds.isEmpty()) {
                for (String roomId : roomIds) {
                    roomIdsList.add(Id.valueOf(roomId));
                }
            }
            
            DroplloCalendarService.CalendarData calendarData = DroplloCalendarService.getRoomCalendarData(
                startDt, endDt, roomIdsList
            );
            
            CalendarDataWrapper wrapper = new CalendarDataWrapper();
            wrapper.isSuccess = calendarData.isSuccess;
            wrapper.errorMessage = calendarData.errorMessage;
            wrapper.startDate = startDate;
            wrapper.endDate = endDate;
            wrapper.resourceType = calendarData.resourceType;
            wrapper.resources = new List<CalendarResourceWrapper>();
            
            if (calendarData.resources != null) {
                for (DroplloCalendarService.CalendarResource resource : calendarData.resources) {
                    CalendarResourceWrapper resourceWrapper = new CalendarResourceWrapper();
                    resourceWrapper.id = resource.id;
                    resourceWrapper.name = resource.name;
                    resourceWrapper.type = resource.type;
                    resourceWrapper.capacity = resource.capacity;
                    resourceWrapper.details = resource.details;
                    resourceWrapper.isAvailable = resource.isAvailable;
                    resourceWrapper.amenities = resource.amenities;
                    resourceWrapper.bookings = new List<CalendarBookingWrapper>();
                    
                    if (resource.bookings != null) {
                        for (DroplloCalendarService.CalendarBooking booking : resource.bookings) {
                            CalendarBookingWrapper bookingWrapper = new CalendarBookingWrapper();
                            bookingWrapper.id = booking.id;
                            bookingWrapper.name = booking.name;
                            bookingWrapper.startDateTime = booking.startDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                            bookingWrapper.endDateTime = booking.endDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                            bookingWrapper.status = booking.status;
                            bookingWrapper.purpose = booking.purpose;
                            bookingWrapper.bookedBy = booking.bookedBy;
                            bookingWrapper.attendeeCount = booking.attendeeCount;
                            
                            resourceWrapper.bookings.add(bookingWrapper);
                        }
                    }
                    
                    wrapper.resources.add(resourceWrapper);
                }
            }
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting room calendar data: ' + e.getMessage());
        }
    }
    
    /**
     * Get calendar data for equipment
     * @param startDate Start date for calendar view
     * @param endDate End date for calendar view
     * @param equipmentIds Optional list of equipment IDs to filter
     * @return Calendar data for equipment
     */
    @AuraEnabled(cacheable=true)
    public static CalendarDataWrapper getEquipmentCalendarData(String startDate, String endDate, List<String> equipmentIds) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            List<Id> equipmentIdsList = new List<Id>();
            
            if (equipmentIds != null && !equipmentIds.isEmpty()) {
                for (String equipmentId : equipmentIds) {
                    equipmentIdsList.add(Id.valueOf(equipmentId));
                }
            }
            
            DroplloCalendarService.CalendarData calendarData = DroplloCalendarService.getEquipmentCalendarData(
                startDt, endDt, equipmentIdsList
            );
            
            CalendarDataWrapper wrapper = new CalendarDataWrapper();
            wrapper.isSuccess = calendarData.isSuccess;
            wrapper.errorMessage = calendarData.errorMessage;
            wrapper.startDate = startDate;
            wrapper.endDate = endDate;
            wrapper.resourceType = calendarData.resourceType;
            wrapper.resources = new List<CalendarResourceWrapper>();
            
            if (calendarData.resources != null) {
                for (DroplloCalendarService.CalendarResource resource : calendarData.resources) {
                    CalendarResourceWrapper resourceWrapper = new CalendarResourceWrapper();
                    resourceWrapper.id = resource.id;
                    resourceWrapper.name = resource.name;
                    resourceWrapper.type = resource.type;
                    resourceWrapper.details = resource.details;
                    resourceWrapper.isAvailable = resource.isAvailable;
                    resourceWrapper.amenities = resource.amenities;
                    resourceWrapper.bookings = new List<CalendarBookingWrapper>();
                    
                    if (resource.bookings != null) {
                        for (DroplloCalendarService.CalendarBooking booking : resource.bookings) {
                            CalendarBookingWrapper bookingWrapper = new CalendarBookingWrapper();
                            bookingWrapper.id = booking.id;
                            bookingWrapper.name = booking.name;
                            bookingWrapper.startDateTime = booking.startDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                            bookingWrapper.endDateTime = booking.endDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                            bookingWrapper.status = booking.status;
                            bookingWrapper.purpose = booking.purpose;
                            bookingWrapper.bookedBy = booking.bookedBy;
                            bookingWrapper.returnStatus = booking.returnStatus;
                            
                            resourceWrapper.bookings.add(bookingWrapper);
                        }
                    }
                    
                    wrapper.resources.add(resourceWrapper);
                }
            }
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting equipment calendar data: ' + e.getMessage());
        }
    }
    
    /**
     * Get available time slots for a resource
     * @param resourceId Resource ID (room or equipment)
     * @param resourceType 'Room' or 'Equipment'
     * @param targetDate Date to check availability
     * @param duration Duration in hours
     * @return List of available time slots
     */
    @AuraEnabled(cacheable=true)
    public static List<TimeSlotWrapper> getAvailableTimeSlots(String resourceId, String resourceType, String targetDate, Integer duration) {
        try {
            Date targetDt = Date.valueOf(targetDate);
            Id resourceIdVal = Id.valueOf(resourceId);
            
            List<DroplloCalendarService.TimeSlot> timeSlots = DroplloCalendarService.getAvailableTimeSlots(
                resourceIdVal, resourceType, targetDt, duration
            );
            
            List<TimeSlotWrapper> wrappers = new List<TimeSlotWrapper>();
            
            for (DroplloCalendarService.TimeSlot slot : timeSlots) {
                TimeSlotWrapper wrapper = new TimeSlotWrapper();
                wrapper.startDateTime = slot.startDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                wrapper.endDateTime = slot.endDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                wrapper.duration = slot.duration;
                wrapper.isAvailable = slot.isAvailable;
                
                wrappers.add(wrapper);
            }
            
            return wrappers;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting available time slots: ' + e.getMessage());
        }
    }
    
    /**
     * Suggest alternative time slots
     * @param resourceType 'Room' or 'Equipment'
     * @param preferredStartDateTime Preferred start time
     * @param duration Duration in hours
     * @param searchCriteria Search criteria for alternatives
     * @return List of alternative slot suggestions
     */
    @AuraEnabled
    public static List<AlternativeSlotWrapper> suggestAlternativeSlots(String resourceType, String preferredStartDateTime, Integer duration, AlternativeSearchCriteriaWrapper searchCriteria) {
        try {
            DateTime preferredStart = DateTime.valueOf(preferredStartDateTime);
            
            DroplloCalendarService.AlternativeSearchCriteria criteria = new DroplloCalendarService.AlternativeSearchCriteria();
            criteria.minCapacity = searchCriteria.minCapacity;
            criteria.equipmentType = searchCriteria.equipmentType;
            criteria.searchNextDays = searchCriteria.searchNextDays;
            criteria.preferredAmenities = searchCriteria.preferredAmenities;
            
            List<DroplloCalendarService.AlternativeSlot> alternatives = DroplloCalendarService.suggestAlternativeSlots(
                resourceType, preferredStart, duration, criteria
            );
            
            List<AlternativeSlotWrapper> wrappers = new List<AlternativeSlotWrapper>();
            
            for (DroplloCalendarService.AlternativeSlot alternative : alternatives) {
                AlternativeSlotWrapper wrapper = new AlternativeSlotWrapper();
                wrapper.resourceId = alternative.resourceId;
                wrapper.resourceName = alternative.resourceName;
                wrapper.resourceType = alternative.resourceType;
                wrapper.startDateTime = alternative.startDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                wrapper.endDateTime = alternative.endDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                wrapper.capacity = alternative.capacity;
                wrapper.details = alternative.details;
                wrapper.timeDifferenceMinutes = alternative.timeDifferenceMinutes;
                
                wrappers.add(wrapper);
            }
            
            return wrappers;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error suggesting alternative slots: ' + e.getMessage());
        }
    }
    
    /**
     * Get all amenities for filter options
     * @return List of all available amenities
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAllAmenities() {
        try {
            Set<String> amenitiesSet = new Set<String>();
            
            List<Room__c> rooms = [SELECT Amenities__c FROM Room__c WHERE Is_Active__c = true];
            
            for (Room__c room : rooms) {
                if (String.isNotBlank(room.Amenities__c)) {
                    try {
                        List<String> roomAmenities = (List<String>) JSON.deserialize(room.Amenities__c, List<String>.class);
                        amenitiesSet.addAll(roomAmenities);
                    } catch (Exception e) {
                        // Skip invalid JSON
                    }
                }
            }
            
            return new List<String>(amenitiesSet);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting amenities: ' + e.getMessage());
        }
    }
    
    // Wrapper classes for LWC data transfer
    
    public class CalendarDataWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public String resourceType;
        @AuraEnabled public List<CalendarResourceWrapper> resources;
    }
    
    public class CalendarResourceWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public Integer capacity;
        @AuraEnabled public String details;
        @AuraEnabled public Boolean isAvailable;
        @AuraEnabled public List<String> amenities;
        @AuraEnabled public List<CalendarBookingWrapper> bookings;
    }
    
    public class CalendarBookingWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String startDateTime;
        @AuraEnabled public String endDateTime;
        @AuraEnabled public String status;
        @AuraEnabled public String purpose;
        @AuraEnabled public String bookedBy;
        @AuraEnabled public Integer attendeeCount;
        @AuraEnabled public String returnStatus;
    }
    
    public class TimeSlotWrapper {
        @AuraEnabled public String startDateTime;
        @AuraEnabled public String endDateTime;
        @AuraEnabled public Integer duration;
        @AuraEnabled public Boolean isAvailable;
    }
    
    public class AlternativeSlotWrapper {
        @AuraEnabled public String resourceId;
        @AuraEnabled public String resourceName;
        @AuraEnabled public String resourceType;
        @AuraEnabled public String startDateTime;
        @AuraEnabled public String endDateTime;
        @AuraEnabled public Integer capacity;
        @AuraEnabled public String details;
        @AuraEnabled public Integer timeDifferenceMinutes;
    }
    
    public class AlternativeSearchCriteriaWrapper {
        @AuraEnabled public Integer minCapacity;
        @AuraEnabled public String equipmentType;
        @AuraEnabled public Integer searchNextDays;
        @AuraEnabled public List<String> preferredAmenities;
    }
} 