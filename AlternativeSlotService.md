# AlternativeSlotService Feature Guide

## Overview
The `AlternativeSlotService` is a bonus feature that enhances user experience by suggesting alternative time slots when a user's preferred booking slot is unavailable. This service is particularly useful in room booking scenarios where popular time slots might already be booked.

## How It Works

1. **Core Functionality**: When a user tries to book a room at a time that's already taken, the service suggests up to 3 alternative time slots (by default) that:
   - Have the same duration as the requested slot
   - Fall within business hours (9 AM to 6 PM)
   - Are on weekdays only (no weekends)
   - Don't conflict with existing bookings
   - Are in the near future (within the next 7 days)

2. **Key Method**: 
   ```apex
   AlternativeSlotService.suggestAlternativeRoomSlots(
       String roomId, 
       String preferredStart, 
       String preferredEnd, 
       Integer numberOfSuggestions
   )
   ```

3. **Parameters**:
   - `roomId`: The ID of the room to book
   - `preferredStart`: The preferred start time in format 'yyyy-MM-dd HH:mm:ss' or 'yyyy-MM-ddTHH:mm:ss'
   - `preferredEnd`: The preferred end time in same format
   - `numberOfSuggestions`: Number of alternative slots to suggest (defaults to 3 if null or <= 0)

4. **Return Value**:
   - Returns a list of `TimeSlotSuggestion` objects containing:
     - `startDateTime`: The suggested start time
     - `endDateTime`: The suggested end time
     - `formattedStart`: Formatted start time string
     - `formattedEnd`: Formatted end time string
     - `dayOfWeek`: Day of the week (e.g., "Monday")
     - `isToday`: Boolean indicating if slot is today
     - `isTomorrow`: Boolean indicating if slot is tomorrow

## Testing in LWC

To implement and test this feature in your Lightning Web Component:

1. **Create an LWC to handle room booking:**

```javascript
// roomBooking.js
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import suggestAlternativeRoomSlots from '@salesforce/apex/AlternativeSlotService.suggestAlternativeRoomSlots';

export default class RoomBooking extends LightningElement {
    @track selectedRoomId;
    @track startDateTime;
    @track endDateTime;
    @track showAlternatives = false;
    @track alternativeSlots = [];
    
    // Handle room selection
    handleRoomChange(event) {
        this.selectedRoomId = event.detail.value;
    }
    
    // Handle start time selection
    handleStartChange(event) {
        this.startDateTime = event.target.value;
    }
    
    // Handle end time selection
    handleEndChange(event) {
        this.endDateTime = event.target.value;
    }
    
    // Attempt to book the room
    attemptBooking() {
        // First attempt regular booking (not shown)
        // If booking fails due to conflict, call getAlternativeSlots()
        this.getAlternativeSlots();
    }
    
    // Get alternative slot suggestions
    getAlternativeSlots() {
        if (!this.selectedRoomId || !this.startDateTime || !this.endDateTime) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }
        
        suggestAlternativeRoomSlots({
            roomId: this.selectedRoomId,
            preferredStart: this.startDateTime,
            preferredEnd: this.endDateTime,
            numberOfSuggestions: 3
        })
        .then(result => {
            if (result && result.length > 0) {
                this.alternativeSlots = result;
                this.showAlternatives = true;
            } else {
                this.showToast('No Alternatives', 'No alternative slots available in the next 7 days', 'info');
            }
        })
        .catch(error => {
            this.showToast('Error', 'Error getting alternative slots: ' + error.body.message, 'error');
        });
    }
    
    // Select an alternative slot
    selectAlternativeSlot(event) {
        const index = event.currentTarget.dataset.index;
        const selected = this.alternativeSlots[index];
        
        // Update the form with the selected slot
        this.startDateTime = selected.formattedStart;
        this.endDateTime = selected.formattedEnd;
        this.showAlternatives = false;
        
        this.showToast('Slot Selected', 'Alternative slot selected. Proceed with booking.', 'success');
    }
    
    // Show toast notification
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
```

2. **Create the HTML template:**

```html
<!-- roomBooking.html -->
<template>
    <lightning-card title="Room Booking" icon-name="standard:event">
        <div class="slds-p-around_medium">
            <!-- Room Selection -->
            <lightning-combobox
                label="Select Room"
                value={selectedRoomId}
                onchange={handleRoomChange}
                options={roomOptions}
                placeholder="Choose a room"
            ></lightning-combobox>
            
            <!-- Date/Time Selection -->
            <div class="slds-grid slds-gutters slds-p-top_small">
                <div class="slds-col">
                    <lightning-input 
                        type="datetime"
                        label="Start Date/Time"
                        value={startDateTime}
                        onchange={handleStartChange}
                    ></lightning-input>
                </div>
                <div class="slds-col">
                    <lightning-input 
                        type="datetime"
                        label="End Date/Time"
                        value={endDateTime}
                        onchange={handleEndChange}
                    ></lightning-input>
                </div>
            </div>
            
            <!-- Book Button -->
            <div class="slds-p-top_medium">
                <lightning-button 
                    label="Book Room"
                    variant="brand"
                    onclick={attemptBooking}
                ></lightning-button>
            </div>
            
            <!-- Alternative Slots -->
            <template if:true={showAlternatives}>
                <div class="slds-p-top_medium">
                    <div class="slds-text-heading_small slds-p-bottom_small">
                        Alternative Time Slots Available:
                    </div>
                    <template for:each={alternativeSlots} for:item="slot" for:index="index">
                        <div key={slot.formattedStart} class="slds-p-bottom_small">
                            <lightning-tile label={slot.dayOfWeek} class="slds-box slds-box_x-small">
                                <p class="slds-p-bottom_xx-small">
                                    <template if:true={slot.isToday}>Today</template>
                                    <template if:true={slot.isTomorrow}>Tomorrow</template>
                                    <template if:false={slot.isToday}>
                                        <template if:false={slot.isTomorrow}>
                                            {slot.formattedStart}
                                        </template>
                                    </template>
                                </p>
                                <p>{slot.formattedStart} - {slot.formattedEnd}</p>
                                <div class="slds-p-top_x-small">
                                    <lightning-button 
                                        label="Select This Slot" 
                                        variant="success"
                                        data-index={index}
                                        onclick={selectAlternativeSlot}>
                                    </lightning-button>
                                </div>
                            </lightning-tile>
                        </div>
                    </template>
                </div>
            </template>
        </div>
    </lightning-card>
</template>
```

3. **Create metadata file:**

```xml
<!-- roomBooking.js-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__RecordPage</target>
        <target>lightning__HomePage</target>
    </targets>
</LightningComponentBundle>
```

## Testing Steps

1. **Deploy Components:**
   - Deploy both the Apex class (`AlternativeSlotService.cls`) and the LWC components

2. **Add Component to a Page:**
   - Add the `roomBooking` component to a Lightning App, Record, or Home page

3. **Test the Flow:**
   - Select a room
   - Choose a start and end time that conflicts with an existing booking
   - Click "Book Room"
   - Observe the alternative slot suggestions
   - Select one of the suggested slots
   - Verify the form updates with the selected slot

4. **Testing Scenarios:**
   - Test with a completely booked room (should show no alternatives)
   - Test with invalid date/time formats (should show error toast)
   - Test with various durations (should maintain same duration in suggestions)
   - Test around business hour boundaries (suggestions should stay within 9 AM - 6 PM)
   - Test weekend requests (suggestions should only be weekdays)

## Integration with Existing Booking Flow

To integrate this feature with your existing booking process:

1. Call `suggestAlternativeRoomSlots` when a booking attempt fails due to time conflict
2. Display the alternatives to the user
3. Allow the user to select an alternative or continue with their original selection
4. Complete the booking process with the selected time slot

This bonus feature significantly improves user experience by providing intelligent alternatives rather than simply rejecting bookings when conflicts occur. 