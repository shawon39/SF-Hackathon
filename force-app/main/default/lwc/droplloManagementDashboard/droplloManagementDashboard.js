import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import getRoomUsageReport from '@salesforce/apex/DroplloReportController.getRoomUsageReport';
import getEquipmentUsageReport from '@salesforce/apex/DroplloReportController.getEquipmentUsageReport';
import getDailyUsageSummary from '@salesforce/apex/DroplloReportController.getDailyUsageSummary';
import getUserActivityReport from '@salesforce/apex/DroplloReportController.getUserActivityReport';
import getRoomUtilizationChartData from '@salesforce/apex/DroplloReportController.getRoomUtilizationChartData';
import getEquipmentUsageChartData from '@salesforce/apex/DroplloReportController.getEquipmentUsageChartData';
import getBookingTrends from '@salesforce/apex/DroplloReportController.getBookingTrends';

export default class DroplloManagementDashboard extends LightningElement {
    @track selectedDateRange = '7';
    @track selectedTab = 'overview';
    @track isLoading = false;
    @track isChartLoaded = false;
    
    // Data properties
    @track dailySummary = null;
    @track roomUsageReport = null;
    @track equipmentUsageReport = null;
    @track userActivityReport = null;
    @track bookingTrends = [];
    
    // Chart instances
    roomUtilizationChart;
    equipmentUsageChart;
    trendsChart;
    
    get dateRangeOptions() {
        return [
            { label: 'Last 7 days', value: '7' },
            { label: 'Last 30 days', value: '30' },
            { label: 'Last 90 days', value: '90' }
        ];
    }
    
    get tabOptions() {
        return [
            { label: 'Overview', value: 'overview' },
            { label: 'Room Analytics', value: 'rooms' },
            { label: 'Equipment Analytics', value: 'equipment' },
            { label: 'User Activity', value: 'users' }
        ];
    }
    
    get isOverviewTab() {
        return this.selectedTab === 'overview';
    }
    
    get isRoomsTab() {
        return this.selectedTab === 'rooms';
    }
    
    get isEquipmentTab() {
        return this.selectedTab === 'equipment';
    }
    
    get isUsersTab() {
        return this.selectedTab === 'users';
    }
    
    get startDate() {
        const today = new Date();
        const days = parseInt(this.selectedDateRange);
        const startDate = new Date(today.getTime() - (days * 24 * 60 * 60 * 1000));
        return startDate.toISOString().slice(0, 10);
    }
    
    get endDate() {
        return new Date().toISOString().slice(0, 10);
    }
    
    get totalBookingsToday() {
        return this.safeGet(this.dailySummary, 'totalBookings', 0);
    }
    
    get roomBookingsToday() {
        return this.safeGet(this.dailySummary, 'roomBookings', 0);
    }
    
    get equipmentBookingsToday() {
        return this.safeGet(this.dailySummary, 'equipmentBookings', 0);
    }
    
    get overdueReturns() {
        return this.safeGet(this.dailySummary, 'overdueReturns', 0);
    }
    
    get mostPopularRoom() {
        return this.safeGet(this.dailySummary, 'mostPopularRoom', 'No data available');
    }
    
    get mostPopularEquipment() {
        return this.safeGet(this.dailySummary, 'mostPopularEquipment', 'No data available');
    }
    
    get averageRoomUtilization() {
        const utilization = this.safeGet(this.roomUsageReport, 'averageUtilization', 0);
        return Math.round(utilization) + '%';
    }
    
    get topRooms() {
        if (!this.roomUsageReport || !this.roomUsageReport.roomStats) return [];
        return this.roomUsageReport.roomStats
            .sort((a, b) => b.utilizationPercentage - a.utilizationPercentage)
            .slice(0, 5);
    }
    
    get topEquipment() {
        if (!this.equipmentUsageReport || !this.equipmentUsageReport.equipmentStats) return [];
        return this.equipmentUsageReport.equipmentStats
            .sort((a, b) => b.totalBookings - a.totalBookings)
            .slice(0, 5);
    }
    
    get topUsers() {
        if (!this.userActivityReport || !this.userActivityReport.userStats) return [];
        return this.userActivityReport.userStats
            .sort((a, b) => b.totalBookings - a.totalBookings)
            .slice(0, 10);
    }
    
    get hasRoomData() {
        return this.roomUsageReport && this.roomUsageReport.roomStats && this.roomUsageReport.roomStats.length > 0;
    }
    
    get hasEquipmentData() {
        return this.equipmentUsageReport && this.equipmentUsageReport.equipmentStats && this.equipmentUsageReport.equipmentStats.length > 0;
    }
    
    get hasUserData() {
        return this.userActivityReport && this.userActivityReport.userStats && this.userActivityReport.userStats.length > 0;
    }
    
    get totalRoomsCount() {
        return this.safeGet(this.roomUsageReport, 'totalRooms', 0);
    }
    
    get totalEquipmentCount() {
        return this.safeGet(this.equipmentUsageReport, 'totalEquipment', 0);
    }
    
    get totalUsersCount() {
        return this.safeGet(this.userActivityReport, 'totalUsers', 0);
    }
    
    get bookingTrendsTable() {
        if (!this.bookingTrends || this.bookingTrends.length === 0) return [];
        
        // Return last 7 days of trend data for table display
        return this.bookingTrends
            .sort((a, b) => new Date(a.dateLabel) - new Date(b.dateLabel))
            .slice(-7)
            .map(trend => ({
                ...trend,
                formattedDate: new Date(trend.dateLabel).toLocaleDateString()
            }));
    }
    
    get overdueEquipmentAlert() {
        const overdueCount = this.overdueReturns;
        if (overdueCount > 0) {
            return {
                show: true,
                variant: overdueCount > 5 ? 'error' : 'warning',
                message: `${overdueCount} equipment item${overdueCount > 1 ? 's' : ''} overdue for return`
            };
        }
        return { show: false };
    }
    
    connectedCallback() {
        this.loadDashboardData();
        // Optional: Try to load Chart.js if available
        this.tryLoadChartLibrary();
    }
    
    async tryLoadChartLibrary() {
        try {
            // This will only work if Chart.js static resource is uploaded
            // For now, we'll skip chart functionality
            console.log('Chart.js library not available - dashboard will work without charts');
            this.isChartLoaded = false;
        } catch (error) {
            console.log('Chart.js library not found - dashboard will work without charts');
            this.isChartLoaded = false;
        }
    }
    
    handleDateRangeChange(event) {
        this.selectedDateRange = event.detail.value;
        this.loadDashboardData();
    }
    
    handleTabChange(event) {
        this.selectedTab = event.detail.value;
        // Load tab-specific data and charts
        setTimeout(() => {
            this.initializeTabCharts();
        }, 100);
    }
    
    handleRefresh() {
        this.loadDashboardData();
    }
    
    async loadDashboardData() {
        try {
            this.isLoading = true;
            
            // Load all dashboard data
            await Promise.all([
                this.loadDailySummary(),
                this.loadRoomUsageReport(),
                this.loadEquipmentUsageReport(),
                this.loadUserActivityReport(),
                this.loadBookingTrends()
            ]);
            
            // Initialize charts after data is loaded (if Chart.js is available)
            if (this.isChartLoaded) {
                setTimeout(() => {
                    this.initializeCharts();
                }, 100);
            }
            
        } catch (error) {
            this.showToast('Error', 'Failed to load dashboard data: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    async loadDailySummary() {
        try {
            const result = await getDailyUsageSummary({ targetDate: this.endDate });
            if (result.isSuccess) {
                this.dailySummary = result;
            }
        } catch (error) {
            console.error('Error loading daily summary:', error);
        }
    }
    
    async loadRoomUsageReport() {
        try {
            const result = await getRoomUsageReport({ 
                startDate: this.startDate,
                endDate: this.endDate
            });
            if (result.isSuccess) {
                this.roomUsageReport = result;
            }
        } catch (error) {
            console.error('Error loading room usage report:', error);
        }
    }
    
    async loadEquipmentUsageReport() {
        try {
            const result = await getEquipmentUsageReport({ 
                startDate: this.startDate,
                endDate: this.endDate
            });
            if (result.isSuccess) {
                this.equipmentUsageReport = result;
            }
        } catch (error) {
            console.error('Error loading equipment usage report:', error);
        }
    }
    
    async loadUserActivityReport() {
        try {
            const result = await getUserActivityReport({ 
                startDate: this.startDate,
                endDate: this.endDate
            });
            if (result.isSuccess) {
                this.userActivityReport = result;
            }
        } catch (error) {
            console.error('Error loading user activity report:', error);
        }
    }
    
    async loadBookingTrends() {
        try {
            const result = await getBookingTrends();
            this.bookingTrends = result || [];
        } catch (error) {
            console.error('Error loading booking trends:', error);
        }
    }
    
    initializeCharts() {
        if (this.isOverviewTab) {
            this.createTrendsChart();
        }
        this.initializeTabCharts();
    }
    
    initializeTabCharts() {
        if (this.isRoomsTab) {
            this.createRoomUtilizationChart();
        } else if (this.isEquipmentTab) {
            this.createEquipmentUsageChart();
        }
    }
    
    createTrendsChart() {
        // Chart functionality disabled until Chart.js is available
        console.log('Chart functionality requires Chart.js static resource');
    }
    
    async createRoomUtilizationChart() {
        // Chart functionality disabled until Chart.js is available
        console.log('Chart functionality requires Chart.js static resource');
    }
    
    async createEquipmentUsageChart() {
        // Chart functionality disabled until Chart.js is available
        console.log('Chart functionality requires Chart.js static resource');
    }
    
    formatNumber(num) {
        return num ? num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") : '0';
    }
    
    formatPercentage(num) {
        return num ? Math.round(num) + '%' : '0%';
    }
    
    safeGet(obj, path, defaultValue = 0) {
        return path.split('.').reduce((current, key) => {
            return current && current[key] !== undefined ? current[key] : defaultValue;
        }, obj);
    }
    
    formatDuration(hours) {
        if (!hours) return '0h';
        if (hours < 1) {
            return `${Math.round(hours * 60)}m`;
        }
        return `${Math.round(hours * 10) / 10}h`;
    }
    
    exportDashboardData() {
        try {
            const dashboardData = {
                exportDate: new Date().toISOString(),
                dateRange: `${this.startDate} to ${this.endDate}`,
                dailySummary: this.dailySummary,
                roomUsage: this.roomUsageReport,
                equipmentUsage: this.equipmentUsageReport,
                userActivity: this.userActivityReport,
                bookingTrends: this.bookingTrends
            };
            
            const dataStr = JSON.stringify(dashboardData, null, 2);
            const dataBlob = new Blob([dataStr], { type: 'application/json' });
            
            // Create download link
            const url = window.URL.createObjectURL(dataBlob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `dropillo-dashboard-${new Date().toISOString().slice(0, 10)}.json`;
            link.click();
            
            this.showToast('Success', 'Dashboard data exported successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to export data: ' + error.message, 'error');
        }
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
} 