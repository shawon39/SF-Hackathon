/**
 * Report Service for generating usage analytics and management reports
 * Provides data for dashboards and automated reporting
 * 
 * Features:
 * - Room and equipment usage statistics
 * - Daily/weekly/monthly usage reports
 * - Occupancy analytics
 * - User activity reports
 * - Equipment return tracking
 * 
 * @version 1.0
 * @author Dropillo Team
 */
public class DroplloReportService {
    
    /**
     * Get room usage statistics for a date range
     * @param startDate Start date for the report
     * @param endDate End date for the report
     * @return RoomUsageReport containing usage statistics
     */
    public static RoomUsageReport getRoomUsageReport(Date startDate, Date endDate) {
        RoomUsageReport report = new RoomUsageReport();
        report.startDate = startDate;
        report.endDate = endDate;
        
        try {
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            // Get all rooms
            List<Room__c> allRooms = [
                SELECT Id, Name, Room_Type__c, Capacity__c, Floor__c
                FROM Room__c 
                WHERE Is_Active__c = true
                ORDER BY Room_Type__c, Name
            ];
            
            // Get bookings for the date range
            List<Booking__c> bookings = [
                SELECT Id, Room__c, Start_DateTime__c, End_DateTime__c, Status__c, Attendee_Count__c,
                       Room__r.Name, Room__r.Room_Type__c
                FROM Booking__c 
                WHERE Room__c != null
                AND Status__c IN ('Confirmed', 'In_Use', 'Completed')
                AND Start_DateTime__c >= :startDateTime
                AND End_DateTime__c <= :endDateTime
                ORDER BY Room__c, Start_DateTime__c
            ];
            
            // Calculate usage statistics
            report.roomStats = new List<RoomStat>();
            Map<Id, List<Booking__c>> roomBookingsMap = new Map<Id, List<Booking__c>>();
            
            // Group bookings by room
            for (Booking__c booking : bookings) {
                if (!roomBookingsMap.containsKey(booking.Room__c)) {
                    roomBookingsMap.put(booking.Room__c, new List<Booking__c>());
                }
                roomBookingsMap.get(booking.Room__c).add(booking);
            }
            
            // Calculate stats for each room
            for (Room__c room : allRooms) {
                RoomStat stat = new RoomStat();
                stat.roomId = room.Id;
                stat.roomName = room.Name;
                stat.roomType = room.Room_Type__c;
                stat.capacity = room.Capacity__c != null ? Integer.valueOf(room.Capacity__c) : 0;
                stat.floor = room.Floor__c;
                
                List<Booking__c> roomBookings = roomBookingsMap.get(room.Id);
                if (roomBookings != null && !roomBookings.isEmpty()) {
                    stat.totalBookings = roomBookings.size();
                    stat.totalHoursBooked = 0;
                    stat.totalAttendees = 0;
                    
                    for (Booking__c booking : roomBookings) {
                        // Calculate hours
                        Long milliseconds = booking.End_DateTime__c.getTime() - booking.Start_DateTime__c.getTime();
                        Decimal hours = milliseconds / (1000.0 * 60 * 60);
                        stat.totalHoursBooked += hours;
                        
                        // Add attendees
                        if (booking.Attendee_Count__c != null) {
                            stat.totalAttendees += Integer.valueOf(booking.Attendee_Count__c);
                        }
                    }
                    
                    stat.averageAttendees = stat.totalBookings > 0 ? stat.totalAttendees / stat.totalBookings : 0;
                    stat.averageBookingDuration = stat.totalBookings > 0 ? stat.totalHoursBooked / stat.totalBookings : 0;
                } else {
                    stat.totalBookings = 0;
                    stat.totalHoursBooked = 0;
                    stat.totalAttendees = 0;
                    stat.averageAttendees = 0;
                    stat.averageBookingDuration = 0;
                }
                
                // Calculate utilization percentage (assuming 8 AM to 8 PM = 12 hours/day)
                Integer daysBetween = startDate.daysBetween(endDate) + 1;
                Decimal availableHours = daysBetween * 12; // 12 hours per day
                stat.utilizationPercentage = availableHours > 0 ? (stat.totalHoursBooked / availableHours) * 100 : 0;
                
                report.roomStats.add(stat);
            }
            
            // Calculate summary statistics
            report.totalRooms = allRooms.size();
            report.totalBookings = bookings.size();
            report.totalHoursBooked = 0;
            report.totalAttendees = 0;
            
            for (RoomStat stat : report.roomStats) {
                report.totalHoursBooked += stat.totalHoursBooked;
                report.totalAttendees += stat.totalAttendees;
            }
            
            report.averageUtilization = 0;
            if (!report.roomStats.isEmpty()) {
                Decimal totalUtilization = 0;
                for (RoomStat stat : report.roomStats) {
                    totalUtilization += stat.utilizationPercentage;
                }
                report.averageUtilization = totalUtilization / report.roomStats.size();
            }
            
            report.isSuccess = true;
            
        } catch (Exception e) {
            report.isSuccess = false;
            report.errorMessage = 'Failed to generate room usage report: ' + e.getMessage();
            System.debug('Report service error: ' + e.getMessage());
        }
        
        return report;
    }
    
    /**
     * Get equipment usage statistics for a date range
     * @param startDate Start date for the report
     * @param endDate End date for the report
     * @return EquipmentUsageReport containing usage statistics
     */
    public static EquipmentUsageReport getEquipmentUsageReport(Date startDate, Date endDate) {
        EquipmentUsageReport report = new EquipmentUsageReport();
        report.startDate = startDate;
        report.endDate = endDate;
        
        try {
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            // Get all equipment
            List<Equipment__c> allEquipment = [
                SELECT Id, Name, Equipment_Type__c, Serial_Number__c, Current_Location__c
                FROM Equipment__c 
                WHERE Is_Active__c = true
                ORDER BY Equipment_Type__c, Name
            ];
            
            // Get bookings for the date range
            List<Booking__c> bookings = [
                SELECT Id, Equipment__c, Start_DateTime__c, End_DateTime__c, Status__c, Return_Status__c,
                       Equipment__r.Name, Equipment__r.Equipment_Type__c
                FROM Booking__c 
                WHERE Equipment__c != null
                AND Status__c IN ('Confirmed', 'In_Use', 'Completed')
                AND Start_DateTime__c >= :startDateTime
                AND End_DateTime__c <= :endDateTime
                ORDER BY Equipment__c, Start_DateTime__c
            ];
            
            // Calculate usage statistics
            report.equipmentStats = new List<EquipmentStat>();
            Map<Id, List<Booking__c>> equipmentBookingsMap = new Map<Id, List<Booking__c>>();
            
            // Group bookings by equipment
            for (Booking__c booking : bookings) {
                if (!equipmentBookingsMap.containsKey(booking.Equipment__c)) {
                    equipmentBookingsMap.put(booking.Equipment__c, new List<Booking__c>());
                }
                equipmentBookingsMap.get(booking.Equipment__c).add(booking);
            }
            
            // Calculate stats for each equipment
            for (Equipment__c equipment : allEquipment) {
                EquipmentStat stat = new EquipmentStat();
                stat.equipmentId = equipment.Id;
                stat.equipmentName = equipment.Name;
                stat.equipmentType = equipment.Equipment_Type__c;
                stat.serialNumber = equipment.Serial_Number__c;
                stat.currentLocation = equipment.Current_Location__c;
                
                List<Booking__c> equipmentBookings = equipmentBookingsMap.get(equipment.Id);
                if (equipmentBookings != null && !equipmentBookings.isEmpty()) {
                    stat.totalBookings = equipmentBookings.size();
                    stat.totalHoursBooked = 0;
                    stat.overdueReturns = 0;
                    
                    for (Booking__c booking : equipmentBookings) {
                        // Calculate hours
                        Long milliseconds = booking.End_DateTime__c.getTime() - booking.Start_DateTime__c.getTime();
                        Decimal hours = milliseconds / (1000.0 * 60 * 60);
                        stat.totalHoursBooked += hours;
                        
                        // Check for overdue returns
                        if (booking.Return_Status__c == 'Overdue' || 
                           (booking.Return_Status__c == 'Not_Returned' && booking.End_DateTime__c < DateTime.now())) {
                            stat.overdueReturns++;
                        }
                    }
                    
                    stat.averageBookingDuration = stat.totalBookings > 0 ? stat.totalHoursBooked / stat.totalBookings : 0;
                } else {
                    stat.totalBookings = 0;
                    stat.totalHoursBooked = 0;
                    stat.overdueReturns = 0;
                    stat.averageBookingDuration = 0;
                }
                
                report.equipmentStats.add(stat);
            }
            
            // Calculate summary statistics
            report.totalEquipment = allEquipment.size();
            report.totalBookings = bookings.size();
            report.totalHoursBooked = 0;
            report.totalOverdueReturns = 0;
            
            for (EquipmentStat stat : report.equipmentStats) {
                report.totalHoursBooked += stat.totalHoursBooked;
                report.totalOverdueReturns += stat.overdueReturns;
            }
            
            report.isSuccess = true;
            
        } catch (Exception e) {
            report.isSuccess = false;
            report.errorMessage = 'Failed to generate equipment usage report: ' + e.getMessage();
            System.debug('Report service error: ' + e.getMessage());
        }
        
        return report;
    }
    
    /**
     * Get daily usage summary for management emails
     * @param targetDate Date for the summary
     * @return DailyUsageSummary containing daily statistics
     */
    public static DailyUsageSummary getDailyUsageSummary(Date targetDate) {
        DailyUsageSummary summary = new DailyUsageSummary();
        summary.reportDate = targetDate;
        
        try {
            DateTime dayStart = DateTime.newInstance(targetDate, Time.newInstance(0, 0, 0, 0));
            DateTime dayEnd = DateTime.newInstance(targetDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            // Get today's bookings
            List<Booking__c> todaysBookings = [
                SELECT Id, Booking_Type__c, Status__c, Start_DateTime__c, End_DateTime__c, Return_Status__c,
                       Room__r.Name, Equipment__r.Name
                FROM Booking__c 
                WHERE Start_DateTime__c >= :dayStart
                AND Start_DateTime__c < :dayEnd
                ORDER BY Start_DateTime__c
            ];
            
            // Calculate statistics
            summary.totalBookings = todaysBookings.size();
            summary.roomBookings = 0;
            summary.equipmentBookings = 0;
            summary.confirmedBookings = 0;
            summary.completedBookings = 0;
            summary.cancelledBookings = 0;
            summary.overdueReturns = 0;
            
            for (Booking__c booking : todaysBookings) {
                if (booking.Booking_Type__c == 'Room') {
                    summary.roomBookings++;
                } else if (booking.Booking_Type__c == 'Equipment') {
                    summary.equipmentBookings++;
                    
                    // Check for overdue returns
                    if (booking.Return_Status__c == 'Overdue' || 
                       (booking.Return_Status__c == 'Not_Returned' && booking.End_DateTime__c < DateTime.now())) {
                        summary.overdueReturns++;
                    }
                }
                
                if (booking.Status__c == 'Confirmed') {
                    summary.confirmedBookings++;
                } else if (booking.Status__c == 'Completed') {
                    summary.completedBookings++;
                } else if (booking.Status__c == 'Cancelled') {
                    summary.cancelledBookings++;
                }
            }
            
            // Get most popular resources
            summary.mostPopularRoom = getMostPopularRoom(targetDate);
            summary.mostPopularEquipment = getMostPopularEquipment(targetDate);
            
            summary.isSuccess = true;
            
        } catch (Exception e) {
            summary.isSuccess = false;
            summary.errorMessage = 'Failed to generate daily usage summary: ' + e.getMessage();
            System.debug('Daily summary error: ' + e.getMessage());
        }
        
        return summary;
    }
    
    /**
     * Get user activity report for a date range
     * @param startDate Start date for the report
     * @param endDate End date for the report
     * @return UserActivityReport containing user statistics
     */
    public static UserActivityReport getUserActivityReport(Date startDate, Date endDate) {
        UserActivityReport report = new UserActivityReport();
        report.startDate = startDate;
        report.endDate = endDate;
        
        try {
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            // Get bookings grouped by user
            List<AggregateResult> userBookings = [
                SELECT Booking_User__c, Booking_User__r.Name, Booking_Type__c, COUNT(Id) totalBookings
                FROM Booking__c 
                WHERE Start_DateTime__c >= :startDateTime
                AND Start_DateTime__c < :endDateTime
                AND Status__c != 'Cancelled'
                GROUP BY Booking_User__c, Booking_User__r.Name, Booking_Type__c
                ORDER BY COUNT(Id) DESC
            ];
            
            // Process user statistics
            Map<Id, UserStat> userStatsMap = new Map<Id, UserStat>();
            
            for (AggregateResult result : userBookings) {
                Id userId = (Id) result.get('Booking_User__c');
                String userName = (String) result.get('Name');
                String bookingType = (String) result.get('Booking_Type__c');
                Integer totalBookings = (Integer) result.get('totalBookings');
                
                if (!userStatsMap.containsKey(userId)) {
                    UserStat userStat = new UserStat();
                    userStat.userId = userId;
                    userStat.userName = userName;
                    userStat.totalBookings = 0;
                    userStat.roomBookings = 0;
                    userStat.equipmentBookings = 0;
                    userStatsMap.put(userId, userStat);
                }
                
                UserStat userStat = userStatsMap.get(userId);
                userStat.totalBookings += totalBookings;
                
                if (bookingType == 'Room') {
                    userStat.roomBookings += totalBookings;
                } else if (bookingType == 'Equipment') {
                    userStat.equipmentBookings += totalBookings;
                }
            }
            
            report.userStats = userStatsMap.values();
            report.totalUsers = userStatsMap.size();
            report.isSuccess = true;
            
        } catch (Exception e) {
            report.isSuccess = false;
            report.errorMessage = 'Failed to generate user activity report: ' + e.getMessage();
            System.debug('User activity report error: ' + e.getMessage());
        }
        
        return report;
    }
    
    /**
     * Send daily usage summary email to management
     * @param targetDate Date for the summary
     * @param recipientEmails List of email addresses to send to
     * @return Boolean true if email sent successfully
     */
    public static Boolean sendDailyUsageSummaryEmail(Date targetDate, List<String> recipientEmails) {
        try {
            DailyUsageSummary summary = getDailyUsageSummary(targetDate);
            
            if (!summary.isSuccess) {
                System.debug('Failed to generate daily summary for email: ' + summary.errorMessage);
                return false;
            }
            
            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(recipientEmails);
            email.setSubject('Dropillo Daily Usage Summary - ' + targetDate.format());
            
            String htmlBody = buildDailySummaryEmailHtml(summary);
            email.setHtmlBody(htmlBody);
            
            String plainTextBody = buildDailySummaryEmailText(summary);
            email.setPlainTextBody(plainTextBody);
            
            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            System.debug('Daily usage summary email sent successfully');
            return true;
            
        } catch (Exception e) {
            System.debug('Failed to send daily usage summary email: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Get most popular room for a date
     */
    private static String getMostPopularRoom(Date targetDate) {
        try {
            DateTime dayStart = DateTime.newInstance(targetDate, Time.newInstance(0, 0, 0, 0));
            DateTime dayEnd = DateTime.newInstance(targetDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            List<AggregateResult> results = [
                SELECT Room__r.Name, COUNT(Id) bookingCount
                FROM Booking__c 
                WHERE Room__c != null
                AND Start_DateTime__c >= :dayStart
                AND Start_DateTime__c < :dayEnd
                AND Status__c != 'Cancelled'
                GROUP BY Room__r.Name
                ORDER BY COUNT(Id) DESC
                LIMIT 1
            ];
            
            if (!results.isEmpty()) {
                return (String) results[0].get('Name');
            }
        } catch (Exception e) {
            System.debug('Error getting most popular room: ' + e.getMessage());
        }
        
        return 'N/A';
    }
    
    /**
     * Get most popular equipment for a date
     */
    private static String getMostPopularEquipment(Date targetDate) {
        try {
            DateTime dayStart = DateTime.newInstance(targetDate, Time.newInstance(0, 0, 0, 0));
            DateTime dayEnd = DateTime.newInstance(targetDate.addDays(1), Time.newInstance(0, 0, 0, 0));
            
            List<AggregateResult> results = [
                SELECT Equipment__r.Name, COUNT(Id) bookingCount
                FROM Booking__c 
                WHERE Equipment__c != null
                AND Start_DateTime__c >= :dayStart
                AND Start_DateTime__c < :dayEnd
                AND Status__c != 'Cancelled'
                GROUP BY Equipment__r.Name
                ORDER BY COUNT(Id) DESC
                LIMIT 1
            ];
            
            if (!results.isEmpty()) {
                return (String) results[0].get('Name');
            }
        } catch (Exception e) {
            System.debug('Error getting most popular equipment: ' + e.getMessage());
        }
        
        return 'N/A';
    }
    
    /**
     * Build HTML body for daily summary email
     */
    private static String buildDailySummaryEmailHtml(DailyUsageSummary summary) {
        String html = '<html><body>';
        html += '<h1>Dropillo Daily Usage Summary</h1>';
        html += '<h2>Date: ' + summary.reportDate.format() + '</h2>';
        
        html += '<h3>Overview</h3>';
        html += '<table border="1" style="border-collapse: collapse; margin: 20px 0;">';
        html += '<tr><td><strong>Total Bookings:</strong></td><td>' + summary.totalBookings + '</td></tr>';
        html += '<tr><td><strong>Room Bookings:</strong></td><td>' + summary.roomBookings + '</td></tr>';
        html += '<tr><td><strong>Equipment Bookings:</strong></td><td>' + summary.equipmentBookings + '</td></tr>';
        html += '<tr><td><strong>Confirmed Bookings:</strong></td><td>' + summary.confirmedBookings + '</td></tr>';
        html += '<tr><td><strong>Completed Bookings:</strong></td><td>' + summary.completedBookings + '</td></tr>';
        html += '<tr><td><strong>Cancelled Bookings:</strong></td><td>' + summary.cancelledBookings + '</td></tr>';
        html += '<tr><td><strong>Overdue Returns:</strong></td><td>' + summary.overdueReturns + '</td></tr>';
        html += '</table>';
        
        html += '<h3>Popular Resources</h3>';
        html += '<table border="1" style="border-collapse: collapse; margin: 20px 0;">';
        html += '<tr><td><strong>Most Popular Room:</strong></td><td>' + summary.mostPopularRoom + '</td></tr>';
        html += '<tr><td><strong>Most Popular Equipment:</strong></td><td>' + summary.mostPopularEquipment + '</td></tr>';
        html += '</table>';
        
        html += '<p><em>Generated automatically by Dropillo Space & Asset Hub</em></p>';
        html += '</body></html>';
        
        return html;
    }
    
    /**
     * Build plain text body for daily summary email
     */
    private static String buildDailySummaryEmailText(DailyUsageSummary summary) {
        String text = 'DROPILLO DAILY USAGE SUMMARY\n';
        text += 'Date: ' + summary.reportDate.format() + '\n\n';
        
        text += 'OVERVIEW\n';
        text += 'Total Bookings: ' + summary.totalBookings + '\n';
        text += 'Room Bookings: ' + summary.roomBookings + '\n';
        text += 'Equipment Bookings: ' + summary.equipmentBookings + '\n';
        text += 'Confirmed Bookings: ' + summary.confirmedBookings + '\n';
        text += 'Completed Bookings: ' + summary.completedBookings + '\n';
        text += 'Cancelled Bookings: ' + summary.cancelledBookings + '\n';
        text += 'Overdue Returns: ' + summary.overdueReturns + '\n\n';
        
        text += 'POPULAR RESOURCES\n';
        text += 'Most Popular Room: ' + summary.mostPopularRoom + '\n';
        text += 'Most Popular Equipment: ' + summary.mostPopularEquipment + '\n\n';
        
        text += 'Generated automatically by Dropillo Space & Asset Hub';
        
        return text;
    }
    
    // Inner classes for report data structures
    
    /**
     * Room usage report wrapper
     */
    public class RoomUsageReport {
        public Boolean isSuccess = false;
        public String errorMessage;
        public Date startDate;
        public Date endDate;
        public Integer totalRooms;
        public Integer totalBookings;
        public Decimal totalHoursBooked;
        public Integer totalAttendees;
        public Decimal averageUtilization;
        public List<RoomStat> roomStats;
    }
    
    /**
     * Equipment usage report wrapper
     */
    public class EquipmentUsageReport {
        public Boolean isSuccess = false;
        public String errorMessage;
        public Date startDate;
        public Date endDate;
        public Integer totalEquipment;
        public Integer totalBookings;
        public Decimal totalHoursBooked;
        public Integer totalOverdueReturns;
        public List<EquipmentStat> equipmentStats;
    }
    
    /**
     * Daily usage summary wrapper
     */
    public class DailyUsageSummary {
        public Boolean isSuccess = false;
        public String errorMessage;
        public Date reportDate;
        public Integer totalBookings;
        public Integer roomBookings;
        public Integer equipmentBookings;
        public Integer confirmedBookings;
        public Integer completedBookings;
        public Integer cancelledBookings;
        public Integer overdueReturns;
        public String mostPopularRoom;
        public String mostPopularEquipment;
    }
    
    /**
     * User activity report wrapper
     */
    public class UserActivityReport {
        public Boolean isSuccess = false;
        public String errorMessage;
        public Date startDate;
        public Date endDate;
        public Integer totalUsers;
        public List<UserStat> userStats;
    }
    
    /**
     * Room statistics
     */
    public class RoomStat {
        public Id roomId;
        public String roomName;
        public String roomType;
        public Integer capacity;
        public String floor;
        public Integer totalBookings;
        public Decimal totalHoursBooked;
        public Integer totalAttendees;
        public Integer averageAttendees;
        public Decimal averageBookingDuration;
        public Decimal utilizationPercentage;
    }
    
    /**
     * Equipment statistics
     */
    public class EquipmentStat {
        public Id equipmentId;
        public String equipmentName;
        public String equipmentType;
        public String serialNumber;
        public String currentLocation;
        public Integer totalBookings;
        public Decimal totalHoursBooked;
        public Decimal averageBookingDuration;
        public Integer overdueReturns;
    }
    
    /**
     * User statistics
     */
    public class UserStat {
        public Id userId;
        public String userName;
        public Integer totalBookings;
        public Integer roomBookings;
        public Integer equipmentBookings;
    }
} 