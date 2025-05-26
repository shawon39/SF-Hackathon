/**
 * Trigger for Booking__c object
 * Handles booking insert and update events to create reminder tasks and send notifications
 * 
 * Requirements:
 * - Create a Task assigned to the booking user as a reminder on insert/update
 * - Send email notifications for booking confirmations
 * - Update equipment availability status
 * 
 * @version 1.0
 * @author Dropillo Team
 */
trigger BookingTrigger on Booking__c (after insert, after update, before update) {
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Handle before update logic if needed
        BookingTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        // Handle new bookings
        BookingTriggerHandler.handleAfterInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Handle booking updates
        BookingTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
} 