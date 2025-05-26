import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getAvailableRooms from '@salesforce/apex/BookingController.getAvailableRooms';
import getAvailableEquipment from '@salesforce/apex/BookingController.getAvailableEquipment';
import createBooking from '@salesforce/apex/BookingController.createBooking';
import getUserBookings from '@salesforce/apex/BookingController.getUserBookings';
import cancelBooking from '@salesforce/apex/BookingController.cancelBooking';
import getEquipmentTypes from '@salesforce/apex/BookingController.getEquipmentTypes';
import debugGetUserBookings from '@salesforce/apex/BookingController.debugGetUserBookings';

export default class DroplloBookingHub extends LightningElement {
    
    // Tab management
    @track activeTab = 'rooms';
    
    // Room search properties
    @track roomStartTime = '';
    @track roomEndTime = '';
    @track roomCapacity = '';
    @track roomAmenities = '';
    @track availableRooms = [];
    @track isSearchingRooms = false;
    
    // Equipment search properties
    @track equipmentStartTime = '';
    @track equipmentEndTime = '';
    @track equipmentType = '';
    @track availableEquipment = [];
    @track isSearchingEquipment = false;
    @track equipmentTypeOptions = [];
    
    // User bookings
    @track userBookings = [];
    @track isLoadingBookings = false;
    
    // Modal properties
    @track showBookingModal = false;
    @track modalTitle = '';
    @track modalStartTime = '';
    @track modalEndTime = '';
    @track modalPurpose = '';
    @track modalAttendeeCount = 1;
    @track isCreatingBooking = false;
    @track selectedResourceId = '';
    @track selectedResourceType = '';
    
    // Wire results for refresh
    userBookingsWireResult;
    equipmentTypesWireResult;
    
    // Load equipment types on component initialization
    @wire(getEquipmentTypes)
    wiredEquipmentTypes(result) {
        this.equipmentTypesWireResult = result;
        if (result.data) {
            this.equipmentTypeOptions = [
                { label: 'All Types', value: '' },
                ...result.data.map(type => ({ label: type, value: type }))
            ];
        } else if (result.error) {
            this.showToast('Error', 'Failed to load equipment types', 'error');
        }
    }
    
    // Load all user bookings
    @wire(getUserBookings)
    wiredUserBookings(result) {
        this.userBookingsWireResult = result;
        console.log('Wire result:', result);
        
        if (result.data) {
            console.log('Bookings data received:', result.data);
            console.log('Number of bookings:', result.data.length);
            
            this.userBookings = result.data.map(booking => ({
                ...booking,
                iconName: booking.bookingType === 'Room' ? 'utility:home' : 'utility:connected_apps',
                statusVariant: this.getStatusVariant(booking.status),
                isCancelDisabled: booking.status === 'Cancelled' || booking.status === 'Completed' || this.isPastBooking(booking.endDateTime),
                formattedStartTime: this.formatDateTime(booking.startDateTime),
                formattedEndTime: this.formatDateTime(booking.endDateTime),
                isExpired: this.isPastBooking(booking.endDateTime),
                cardClass: this.getBookingCardClass(booking.status, booking.endDateTime)
            }));
            
            console.log('Processed bookings:', this.userBookings);
        } else if (result.error) {
            console.error('Wire error:', result.error);
            this.showToast('Error', 'Failed to load bookings: ' + result.error.body?.message, 'error');
        } else {
            console.log('No data and no error - still loading?');
        }
    }
    
    // Initialize component
    connectedCallback() {
        this.setDefaultTimes();
        this.loadUserBookings();
    }
    
    // Set default start and end times
    setDefaultTimes() {
        const now = new Date();
        const startTime = new Date(now.getTime() + 60 * 60 * 1000); // 1 hour from now
        const endTime = new Date(startTime.getTime() + 60 * 60 * 1000); // 1 hour duration
        
        this.roomStartTime = this.formatDateTimeInput(startTime);
        this.roomEndTime = this.formatDateTimeInput(endTime);
        this.equipmentStartTime = this.formatDateTimeInput(startTime);
        this.equipmentEndTime = this.formatDateTimeInput(endTime);
    }
    
    // Tab management
    get isRoomsTabActive() {
        return this.activeTab === 'rooms';
    }
    
    get isEquipmentTabActive() {
        return this.activeTab === 'equipment';
    }
    
    get isMyBookingsTabActive() {
        return this.activeTab === 'mybookings';
    }
    
    get hasRooms() {
        return this.availableRooms && this.availableRooms.length > 0;
    }
    
    get hasEquipment() {
        return this.availableEquipment && this.availableEquipment.length > 0;
    }
    
    get hasBookings() {
        return this.userBookings && this.userBookings.length > 0;
    }
    
    get isRoomBooking() {
        return this.selectedResourceType === 'Room';
    }
    
    // Handle tab change
    handleTabChange(event) {
        event.preventDefault();
        const selectedTab = event.target.dataset.tab;
        this.activeTab = selectedTab;
        
        if (selectedTab === 'mybookings') {
            this.loadUserBookings();
            this.debugBookings(); // Add debug call
        }
    }
    
    // Handle room filter changes
    handleRoomFilterChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        
        if (field === 'roomStartTime') {
            this.roomStartTime = value;
        } else if (field === 'roomEndTime') {
            this.roomEndTime = value;
        } else if (field === 'capacity') {
            this.roomCapacity = value;
        } else if (field === 'amenities') {
            this.roomAmenities = value;
        }
    }
    
    // Handle equipment filter changes
    handleEquipmentFilterChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        
        if (field === 'equipmentStartTime') {
            this.equipmentStartTime = value;
        } else if (field === 'equipmentEndTime') {
            this.equipmentEndTime = value;
        } else if (field === 'equipmentType') {
            this.equipmentType = value;
        }
    }
    
    // Search rooms
    async searchRooms() {
        if (!this.roomStartTime || !this.roomEndTime) {
            this.showToast('Error', 'Please select start and end times', 'error');
            return;
        }
        
        this.isSearchingRooms = true;
        try {
            const result = await getAvailableRooms({
                startDateTime: this.roomStartTime,
                endDateTime: this.roomEndTime,
                capacity: this.roomCapacity ? parseInt(this.roomCapacity) : null,
                amenities: this.roomAmenities
            });
            
            this.availableRooms = result.map(room => ({
                ...room,
                cardClass: room.isAvailable ? 'slds-card' : 'slds-card slds-card_disabled',
                availabilityLabel: room.isAvailable ? 'Available' : 'Unavailable',
                availabilityVariant: room.isAvailable ? 'success' : 'error',
                isDisabled: !room.isAvailable
            }));
            
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to search rooms', 'error');
        } finally {
            this.isSearchingRooms = false;
        }
    }
    
    // Search equipment
    async searchEquipment() {
        if (!this.equipmentStartTime || !this.equipmentEndTime) {
            this.showToast('Error', 'Please select start and end times', 'error');
            return;
        }
        
        this.isSearchingEquipment = true;
        try {
            const result = await getAvailableEquipment({
                startDateTime: this.equipmentStartTime,
                endDateTime: this.equipmentEndTime,
                equipmentType: this.equipmentType
            });
            
            this.availableEquipment = result.map(equipment => ({
                ...equipment,
                cardClass: equipment.isAvailable ? 'slds-card' : 'slds-card slds-card_disabled',
                availabilityLabel: equipment.isAvailable ? 'Available' : 'Unavailable',
                availabilityVariant: equipment.isAvailable ? 'success' : 'error',
                isDisabled: !equipment.isAvailable
            }));
            
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to search equipment', 'error');
        } finally {
            this.isSearchingEquipment = false;
        }
    }
    
    // Handle room booking
    handleBookRoom(event) {
        const roomId = event.target.dataset.roomId;
        const room = this.availableRooms.find(r => r.roomId === roomId);
        
        if (room && room.isAvailable) {
            this.selectedResourceId = roomId;
            this.selectedResourceType = 'Room';
            this.modalTitle = `Book ${room.name}`;
            this.modalStartTime = this.roomStartTime;
            this.modalEndTime = this.roomEndTime;
            this.showBookingModal = true;
        }
    }
    
    // Handle equipment booking
    handleBookEquipment(event) {
        const equipmentId = event.target.dataset.equipmentId;
        const equipment = this.availableEquipment.find(e => e.equipmentId === equipmentId);
        
        if (equipment && equipment.isAvailable) {
            this.selectedResourceId = equipmentId;
            this.selectedResourceType = 'Equipment';
            this.modalTitle = `Book ${equipment.name}`;
            this.modalStartTime = this.equipmentStartTime;
            this.modalEndTime = this.equipmentEndTime;
            this.showBookingModal = true;
        }
    }
    
    // Handle modal field changes
    handleModalFieldChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        
        if (field === 'startDateTime') {
            this.modalStartTime = value;
        } else if (field === 'endDateTime') {
            this.modalEndTime = value;
        } else if (field === 'purpose') {
            this.modalPurpose = value;
        } else if (field === 'attendeeCount') {
            this.modalAttendeeCount = value;
        }
    }
    
    // Create booking
    async createBooking() {
        if (!this.modalStartTime || !this.modalEndTime) {
            this.showToast('Error', 'Please select start and end times', 'error');
            return;
        }
        
        this.isCreatingBooking = true;
        try {
            const result = await createBooking({
                bookingType: this.selectedResourceType,
                resourceId: this.selectedResourceId,
                startDateTime: this.modalStartTime,
                endDateTime: this.modalEndTime,
                purpose: this.modalPurpose,
                attendeeCount: this.modalAttendeeCount ? parseInt(this.modalAttendeeCount) : null
            });
            
            if (result.isSuccess) {
                this.showToast('Success', result.message, 'success');
                this.closeBookingModal();
                this.refreshBookings();
                
                // Refresh the search results
                if (this.selectedResourceType === 'Room') {
                    this.searchRooms();
                } else {
                    this.searchEquipment();
                }
            } else {
                this.showToast('Error', result.message, 'error');
            }
            
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to create booking', 'error');
        } finally {
            this.isCreatingBooking = false;
        }
    }
    
    // Cancel booking
    async handleCancelBooking(event) {
        const bookingId = event.target.dataset.bookingId;
        
        try {
            const result = await cancelBooking({ bookingId: bookingId });
            
            if (result.isSuccess) {
                this.showToast('Success', result.message, 'success');
                this.refreshBookings();
            } else {
                this.showToast('Error', result.message, 'error');
            }
            
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to cancel booking', 'error');
        }
    }
    
    // Close booking modal
    closeBookingModal() {
        this.showBookingModal = false;
        this.modalTitle = '';
        this.modalStartTime = '';
        this.modalEndTime = '';
        this.modalPurpose = '';
        this.modalAttendeeCount = 1;
        this.selectedResourceId = '';
        this.selectedResourceType = '';
    }
    
    // Load user bookings
    loadUserBookings() {
        this.isLoadingBookings = true;
        // Refresh the wire service
        refreshApex(this.userBookingsWireResult).finally(() => {
            this.isLoadingBookings = false;
        });
    }
    
    // Refresh bookings
    refreshBookings() {
        refreshApex(this.userBookingsWireResult);
    }
    
    // Utility methods
    formatDateTime(dateTime) {
        if (!dateTime) return '';
        const date = new Date(dateTime);
        return date.toLocaleString('en-US', {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    
    formatDateTimeInput(date) {
        return date.toISOString().slice(0, 16);
    }
    
    getStatusVariant(status) {
        switch (status) {
            case 'Confirmed':
                return 'success';
            case 'Pending':
                return 'warning';
            case 'In_Use':
                return 'brand';
            case 'Completed':
                return 'inverse';
            case 'Cancelled':
                return 'error';
            default:
                return 'inverse';
        }
    }
    
    // Check if booking is in the past
    isPastBooking(endDateTime) {
        if (!endDateTime) return false;
        return new Date(endDateTime) < new Date();
    }
    
    // Get card styling based on booking status and timing
    getBookingCardClass(status, endDateTime) {
        let baseClass = 'slds-card';
        
        if (status === 'Cancelled') {
            return baseClass + ' slds-card_disabled';
        }
        
        if (this.isPastBooking(endDateTime)) {
            return baseClass + ' slds-card_expired';
        }
        
        return baseClass;
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Debug method to check booking data
    async debugBookings() {
        try {
            const debugInfo = await debugGetUserBookings();
            console.log('Debug Bookings Info:', debugInfo);
            this.showToast('Debug Info', debugInfo, 'info');
        } catch (error) {
            console.error('Debug error:', error);
            this.showToast('Debug Error', error.body?.message || 'Debug failed', 'error');
        }
    }
}