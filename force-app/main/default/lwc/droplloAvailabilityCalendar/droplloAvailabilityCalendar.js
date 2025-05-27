import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRoomCalendarData from '@salesforce/apex/DroplloCalendarController.getRoomCalendarData';
import getEquipmentCalendarData from '@salesforce/apex/DroplloCalendarController.getEquipmentCalendarData';

export default class DroplloAvailabilityCalendar extends LightningElement {
    @track resourceType = 'Room';
    @track viewType = 'calendar';
    @track selectedDate = '';
    @track calendarData = null;
    @track isLoading = false;
    @track showModal = false;
    @track selectedBooking = null;
    
    // Filter properties
    @track selectedResources = [];
    @track filteredResources = [];
    
    get resourceTypeOptions() {
        return [
            { label: 'Rooms', value: 'Room' },
            { label: 'Equipment', value: 'Equipment' }
        ];
    }
    
    get viewTypeOptions() {
        return [
            { label: 'Calendar View', value: 'calendar' },
            { label: 'List View', value: 'list' }
        ];
    }
    
    get isRoomView() {
        return this.resourceType === 'Room';
    }
    
    get isEquipmentView() {
        return this.resourceType === 'Equipment';
    }
    
    get isCalendarView() {
        return this.viewType === 'calendar';
    }
    
    get isListView() {
        return this.viewType === 'list';
    }
    
    get hasCalendarData() {
        const hasData = this.calendarData && this.calendarData.resources && this.calendarData.resources.length > 0;
        console.log('hasCalendarData:', hasData, 'calendarData:', this.calendarData);
        return hasData;
    }
    
    get displayResources() {
        const resources = this.filteredResources.length > 0 ? this.filteredResources : (this.calendarData?.resources || []);
        console.log('displayResources:', resources.length, 'resources:', resources);
        return resources;
    }
    
    get todayDate() {
        return new Date().toISOString().slice(0, 10);
    }
    
    get selectedDateFormatted() {
        if (!this.selectedDate) return '';
        try {
            return new Date(this.selectedDate).toLocaleDateString([], { 
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
        } catch (error) {
            return this.selectedDate;
        }
    }
    
    connectedCallback() {
        this.setDefaultDate();
        this.loadCalendarData();
        
        // Set up auto-refresh interval
        this.refreshInterval = setInterval(() => {
            if (!this.isLoading) {
                this.loadCalendarData();
            }
        }, 300000); // 5 minutes
    }
    
    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }
    
    setDefaultDate() {
        this.selectedDate = this.todayDate;
    }
    
    handleResourceTypeChange(event) {
        this.resourceType = event.detail.value;
        this.loadCalendarData();
    }
    
    handleViewTypeChange(event) {
        this.viewType = event.detail.value;
    }
    
    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.loadCalendarData();
    }
    
    handleRefresh() {
        this.loadCalendarData();
    }
    
    async loadCalendarData() {
        if (!this.selectedDate) return;
        
        try {
            this.isLoading = true;
            
            const startDate = this.selectedDate;
            const endDate = this.selectedDate; // Single day view
            
            let result;
            
            if (this.resourceType === 'Room') {
                result = await getRoomCalendarData({
                    startDate: startDate,
                    endDate: endDate,
                    roomIds: this.selectedResources
                });
            } else {
                result = await getEquipmentCalendarData({
                    startDate: startDate,
                    endDate: endDate,
                    equipmentIds: this.selectedResources
                });
            }
            
            if (result.isSuccess) {
                this.calendarData = result;
                // Process the resources data to add computed properties
                this.filteredResources = this.processResourcesData(result.resources || []);
                console.log('Processed calendar data:', this.filteredResources);
            } else {
                this.showToast('Error', result.errorMessage || 'Failed to load calendar data', 'error');
                this.calendarData = null;
                this.filteredResources = [];
            }
            
        } catch (error) {
            console.error('Calendar data error:', error);
            this.showToast('Error', 'Failed to load calendar data: ' + (error.body?.message || error.message), 'error');
            this.calendarData = null;
            this.filteredResources = [];
        } finally {
            this.isLoading = false;
        }
    }
    
    processResourcesData(resources) {
        return resources.map(resource => {
            // Process bookings to add display properties
            const processedBookings = (resource.bookings || []).map(booking => {
                return {
                    ...booking,
                    startTime: this.formatTime(booking.startDateTime),
                    endTime: this.formatTime(booking.endDateTime),
                    statusVariant: this.getBookingStatusVariant(booking.status)
                };
            });
            
            // Sort bookings by start time
            processedBookings.sort((a, b) => new Date(a.startDateTime) - new Date(b.startDateTime));
            
            // Find current and next bookings
            const now = new Date();
            const currentBooking = processedBookings.find(booking => {
                const start = new Date(booking.startDateTime);
                const end = new Date(booking.endDateTime);
                return start <= now && end > now && booking.status !== 'Cancelled';
            });
            
            const nextBooking = processedBookings.find(booking => {
                const start = new Date(booking.startDateTime);
                return start > now && booking.status !== 'Cancelled';
            });
            
            // Create processed resource with updated bookings
            const processedResource = {
                ...resource,
                bookings: processedBookings,
                currentBooking: currentBooking,
                nextBooking: nextBooking
            };
            
            // Calculate availability status and variant using processed data
            const availabilityStatus = this.calculateAvailabilityStatus(processedResource);
            const availabilityVariant = this.calculateAvailabilityVariant(availabilityStatus);
            
            return {
                ...processedResource,
                availabilityStatus: availabilityStatus,
                availabilityVariant: availabilityVariant
            };
        });
    }
    
    calculateAvailabilityStatus(resource) {
        if (!resource.bookings || resource.bookings.length === 0) {
            return 'Available';
        }
        
        const now = new Date();
        
        // Check if there's a current booking
        if (resource.currentBooking) {
            return 'In Use';
        }
        
        // Find next booking today
        const nextBooking = resource.bookings.find(booking => {
            const start = new Date(booking.startDateTime);
            const bookingDate = start.toDateString();
            const todayDate = now.toDateString();
            return start > now && bookingDate === todayDate && booking.status !== 'Cancelled';
        });
        
        if (nextBooking) {
            const start = new Date(nextBooking.startDateTime);
            const minutesUntil = Math.round((start - now) / (1000 * 60));
            
            if (minutesUntil < 60) {
                return `Next in ${minutesUntil}m`;
            } else {
                const hoursUntil = Math.round(minutesUntil / 60);
                return `Next in ${hoursUntil}h`;
            }
        }
        
        return 'Available';
    }
    
    calculateAvailabilityVariant(status) {
        if (status === 'Available') return 'success';
        if (status === 'In Use') return 'error';
        return 'warning';
    }
    
    handleBookingClick(event) {
        const bookingId = event.currentTarget.dataset.bookingId;
        const resourceId = event.currentTarget.dataset.resourceId;
        
        // Find the booking details from processed data
        if (this.filteredResources && this.filteredResources.length > 0) {
            for (const resource of this.filteredResources) {
                if (resource.id === resourceId) {
                    const booking = resource.bookings.find(b => b.id === bookingId);
                    if (booking) {
                        this.selectedBooking = {
                            ...booking,
                            resourceName: resource.name,
                            resourceType: this.resourceType,
                            statusVariant: this.getBookingStatusVariant(booking.status)
                        };
                        this.showModal = true;
                        break;
                    }
                }
            }
        }
    }
    
    handleCloseModal() {
        this.showModal = false;
        this.selectedBooking = null;
    }
    
    getBookingStatusVariant(status) {
        switch (status) {
            case 'Confirmed':
                return 'success';
            case 'In_Use':
                return 'warning';
            case 'Completed':
                return 'inverse';
            case 'Cancelled':
                return 'error';
            default:
                return 'neutral';
        }
    }
    
    formatDateTime(dateTimeString) {
        if (!dateTimeString) return '';
        try {
            const date = new Date(dateTimeString);
            return date.toLocaleString([], { 
                year: 'numeric',
                month: 'short', 
                day: 'numeric',
                hour: '2-digit', 
                minute: '2-digit',
                hour12: true
            });
        } catch (error) {
            console.error('Error formatting datetime:', error);
            return dateTimeString;
        }
    }
    
    formatTime(dateTimeString) {
        if (!dateTimeString) return '';
        try {
            const date = new Date(dateTimeString);
            return date.toLocaleTimeString([], { 
                hour: '2-digit', 
                minute: '2-digit',
                hour12: true 
            });
        } catch (error) {
            console.error('Error formatting time:', error);
            return dateTimeString;
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