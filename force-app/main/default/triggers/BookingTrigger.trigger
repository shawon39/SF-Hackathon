/**
 * Trigger for Booking__c to handle activity logging and notifications
 * Creates reminder tasks when bookings are created or updated
 */
trigger BookingTrigger on Booking__c (after insert, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            BookingTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            BookingTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
} 