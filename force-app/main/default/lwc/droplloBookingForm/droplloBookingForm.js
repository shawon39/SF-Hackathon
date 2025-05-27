import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import getAvailableRooms from '@salesforce/apex/DroplloBookingController.getAvailableRooms';
import getAvailableEquipment from '@salesforce/apex/DroplloBookingController.getAvailableEquipment';
import createBooking from '@salesforce/apex/DroplloBookingController.createBooking';
import getRoomTypes from '@salesforce/apex/DroplloBookingController.getRoomTypes';
import getEquipmentTypes from '@salesforce/apex/DroplloBookingController.getEquipmentTypes';
import getAllAmenities from '@salesforce/apex/DroplloCalendarController.getAllAmenities';

export default class DroplloBookingForm extends LightningElement {
    @track bookingType = 'Room';
    @track selectedResource = null;
    @track startDateTime = '';
    @track endDateTime = '';
    @track purpose = '';
    @track attendeeCount = 1;
    @track notes = '';
    @track showResults = false;
    @track isLoading = false;
    
    // Filter properties
    @track minCapacity = 1;
    @track selectedRoomType = '';
    @track selectedEquipmentType = '';
    @track selectedAmenities = [];
    
    // Data properties
    @track availableResources = [];
    @track roomTypes = [];
    @track equipmentTypes = [];
    @track amenities = [];
    
    // Modal properties
    @track showBookingModal = false;
    @track selectedResourceForBooking = null;
    
    userId = Id;
    
    get bookingTypeOptions() {
        return [
            { label: 'Room', value: 'Room' },
            { label: 'Equipment', value: 'Equipment' }
        ];
    }
    
    get capacityOptions() {
        return [
            { label: '1 person', value: 1 },
            { label: '2-4 people', value: 2 },
            { label: '5-8 people', value: 5 },
            { label: '9-16 people', value: 9 },
            { label: '17+ people', value: 17 }
        ];
    }
    
    get isRoomBooking() {
        return this.bookingType === 'Room';
    }
    
    get isEquipmentBooking() {
        return this.bookingType === 'Equipment';
    }
    
    get hasResults() {
        return this.availableResources && this.availableResources.length > 0;
    }
    
    get currentDateTime() {
        const now = new Date();
        now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
        return now.toISOString().slice(0, 16);
    }
    
    connectedCallback() {
        this.loadFilterOptions();
        this.setDefaultDateTime();
    }
    
    setDefaultDateTime() {
        const now = new Date();
        now.setHours(now.getHours() + 1, 0, 0, 0); // Next hour
        this.startDateTime = now.toISOString().slice(0, 16);
        
        now.setHours(now.getHours() + 1); // 2 hours from now
        this.endDateTime = now.toISOString().slice(0, 16);
    }
    
    async loadFilterOptions() {
        try {
            this.isLoading = true;
            
            // Load room types
            const roomTypesResult = await getRoomTypes();
            this.roomTypes = roomTypesResult.map(type => ({ label: type, value: type }));
            
            // Load equipment types
            const equipmentTypesResult = await getEquipmentTypes();
            this.equipmentTypes = equipmentTypesResult.map(type => ({ label: type, value: type }));
            
            // Load amenities
            const amenitiesResult = await getAllAmenities();
            this.amenities = amenitiesResult.map(amenity => ({ label: amenity, value: amenity }));
            
        } catch (error) {
            this.showToast('Error', 'Failed to load filter options: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    handleBookingTypeChange(event) {
        this.bookingType = event.detail.value;
        this.clearResults();
    }
    
    handleStartDateTimeChange(event) {
        this.startDateTime = event.target.value;
        this.validateDateTime();
    }
    
    handleEndDateTimeChange(event) {
        this.endDateTime = event.target.value;
        this.validateDateTime();
    }
    
    validateDateTime() {
        if (this.startDateTime && this.endDateTime) {
            const start = new Date(this.startDateTime);
            const end = new Date(this.endDateTime);
            
            if (start >= end) {
                this.showToast('Invalid Time', 'End time must be after start time', 'warning');
                return false;
            }
            
            if (start < new Date()) {
                this.showToast('Invalid Time', 'Cannot book in the past', 'warning');
                return false;
            }
        }
        return true;
    }
    
    handleCapacityChange(event) {
        this.minCapacity = parseInt(event.detail.value);
    }
    
    handleRoomTypeChange(event) {
        this.selectedRoomType = event.detail.value;
    }
    
    handleEquipmentTypeChange(event) {
        this.selectedEquipmentType = event.detail.value;
    }
    
    handleAmenitiesChange(event) {
        this.selectedAmenities = event.detail.value;
    }
    
    handlePurposeChange(event) {
        this.purpose = event.target.value;
    }
    
    handleAttendeeCountChange(event) {
        this.attendeeCount = parseInt(event.target.value);
    }
    
    handleNotesChange(event) {
        this.notes = event.target.value;
    }
    
    async handleSearch() {
        if (!this.validateDateTime() || !this.startDateTime || !this.endDateTime) {
            this.showToast('Missing Information', 'Please select start and end date/time', 'warning');
            return;
        }
        
        try {
            this.isLoading = true;
            this.clearResults();
            
            if (this.isRoomBooking) {
                await this.searchRooms();
            } else {
                await this.searchEquipment();
            }
            
            this.showResults = true;
            
        } catch (error) {
            this.showToast('Search Error', 'Failed to search: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    async searchRooms() {
        const result = await getAvailableRooms({
            startDateTime: this.startDateTime,
            endDateTime: this.endDateTime,
            minCapacity: this.minCapacity,
            roomType: this.selectedRoomType
        });
        
        // Filter by amenities if selected
        if (this.selectedAmenities.length > 0) {
            this.availableResources = result.filter(room => {
                return this.selectedAmenities.some(amenity => 
                    room.amenities && room.amenities.includes(amenity)
                );
            });
        } else {
            this.availableResources = result;
        }
    }
    
    async searchEquipment() {
        const result = await getAvailableEquipment({
            startDateTime: this.startDateTime,
            endDateTime: this.endDateTime,
            equipmentType: this.selectedEquipmentType
        });
        
        this.availableResources = result;
    }
    
    handleResourceSelect(event) {
        const resourceId = event.currentTarget.dataset.id;
        this.selectedResourceForBooking = this.availableResources.find(res => res.id === resourceId);
        this.showBookingModal = true;
    }
    
    handleCloseModal() {
        this.showBookingModal = false;
        this.selectedResourceForBooking = null;
    }
    
    async handleConfirmBooking() {
        if (!this.purpose.trim()) {
            this.showToast('Missing Information', 'Please enter a purpose for the booking', 'warning');
            return;
        }
        
        try {
            this.isLoading = true;
            
            const bookingData = {
                userId: this.userId,
                bookingType: this.bookingType,
                roomId: this.isRoomBooking ? this.selectedResourceForBooking.id : null,
                equipmentId: this.isEquipmentBooking ? this.selectedResourceForBooking.id : null,
                startDateTime: this.startDateTime,
                endDateTime: this.endDateTime,
                purpose: this.purpose,
                attendeeCount: this.attendeeCount,
                notes: this.notes
            };
            
            const result = await createBooking({ bookingData });
            
            if (result.isSuccess) {
                this.showToast('Success', 'Booking created successfully!', 'success');
                this.handleCloseModal();
                this.resetForm();
            } else {
                this.showToast('Booking Failed', result.errorMessage, 'error');
            }
            
        } catch (error) {
            this.showToast('Error', 'Failed to create booking: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    clearResults() {
        this.availableResources = [];
        this.showResults = false;
        this.selectedResource = null;
    }
    
    resetForm() {
        this.purpose = '';
        this.notes = '';
        this.attendeeCount = 1;
        this.clearResults();
        this.setDefaultDateTime();
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