/**
 * Handler class for BookingTrigger
 * Manages activity logging and email notifications for booking records
 */
public class BookingTriggerHandler {
    
    /**
     * Handle after insert operations
     * @param newBookings List of newly inserted booking records
     */
    public static void handleAfterInsert(List<Booking__c> newBookings) {
        createReminderTasks(newBookings);
        sendBookingNotifications(newBookings);
    }
    
    /**
     * Handle after update operations
     * @param newBookings List of updated booking records
     * @param oldBookingMap Map of old booking records
     */
    public static void handleAfterUpdate(List<Booking__c> newBookings, Map<Id, Booking__c> oldBookingMap) {
        List<Booking__c> statusChangedBookings = new List<Booking__c>();
        
        for (Booking__c booking : newBookings) {
            Booking__c oldBooking = oldBookingMap.get(booking.Id);
            
            // Check if status changed
            if (booking.Status__c != oldBooking.Status__c) {
                statusChangedBookings.add(booking);
            }
        }
        
        if (!statusChangedBookings.isEmpty()) {
            createReminderTasks(statusChangedBookings);
            sendStatusUpdateNotifications(statusChangedBookings);
        }
    }
    
    /**
     * Create reminder tasks for booking users
     * @param bookings List of booking records
     */
    private static void createReminderTasks(List<Booking__c> bookings) {
        List<Task> tasksToInsert = new List<Task>();
        
        // Get room and equipment details for task descriptions
        Set<Id> roomIds = new Set<Id>();
        Set<Id> equipmentIds = new Set<Id>();
        
        for (Booking__c booking : bookings) {
            if (booking.Room__c != null) {
                roomIds.add(booking.Room__c);
            }
            if (booking.Equipment__c != null) {
                equipmentIds.add(booking.Equipment__c);
            }
        }
        
        Map<Id, Room__c> roomMap = new Map<Id, Room__c>();
        if (!roomIds.isEmpty()) {
            roomMap = new Map<Id, Room__c>([
                SELECT Id, Name, Room_Type__c, Floor__c 
                FROM Room__c 
                WHERE Id IN :roomIds
            ]);
        }
        
        Map<Id, Equipment__c> equipmentMap = new Map<Id, Equipment__c>();
        if (!equipmentIds.isEmpty()) {
            equipmentMap = new Map<Id, Equipment__c>([
                SELECT Id, Name, Equipment_Type__c, Current_Location__c 
                FROM Equipment__c 
                WHERE Id IN :equipmentIds
            ]);
        }
        
        for (Booking__c booking : bookings) {
            // Create reminder task
            Task reminderTask = new Task();
            reminderTask.WhatId = booking.Id;
            reminderTask.OwnerId = booking.Booking_User__c;
            reminderTask.Status = 'Open';
            reminderTask.Priority = 'Normal';
            
            String resourceName = '';
            String resourceLocation = '';
            
            if (booking.Room__c != null && roomMap.containsKey(booking.Room__c)) {
                Room__c room = roomMap.get(booking.Room__c);
                resourceName = room.Name;
                resourceLocation = room.Floor__c;
                reminderTask.Subject = 'Room Booking Reminder: ' + room.Name;
            } else if (booking.Equipment__c != null && equipmentMap.containsKey(booking.Equipment__c)) {
                Equipment__c equipment = equipmentMap.get(booking.Equipment__c);
                resourceName = equipment.Name;
                resourceLocation = equipment.Current_Location__c;
                reminderTask.Subject = 'Equipment Booking Reminder: ' + equipment.Name;
            } else {
                reminderTask.Subject = 'Booking Reminder';
            }
            
            // Set task due date to booking start time
            if (booking.Start_DateTime__c != null) {
                reminderTask.ActivityDate = booking.Start_DateTime__c.date();
            }
            
            // Create task description
            String description = 'Booking Status: ' + booking.Status__c + '\n';
            description += 'Resource: ' + resourceName + '\n';
            if (String.isNotBlank(resourceLocation)) {
                description += 'Location: ' + resourceLocation + '\n';
            }
            description += 'Start Time: ' + booking.Start_DateTime__c?.format('yyyy-MM-dd HH:mm') + '\n';
            description += 'End Time: ' + booking.End_DateTime__c?.format('yyyy-MM-dd HH:mm') + '\n';
            if (String.isNotBlank(booking.Purpose__c)) {
                description += 'Purpose: ' + booking.Purpose__c + '\n';
            }
            
            reminderTask.Description = description;
            
            tasksToInsert.add(reminderTask);
        }
        
        if (!tasksToInsert.isEmpty()) {
            try {
                insert tasksToInsert;
                System.debug('Created ' + tasksToInsert.size() + ' reminder tasks');
            } catch (DmlException e) {
                System.debug('Error creating reminder tasks: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Send booking confirmation notifications
     * @param bookings List of newly created bookings
     */
    private static void sendBookingNotifications(List<Booking__c> bookings) {
        // Get user email addresses
        Set<Id> userIds = new Set<Id>();
        for (Booking__c booking : bookings) {
            userIds.add(booking.Booking_User__c);
        }
        
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Email, Name 
            FROM User 
            WHERE Id IN :userIds
        ]);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Booking__c booking : bookings) {
            if (userMap.containsKey(booking.Booking_User__c)) {
                User bookingUser = userMap.get(booking.Booking_User__c);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{bookingUser.Email});
                email.setSubject('Dropillo Space & Asset Hub - Booking Confirmation');
                
                String emailBody = 'Dear ' + bookingUser.Name + ',\n\n';
                emailBody += 'Your booking has been confirmed!\n\n';
                emailBody += 'Booking Details:\n';
                emailBody += '• Booking ID: ' + booking.Name + '\n';
                emailBody += '• Type: ' + booking.Booking_Type__c + '\n';
                emailBody += '• Start Time: ' + booking.Start_DateTime__c?.format('yyyy-MM-dd HH:mm') + '\n';
                emailBody += '• End Time: ' + booking.End_DateTime__c?.format('yyyy-MM-dd HH:mm') + '\n';
                emailBody += '• Status: ' + booking.Status__c + '\n';
                
                if (String.isNotBlank(booking.Purpose__c)) {
                    emailBody += '• Purpose: ' + booking.Purpose__c + '\n';
                }
                
                emailBody += '\nPlease ensure you arrive on time and follow company policies.\n\n';
                emailBody += 'Best regards,\n';
                emailBody += 'Dropillo Space & Asset Hub';
                
                email.setPlainTextBody(emailBody);
                emails.add(email);
            }
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                
                // Update notification sent flag - create new instances to avoid read-only error
                List<Booking__c> bookingsToUpdate = new List<Booking__c>();
                for (Booking__c booking : bookings) {
                    Booking__c bookingUpdate = new Booking__c();
                    bookingUpdate.Id = booking.Id;
                    bookingUpdate.Notification_Sent__c = true;
                    bookingsToUpdate.add(bookingUpdate);
                }
                update bookingsToUpdate;
                
                System.debug('Sent ' + emails.size() + ' booking confirmation emails');
            } catch (EmailException e) {
                System.debug('Error sending booking confirmation emails: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Send status update notifications
     * @param bookings List of bookings with status changes
     */
    private static void sendStatusUpdateNotifications(List<Booking__c> bookings) {
        // Get user email addresses
        Set<Id> userIds = new Set<Id>();
        for (Booking__c booking : bookings) {
            userIds.add(booking.Booking_User__c);
        }
        
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Email, Name 
            FROM User 
            WHERE Id IN :userIds
        ]);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Booking__c booking : bookings) {
            if (userMap.containsKey(booking.Booking_User__c)) {
                User bookingUser = userMap.get(booking.Booking_User__c);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{bookingUser.Email});
                email.setSubject('Dropillo Space & Asset Hub - Booking Status Update');
                
                String emailBody = 'Dear ' + bookingUser.Name + ',\n\n';
                emailBody += 'Your booking status has been updated.\n\n';
                emailBody += 'Booking Details:\n';
                emailBody += '• Booking ID: ' + booking.Name + '\n';
                emailBody += '• New Status: ' + booking.Status__c + '\n';
                emailBody += '• Start Time: ' + booking.Start_DateTime__c?.format('yyyy-MM-dd HH:mm') + '\n';
                emailBody += '• End Time: ' + booking.End_DateTime__c?.format('yyyy-MM-dd HH:mm') + '\n';
                
                if (booking.Status__c == 'Cancelled') {
                    emailBody += '\nYour booking has been cancelled. If you did not request this cancellation, please contact the administrator.\n';
                } else if (booking.Status__c == 'Confirmed') {
                    emailBody += '\nYour booking is now confirmed. Please arrive on time.\n';
                } else if (booking.Status__c == 'Completed') {
                    emailBody += '\nThank you for using Dropillo Space & Asset Hub!\n';
                }
                
                emailBody += '\nBest regards,\n';
                emailBody += 'Dropillo Space & Asset Hub';
                
                email.setPlainTextBody(emailBody);
                emails.add(email);
            }
        }
        
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
                System.debug('Sent ' + emails.size() + ' status update emails');
            } catch (EmailException e) {
                System.debug('Error sending status update emails: ' + e.getMessage());
            }
        }
    }
} 