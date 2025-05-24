# Dropillo Space & Asset Hub - Salesforce Data Model (Current Implementation)

## Mermaid ER Diagram (Salesforce Style) - IMPLEMENTED OBJECTS ONLY

```mermaid
erDiagram
    %% Custom Objects with Salesforce Standard Fields (IMPLEMENTED)
    
    ROOM__C {
        Id Id PK "18-char Salesforce ID"
        Text Name "Room Name (80)"
        Text External_Room_ID__c UK "External API ID (50)"
        Picklist Room_Type__c "Focus_Pod, Huddle_Room, Collaboration_Room, Boardroom"
        Number Capacity__c "Max occupancy (3,0)"
        TextArea Amenities__c "JSON amenities (32768)"
        Text Floor__c "Floor location (10)"
        Checkbox Is_Active__c "Available for booking"
        DateTime Last_Sync_Date__c "Last API sync"
        DateTime CreatedDate "SF Standard"
        DateTime LastModifiedDate "SF Standard"
        Lookup CreatedById "SF Standard"
        Lookup LastModifiedById "SF Standard"
        Lookup OwnerId "SF Standard"
    }
    
    EQUIPMENT__C {
        Id Id PK "18-char Salesforce ID"
        Text Name "Equipment Name (80)"
        Text External_Equipment_ID__c UK "External API ID (50)"
        Text Equipment_Type__c "Equipment Type (255)"
        Text Serial_Number__c UK "Serial number (50)"
        Checkbox Is_Available__c "Current availability"
        Checkbox Is_Active__c "Active status"
        DateTime Last_Sync_Date__c "Last API sync"
        Text Current_Location__c "Physical location (100)"
        DateTime CreatedDate "SF Standard"
        DateTime LastModifiedDate "SF Standard"
        Lookup CreatedById "SF Standard"
        Lookup LastModifiedById "SF Standard"
        Lookup OwnerId "SF Standard"
    }
    
    BOOKING__C {
        Id Id PK "18-char Salesforce ID"
        AutoNumber Name "B-{0000000}"
        Lookup Booking_User__c FK "User making booking"
        Picklist Booking_Type__c "Room, Equipment"
        Lookup Room__c FK "Booked room (optional)"
        Lookup Equipment__c FK "Booked equipment (optional)"
        DateTime Start_DateTime__c "Booking start"
        DateTime End_DateTime__c "Booking end"
        Picklist Status__c "Pending, Confirmed, In_Use, Completed, Cancelled"
        LongTextArea Purpose__c "Booking reason (32768)"
        Number Attendee_Count__c "Expected attendees (3,0)"
        Picklist Return_Status__c "Not_Applicable, Not_Returned, Returned, Overdue"
        LongTextArea Booking_Notes__c "Additional notes (32768)"
        Checkbox Notification_Sent__c "Email sent status"
        DateTime CreatedDate "SF Standard"
        DateTime LastModifiedDate "SF Standard"
        Lookup CreatedById "SF Standard"
        Lookup LastModifiedById "SF Standard"
        Lookup OwnerId "SF Standard"
    }
    
    %% Standard Salesforce Objects
    
    USER {
        Id Id PK "18-char Salesforce ID"
        Text Name "Full name (80)"
        Email Email "Email address (80)"
        Text Department "User department (80)"
        Text Title "Job title (80)"
        DateTime CreatedDate "SF Standard"
        DateTime LastModifiedDate "SF Standard"
        Checkbox IsActive "SF Standard"
        Text Username "SF Standard"
        Profile ProfileId "SF Standard"
    }
    
    TASK {
        Id Id PK "18-char Salesforce ID"
        Text Subject "Task subject (255)"
        LongTextArea Description "Task description (32000)"
        Date ActivityDate "Due date"
        Lookup WhoId FK "Related User/Contact/Lead"
        Lookup WhatId FK "Related SObject"
        Picklist Status "SF Standard Picklist"
        Picklist Priority "SF Standard Picklist"
        DateTime CreatedDate "SF Standard"
        DateTime LastModifiedDate "SF Standard"
        Lookup CreatedById "SF Standard"
        Lookup LastModifiedById "SF Standard"
        Lookup OwnerId "SF Standard"
    }
    
    %% Salesforce Relationships (IMPLEMENTED)
    
    %% User to Booking (One-to-Many Lookup)
    USER ||--o{ BOOKING__C : "Booking_User__c"
    
    %% User to Task (One-to-Many Lookup)
    USER ||--o{ TASK : "WhoId"
    
    %% Room to Booking (One-to-Many Lookup)
    ROOM__C ||--o{ BOOKING__C : "Room__c"
    
    %% Equipment to Booking (One-to-Many Lookup)
    EQUIPMENT__C ||--o{ BOOKING__C : "Equipment__c"
    
    %% Booking to Task (One-to-Many Lookup)
    BOOKING__C ||--o{ TASK : "WhatId"
```

## Salesforce Relationship Details (CURRENT IMPLEMENTATION)

### Implemented Lookup Relationships

1. **USER → BOOKING__C** (1:M Lookup)
   - **Field**: `Booking_User__c` (Lookup to User)
   - **Type**: Required Lookup
   - **Description**: Each user can create multiple bookings
   - **On Delete**: Restrict (prevent user deletion if bookings exist)

2. **ROOM__C → BOOKING__C** (1:M Lookup)
   - **Field**: `Room__c` (Lookup to Room__c)
   - **Type**: Optional Lookup
   - **Description**: Each room can have multiple bookings
   - **On Delete**: Set Null

3. **EQUIPMENT__C → BOOKING__C** (1:M Lookup)
   - **Field**: `Equipment__c` (Lookup to Equipment__c)
   - **Type**: Optional Lookup
   - **Description**: Each equipment can have multiple bookings
   - **On Delete**: Set Null

4. **BOOKING__C → TASK** (1:M Standard Relationship)
   - **Field**: `WhatId` (Standard Task field)
   - **Type**: Polymorphic Lookup
   - **Description**: Each booking can generate multiple reminder tasks
   - **Trigger Generated**: Auto-created via Apex trigger

