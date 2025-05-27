/**
 * Notification Service for sending booking-related emails
 * Handles email notifications for booking confirmations, reminders, and status updates
 * 
 * Features:
 * - Booking confirmation emails
 * - Booking reminder emails
 * - Equipment return reminders
 * - Booking status update notifications
 * 
 * @version 1.0
 * @author Dropillo Team
 */
public class DroplloNotificationService {
    
    /**
     * Send booking confirmation email
     * @param booking Booking record to send confirmation for
     * @return Boolean true if email sent successfully
     */
    public static Boolean sendBookingConfirmation(Booking__c booking) {
        try {
            // Get booking user details
            User bookingUser = [SELECT Id, Name, Email FROM User WHERE Id = :booking.Booking_User__c LIMIT 1];
            
            // Get room or equipment details
            String resourceName = '';
            String resourceType = '';
            String resourceDetails = '';
            
            if (booking.Booking_Type__c == 'Room' && booking.Room__c != null) {
                Room__c room = [SELECT Name, Room_Type__c, Capacity__c, Floor__c FROM Room__c WHERE Id = :booking.Room__c LIMIT 1];
                resourceName = room.Name;
                resourceType = 'Room';
                resourceDetails = 'Type: ' + room.Room_Type__c + ', Capacity: ' + room.Capacity__c + ', Floor: ' + room.Floor__c;
            } else if (booking.Booking_Type__c == 'Equipment' && booking.Equipment__c != null) {
                Equipment__c equipment = [SELECT Name, Equipment_Type__c, Serial_Number__c FROM Equipment__c WHERE Id = :booking.Equipment__c LIMIT 1];
                resourceName = equipment.Name;
                resourceType = 'Equipment';
                resourceDetails = 'Type: ' + equipment.Equipment_Type__c + ', Serial: ' + equipment.Serial_Number__c;
            }
            
            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{bookingUser.Email});
            email.setSubject('Booking Confirmation - ' + resourceName);
            
            String htmlBody = buildBookingConfirmationHtml(booking, bookingUser, resourceName, resourceType, resourceDetails);
            email.setHtmlBody(htmlBody);
            
            String plainTextBody = buildBookingConfirmationText(booking, bookingUser, resourceName, resourceType, resourceDetails);
            email.setPlainTextBody(plainTextBody);
            
            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            // Update booking to mark notification as sent
            booking.Notification_Sent__c = true;
            update booking;
            
            System.debug('Booking confirmation email sent successfully for booking: ' + booking.Id);
            return true;
            
        } catch (Exception e) {
            System.debug('Failed to send booking confirmation email: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Send booking reminder email
     * @param booking Booking record to send reminder for
     * @param reminderType Type of reminder ('start_soon', 'equipment_return', etc.)
     * @return Boolean true if email sent successfully
     */
    public static Boolean sendBookingReminder(Booking__c booking, String reminderType) {
        try {
            // Get booking user details
            User bookingUser = [SELECT Id, Name, Email FROM User WHERE Id = :booking.Booking_User__c LIMIT 1];
            
            // Get resource details
            String resourceName = '';
            String resourceType = '';
            
            if (booking.Booking_Type__c == 'Room' && booking.Room__c != null) {
                Room__c room = [SELECT Name FROM Room__c WHERE Id = :booking.Room__c LIMIT 1];
                resourceName = room.Name;
                resourceType = 'Room';
            } else if (booking.Booking_Type__c == 'Equipment' && booking.Equipment__c != null) {
                Equipment__c equipment = [SELECT Name FROM Equipment__c WHERE Id = :booking.Equipment__c LIMIT 1];
                resourceName = equipment.Name;
                resourceType = 'Equipment';
            }
            
            // Create email based on reminder type
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{bookingUser.Email});
            
            String subject = '';
            String htmlBody = '';
            String plainTextBody = '';
            
            if (reminderType == 'start_soon') {
                subject = 'Booking Reminder - ' + resourceName + ' starts soon';
                htmlBody = buildStartSoonReminderHtml(booking, bookingUser, resourceName, resourceType);
                plainTextBody = buildStartSoonReminderText(booking, bookingUser, resourceName, resourceType);
            } else if (reminderType == 'equipment_return') {
                subject = 'Equipment Return Reminder - ' + resourceName;
                htmlBody = buildEquipmentReturnReminderHtml(booking, bookingUser, resourceName);
                plainTextBody = buildEquipmentReturnReminderText(booking, bookingUser, resourceName);
            }
            
            email.setSubject(subject);
            email.setHtmlBody(htmlBody);
            email.setPlainTextBody(plainTextBody);
            
            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            System.debug('Booking reminder email sent successfully for booking: ' + booking.Id);
            return true;
            
        } catch (Exception e) {
            System.debug('Failed to send booking reminder email: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Send booking cancellation email
     * @param booking Cancelled booking record
     * @return Boolean true if email sent successfully
     */
    public static Boolean sendBookingCancellation(Booking__c booking) {
        try {
            // Get booking user details
            User bookingUser = [SELECT Id, Name, Email FROM User WHERE Id = :booking.Booking_User__c LIMIT 1];
            
            // Get resource details
            String resourceName = '';
            String resourceType = '';
            
            if (booking.Booking_Type__c == 'Room' && booking.Room__c != null) {
                Room__c room = [SELECT Name FROM Room__c WHERE Id = :booking.Room__c LIMIT 1];
                resourceName = room.Name;
                resourceType = 'Room';
            } else if (booking.Booking_Type__c == 'Equipment' && booking.Equipment__c != null) {
                Equipment__c equipment = [SELECT Name FROM Equipment__c WHERE Id = :booking.Equipment__c LIMIT 1];
                resourceName = equipment.Name;
                resourceType = 'Equipment';
            }
            
            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{bookingUser.Email});
            email.setSubject('Booking Cancelled - ' + resourceName);
            
            String htmlBody = buildBookingCancellationHtml(booking, bookingUser, resourceName, resourceType);
            email.setHtmlBody(htmlBody);
            
            String plainTextBody = buildBookingCancellationText(booking, bookingUser, resourceName, resourceType);
            email.setPlainTextBody(plainTextBody);
            
            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            System.debug('Booking cancellation email sent successfully for booking: ' + booking.Id);
            return true;
            
        } catch (Exception e) {
            System.debug('Failed to send booking cancellation email: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Build HTML body for booking confirmation email
     */
    private static String buildBookingConfirmationHtml(Booking__c booking, User bookingUser, String resourceName, String resourceType, String resourceDetails) {
        String html = '<html><body>';
        html += '<h2>Booking Confirmation</h2>';
        html += '<p>Dear ' + bookingUser.Name + ',</p>';
        html += '<p>Your booking has been confirmed. Here are the details:</p>';
        html += '<table border="1" style="border-collapse: collapse; margin: 20px 0;">';
        html += '<tr><td><strong>Booking ID:</strong></td><td>' + booking.Name + '</td></tr>';
        html += '<tr><td><strong>' + resourceType + ':</strong></td><td>' + resourceName + '</td></tr>';
        html += '<tr><td><strong>Start:</strong></td><td>' + booking.Start_DateTime__c.format() + '</td></tr>';
        html += '<tr><td><strong>End:</strong></td><td>' + booking.End_DateTime__c.format() + '</td></tr>';
        if (String.isNotBlank(resourceDetails)) {
            html += '<tr><td><strong>Details:</strong></td><td>' + resourceDetails + '</td></tr>';
        }
        if (String.isNotBlank(booking.Purpose__c)) {
            html += '<tr><td><strong>Purpose:</strong></td><td>' + booking.Purpose__c + '</td></tr>';
        }
        html += '</table>';
        html += '<p>Please arrive on time for your booking.</p>';
        if (resourceType == 'Equipment') {
            html += '<p><strong>Important:</strong> Please remember to return the equipment after use.</p>';
        }
        html += '<p>Best regards,<br/>Dropillo Space & Asset Hub</p>';
        html += '</body></html>';
        return html;
    }
    
    /**
     * Build plain text body for booking confirmation email
     */
    private static String buildBookingConfirmationText(Booking__c booking, User bookingUser, String resourceName, String resourceType, String resourceDetails) {
        String text = 'BOOKING CONFIRMATION\n\n';
        text += 'Dear ' + bookingUser.Name + ',\n\n';
        text += 'Your booking has been confirmed. Here are the details:\n\n';
        text += 'Booking ID: ' + booking.Name + '\n';
        text += resourceType + ': ' + resourceName + '\n';
        text += 'Start: ' + booking.Start_DateTime__c.format() + '\n';
        text += 'End: ' + booking.End_DateTime__c.format() + '\n';
        if (String.isNotBlank(resourceDetails)) {
            text += 'Details: ' + resourceDetails + '\n';
        }
        if (String.isNotBlank(booking.Purpose__c)) {
            text += 'Purpose: ' + booking.Purpose__c + '\n';
        }
        text += '\nPlease arrive on time for your booking.\n';
        if (resourceType == 'Equipment') {
            text += '\nIMPORTANT: Please remember to return the equipment after use.\n';
        }
        text += '\nBest regards,\nDropillo Space & Asset Hub';
        return text;
    }
    
    /**
     * Build HTML body for start soon reminder email
     */
    private static String buildStartSoonReminderHtml(Booking__c booking, User bookingUser, String resourceName, String resourceType) {
        String html = '<html><body>';
        html += '<h2>Booking Reminder</h2>';
        html += '<p>Dear ' + bookingUser.Name + ',</p>';
        html += '<p>This is a reminder that your booking is starting soon:</p>';
        html += '<table border="1" style="border-collapse: collapse; margin: 20px 0;">';
        html += '<tr><td><strong>' + resourceType + ':</strong></td><td>' + resourceName + '</td></tr>';
        html += '<tr><td><strong>Start:</strong></td><td>' + booking.Start_DateTime__c.format() + '</td></tr>';
        html += '<tr><td><strong>End:</strong></td><td>' + booking.End_DateTime__c.format() + '</td></tr>';
        html += '</table>';
        html += '<p>Please make sure to be on time for your booking.</p>';
        html += '<p>Best regards,<br/>Dropillo Space & Asset Hub</p>';
        html += '</body></html>';
        return html;
    }
    
    /**
     * Build plain text body for start soon reminder email
     */
    private static String buildStartSoonReminderText(Booking__c booking, User bookingUser, String resourceName, String resourceType) {
        String text = 'BOOKING REMINDER\n\n';
        text += 'Dear ' + bookingUser.Name + ',\n\n';
        text += 'This is a reminder that your booking is starting soon:\n\n';
        text += resourceType + ': ' + resourceName + '\n';
        text += 'Start: ' + booking.Start_DateTime__c.format() + '\n';
        text += 'End: ' + booking.End_DateTime__c.format() + '\n';
        text += '\nPlease make sure to be on time for your booking.\n';
        text += '\nBest regards,\nDropillo Space & Asset Hub';
        return text;
    }
    
    /**
     * Build HTML body for equipment return reminder email
     */
    private static String buildEquipmentReturnReminderHtml(Booking__c booking, User bookingUser, String resourceName) {
        String html = '<html><body>';
        html += '<h2>Equipment Return Reminder</h2>';
        html += '<p>Dear ' + bookingUser.Name + ',</p>';
        html += '<p>This is a reminder to return the following equipment:</p>';
        html += '<table border="1" style="border-collapse: collapse; margin: 20px 0;">';
        html += '<tr><td><strong>Equipment:</strong></td><td>' + resourceName + '</td></tr>';
        html += '<tr><td><strong>Booking End:</strong></td><td>' + booking.End_DateTime__c.format() + '</td></tr>';
        html += '</table>';
        html += '<p>Please return the equipment as soon as possible to avoid affecting other bookings.</p>';
        html += '<p>Best regards,<br/>Dropillo Space & Asset Hub</p>';
        html += '</body></html>';
        return html;
    }
    
    /**
     * Build plain text body for equipment return reminder email
     */
    private static String buildEquipmentReturnReminderText(Booking__c booking, User bookingUser, String resourceName) {
        String text = 'EQUIPMENT RETURN REMINDER\n\n';
        text += 'Dear ' + bookingUser.Name + ',\n\n';
        text += 'This is a reminder to return the following equipment:\n\n';
        text += 'Equipment: ' + resourceName + '\n';
        text += 'Booking End: ' + booking.End_DateTime__c.format() + '\n';
        text += '\nPlease return the equipment as soon as possible to avoid affecting other bookings.\n';
        text += '\nBest regards,\nDropillo Space & Asset Hub';
        return text;
    }
    
    /**
     * Build HTML body for booking cancellation email
     */
    private static String buildBookingCancellationHtml(Booking__c booking, User bookingUser, String resourceName, String resourceType) {
        String html = '<html><body>';
        html += '<h2>Booking Cancelled</h2>';
        html += '<p>Dear ' + bookingUser.Name + ',</p>';
        html += '<p>Your booking has been cancelled:</p>';
        html += '<table border="1" style="border-collapse: collapse; margin: 20px 0;">';
        html += '<tr><td><strong>Booking ID:</strong></td><td>' + booking.Name + '</td></tr>';
        html += '<tr><td><strong>' + resourceType + ':</strong></td><td>' + resourceName + '</td></tr>';
        html += '<tr><td><strong>Original Start:</strong></td><td>' + booking.Start_DateTime__c.format() + '</td></tr>';
        html += '<tr><td><strong>Original End:</strong></td><td>' + booking.End_DateTime__c.format() + '</td></tr>';
        html += '</table>';
        html += '<p>If you need to book another time slot, please use the Dropillo Space & Asset Hub.</p>';
        html += '<p>Best regards,<br/>Dropillo Space & Asset Hub</p>';
        html += '</body></html>';
        return html;
    }
    
    /**
     * Build plain text body for booking cancellation email
     */
    private static String buildBookingCancellationText(Booking__c booking, User bookingUser, String resourceName, String resourceType) {
        String text = 'BOOKING CANCELLED\n\n';
        text += 'Dear ' + bookingUser.Name + ',\n\n';
        text += 'Your booking has been cancelled:\n\n';
        text += 'Booking ID: ' + booking.Name + '\n';
        text += resourceType + ': ' + resourceName + '\n';
        text += 'Original Start: ' + booking.Start_DateTime__c.format() + '\n';
        text += 'Original End: ' + booking.End_DateTime__c.format() + '\n';
        text += '\nIf you need to book another time slot, please use the Dropillo Space & Asset Hub.\n';
        text += '\nBest regards,\nDropillo Space & Asset Hub';
        return text;
    }
} 