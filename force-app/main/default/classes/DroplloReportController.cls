/**
 * Lightning Web Component Controller for Dropillo Report Services
 * Exposes reporting and analytics functionality to LWC components
 * 
 * @version 1.0
 * @author Dropillo Team
 */
public with sharing class DroplloReportController {
    
    /**
     * Get room usage report for date range
     * @param startDate Start date for report
     * @param endDate End date for report
     * @return Room usage statistics
     */
    @AuraEnabled(cacheable=true)
    public static RoomUsageReportWrapper getRoomUsageReport(String startDate, String endDate) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            DroplloReportService.RoomUsageReport report = DroplloReportService.getRoomUsageReport(startDt, endDt);
            
            RoomUsageReportWrapper wrapper = new RoomUsageReportWrapper();
            wrapper.isSuccess = report.isSuccess;
            wrapper.errorMessage = report.errorMessage;
            wrapper.startDate = startDate;
            wrapper.endDate = endDate;
            wrapper.totalRooms = report.totalRooms;
            wrapper.totalBookings = report.totalBookings;
            wrapper.totalHoursBooked = report.totalHoursBooked;
            wrapper.totalAttendees = report.totalAttendees;
            wrapper.averageUtilization = report.averageUtilization;
            wrapper.roomStats = new List<RoomStatWrapper>();
            
            if (report.roomStats != null) {
                for (DroplloReportService.RoomStat stat : report.roomStats) {
                    RoomStatWrapper statWrapper = new RoomStatWrapper();
                    statWrapper.roomId = stat.roomId;
                    statWrapper.roomName = stat.roomName;
                    statWrapper.roomType = stat.roomType;
                    statWrapper.capacity = stat.capacity;
                    statWrapper.floor = stat.floor;
                    statWrapper.totalBookings = stat.totalBookings;
                    statWrapper.totalHoursBooked = stat.totalHoursBooked;
                    statWrapper.totalAttendees = stat.totalAttendees;
                    statWrapper.averageAttendees = stat.averageAttendees;
                    statWrapper.averageBookingDuration = stat.averageBookingDuration;
                    statWrapper.utilizationPercentage = stat.utilizationPercentage;
                    
                    wrapper.roomStats.add(statWrapper);
                }
            }
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting room usage report: ' + e.getMessage());
        }
    }
    
    /**
     * Get equipment usage report for date range
     * @param startDate Start date for report
     * @param endDate End date for report
     * @return Equipment usage statistics
     */
    @AuraEnabled(cacheable=true)
    public static EquipmentUsageReportWrapper getEquipmentUsageReport(String startDate, String endDate) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            DroplloReportService.EquipmentUsageReport report = DroplloReportService.getEquipmentUsageReport(startDt, endDt);
            
            EquipmentUsageReportWrapper wrapper = new EquipmentUsageReportWrapper();
            wrapper.isSuccess = report.isSuccess;
            wrapper.errorMessage = report.errorMessage;
            wrapper.startDate = startDate;
            wrapper.endDate = endDate;
            wrapper.totalEquipment = report.totalEquipment;
            wrapper.totalBookings = report.totalBookings;
            wrapper.totalHoursBooked = report.totalHoursBooked;
            wrapper.totalOverdueReturns = report.totalOverdueReturns;
            wrapper.equipmentStats = new List<EquipmentStatWrapper>();
            
            if (report.equipmentStats != null) {
                for (DroplloReportService.EquipmentStat stat : report.equipmentStats) {
                    EquipmentStatWrapper statWrapper = new EquipmentStatWrapper();
                    statWrapper.equipmentId = stat.equipmentId;
                    statWrapper.equipmentName = stat.equipmentName;
                    statWrapper.equipmentType = stat.equipmentType;
                    statWrapper.serialNumber = stat.serialNumber;
                    statWrapper.currentLocation = stat.currentLocation;
                    statWrapper.totalBookings = stat.totalBookings;
                    statWrapper.totalHoursBooked = stat.totalHoursBooked;
                    statWrapper.averageBookingDuration = stat.averageBookingDuration;
                    statWrapper.overdueReturns = stat.overdueReturns;
                    
                    wrapper.equipmentStats.add(statWrapper);
                }
            }
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting equipment usage report: ' + e.getMessage());
        }
    }
    
    /**
     * Get daily usage summary
     * @param targetDate Date for summary
     * @return Daily usage statistics
     */
    @AuraEnabled(cacheable=true)
    public static DailyUsageSummaryWrapper getDailyUsageSummary(String targetDate) {
        try {
            Date targetDt = Date.valueOf(targetDate);
            
            DroplloReportService.DailyUsageSummary summary = DroplloReportService.getDailyUsageSummary(targetDt);
            
            DailyUsageSummaryWrapper wrapper = new DailyUsageSummaryWrapper();
            wrapper.isSuccess = summary.isSuccess;
            wrapper.errorMessage = summary.errorMessage;
            wrapper.reportDate = targetDate;
            wrapper.totalBookings = summary.totalBookings;
            wrapper.roomBookings = summary.roomBookings;
            wrapper.equipmentBookings = summary.equipmentBookings;
            wrapper.confirmedBookings = summary.confirmedBookings;
            wrapper.completedBookings = summary.completedBookings;
            wrapper.cancelledBookings = summary.cancelledBookings;
            wrapper.overdueReturns = summary.overdueReturns;
            wrapper.mostPopularRoom = summary.mostPopularRoom;
            wrapper.mostPopularEquipment = summary.mostPopularEquipment;
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting daily usage summary: ' + e.getMessage());
        }
    }
    
    /**
     * Get user activity report for date range
     * @param startDate Start date for report
     * @param endDate End date for report
     * @return User activity statistics
     */
    @AuraEnabled(cacheable=true)
    public static UserActivityReportWrapper getUserActivityReport(String startDate, String endDate) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            DroplloReportService.UserActivityReport report = DroplloReportService.getUserActivityReport(startDt, endDt);
            
            UserActivityReportWrapper wrapper = new UserActivityReportWrapper();
            wrapper.isSuccess = report.isSuccess;
            wrapper.errorMessage = report.errorMessage;
            wrapper.startDate = startDate;
            wrapper.endDate = endDate;
            wrapper.totalUsers = report.totalUsers;
            wrapper.userStats = new List<UserStatWrapper>();
            
            if (report.userStats != null) {
                for (DroplloReportService.UserStat stat : report.userStats) {
                    UserStatWrapper statWrapper = new UserStatWrapper();
                    statWrapper.userId = stat.userId;
                    statWrapper.userName = stat.userName;
                    statWrapper.totalBookings = stat.totalBookings;
                    statWrapper.roomBookings = stat.roomBookings;
                    statWrapper.equipmentBookings = stat.equipmentBookings;
                    
                    wrapper.userStats.add(statWrapper);
                }
            }
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting user activity report: ' + e.getMessage());
        }
    }
    
    /**
     * Get chart data for room utilization
     * @param startDate Start date for chart data
     * @param endDate End date for chart data
     * @return Chart data for room utilization
     */
    @AuraEnabled(cacheable=true)
    public static List<ChartDataWrapper> getRoomUtilizationChartData(String startDate, String endDate) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            DroplloReportService.RoomUsageReport report = DroplloReportService.getRoomUsageReport(startDt, endDt);
            
            List<ChartDataWrapper> chartData = new List<ChartDataWrapper>();
            
            if (report.roomStats != null) {
                for (DroplloReportService.RoomStat stat : report.roomStats) {
                    ChartDataWrapper dataPoint = new ChartDataWrapper();
                    dataPoint.label = stat.roomName;
                    dataPoint.value = stat.utilizationPercentage;
                    dataPoint.category = stat.roomType;
                    
                    chartData.add(dataPoint);
                }
            }
            
            return chartData;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting room utilization chart data: ' + e.getMessage());
        }
    }
    
    /**
     * Get chart data for equipment usage
     * @param startDate Start date for chart data
     * @param endDate End date for chart data
     * @return Chart data for equipment usage
     */
    @AuraEnabled(cacheable=true)
    public static List<ChartDataWrapper> getEquipmentUsageChartData(String startDate, String endDate) {
        try {
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            DroplloReportService.EquipmentUsageReport report = DroplloReportService.getEquipmentUsageReport(startDt, endDt);
            
            List<ChartDataWrapper> chartData = new List<ChartDataWrapper>();
            
            if (report.equipmentStats != null) {
                for (DroplloReportService.EquipmentStat stat : report.equipmentStats) {
                    ChartDataWrapper dataPoint = new ChartDataWrapper();
                    dataPoint.label = stat.equipmentName;
                    dataPoint.value = stat.totalBookings;
                    dataPoint.category = stat.equipmentType;
                    
                    chartData.add(dataPoint);
                }
            }
            
            return chartData;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting equipment usage chart data: ' + e.getMessage());
        }
    }
    
    /**
     * Get booking trends data for past 30 days
     * @return Booking trends chart data
     */
    @AuraEnabled(cacheable=true)
    public static List<TrendDataWrapper> getBookingTrends() {
        try {
            List<TrendDataWrapper> trendData = new List<TrendDataWrapper>();
            Date endDate = Date.today();
            Date startDate = endDate.addDays(-30);
            
            // Get daily booking counts for the past 30 days
            List<AggregateResult> dailyBookings = [
                SELECT DAY_ONLY(Start_DateTime__c) bookingDate, Booking_Type__c, COUNT(Id) bookingCount
                FROM Booking__c 
                WHERE Start_DateTime__c >= :DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0))
                AND Start_DateTime__c < :DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0))
                AND Status__c != 'Cancelled'
                GROUP BY DAY_ONLY(Start_DateTime__c), Booking_Type__c
                ORDER BY DAY_ONLY(Start_DateTime__c)
            ];
            
            Map<String, TrendDataWrapper> dateMap = new Map<String, TrendDataWrapper>();
            
            for (AggregateResult result : dailyBookings) {
                Date bookingDate = (Date) result.get('bookingDate');
                String bookingType = (String) result.get('Booking_Type__c');
                Integer bookingCount = (Integer) result.get('bookingCount');
                
                String dateKey = bookingDate.format();
                
                if (!dateMap.containsKey(dateKey)) {
                    TrendDataWrapper wrapper = new TrendDataWrapper();
                    wrapper.dateLabel = dateKey;
                    wrapper.roomBookings = 0;
                    wrapper.equipmentBookings = 0;
                    wrapper.totalBookings = 0;
                    dateMap.put(dateKey, wrapper);
                }
                
                TrendDataWrapper wrapper = dateMap.get(dateKey);
                
                if (bookingType == 'Room') {
                    wrapper.roomBookings = bookingCount;
                } else if (bookingType == 'Equipment') {
                    wrapper.equipmentBookings = bookingCount;
                }
                
                wrapper.totalBookings = wrapper.roomBookings + wrapper.equipmentBookings;
            }
            
            trendData.addAll(dateMap.values());
            
            return trendData;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting booking trends: ' + e.getMessage());
        }
    }
    
    // Wrapper classes for LWC data transfer
    
    public class RoomUsageReportWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public Integer totalRooms;
        @AuraEnabled public Integer totalBookings;
        @AuraEnabled public Decimal totalHoursBooked;
        @AuraEnabled public Integer totalAttendees;
        @AuraEnabled public Decimal averageUtilization;
        @AuraEnabled public List<RoomStatWrapper> roomStats;
    }
    
    public class EquipmentUsageReportWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public Integer totalEquipment;
        @AuraEnabled public Integer totalBookings;
        @AuraEnabled public Decimal totalHoursBooked;
        @AuraEnabled public Integer totalOverdueReturns;
        @AuraEnabled public List<EquipmentStatWrapper> equipmentStats;
    }
    
    public class DailyUsageSummaryWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String reportDate;
        @AuraEnabled public Integer totalBookings;
        @AuraEnabled public Integer roomBookings;
        @AuraEnabled public Integer equipmentBookings;
        @AuraEnabled public Integer confirmedBookings;
        @AuraEnabled public Integer completedBookings;
        @AuraEnabled public Integer cancelledBookings;
        @AuraEnabled public Integer overdueReturns;
        @AuraEnabled public String mostPopularRoom;
        @AuraEnabled public String mostPopularEquipment;
    }
    
    public class UserActivityReportWrapper {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public Integer totalUsers;
        @AuraEnabled public List<UserStatWrapper> userStats;
    }
    
    public class RoomStatWrapper {
        @AuraEnabled public String roomId;
        @AuraEnabled public String roomName;
        @AuraEnabled public String roomType;
        @AuraEnabled public Integer capacity;
        @AuraEnabled public String floor;
        @AuraEnabled public Integer totalBookings;
        @AuraEnabled public Decimal totalHoursBooked;
        @AuraEnabled public Integer totalAttendees;
        @AuraEnabled public Integer averageAttendees;
        @AuraEnabled public Decimal averageBookingDuration;
        @AuraEnabled public Decimal utilizationPercentage;
    }
    
    public class EquipmentStatWrapper {
        @AuraEnabled public String equipmentId;
        @AuraEnabled public String equipmentName;
        @AuraEnabled public String equipmentType;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String currentLocation;
        @AuraEnabled public Integer totalBookings;
        @AuraEnabled public Decimal totalHoursBooked;
        @AuraEnabled public Decimal averageBookingDuration;
        @AuraEnabled public Integer overdueReturns;
    }
    
    public class UserStatWrapper {
        @AuraEnabled public String userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Integer totalBookings;
        @AuraEnabled public Integer roomBookings;
        @AuraEnabled public Integer equipmentBookings;
    }
    
    public class ChartDataWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public Decimal value;
        @AuraEnabled public String category;
    }
    
    public class TrendDataWrapper {
        @AuraEnabled public String dateLabel;
        @AuraEnabled public Integer roomBookings;
        @AuraEnabled public Integer equipmentBookings;
        @AuraEnabled public Integer totalBookings;
    }
} 