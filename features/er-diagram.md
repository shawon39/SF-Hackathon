# Dropillo Space & Asset Hub - Salesforce Data Model

## Mermaid ER Diagram (Salesforce Style)

```mermaid
erDiagram
    %% Custom Objects with Salesforce Standard Fields
    
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
        Picklist Equipment_Type__c "PVCU, VR_AR_Kit, Projector, Monitor, Tablet, Phone"
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
    
    API_SYNC_LOG__C {
        Id Id PK "18-char Salesforce ID"
        AutoNumber Name "SYNC-{0000000}"
        Picklist Sync_Type__c "Daily_Sync, Manual_Sync"
        Picklist Sync_Status__c "In_Progress, Success, Failed, Partial"
        DateTime Start_Time__c "Sync start time"
        DateTime End_Time__c "Sync end time"
        Number Rooms_Processed__c "Rooms synced (5,0)"
        Number Equipment_Processed__c "Equipment synced (5,0)"
        LongTextArea Error_Message__c "Error details (32768)"
        LongTextArea Success_Message__c "Success summary (32768)"
        DateTime CreatedDate "SF Standard"
        DateTime LastModifiedDate "SF Standard"
        Lookup CreatedById "SF Standard"
        Lookup LastModifiedById "SF Standard"
        Lookup OwnerId "SF Standard"
    }
    
    BOOKING_CONFLICT__C {
        Id Id PK "18-char Salesforce ID"
        AutoNumber Name "CONFLICT-{0000000}"
        Lookup Primary_Booking__c FK "Original booking"
        Lookup Conflicting_Booking__c FK "Conflicting booking"
        Picklist Conflict_Type__c "Time_Overlap, Double_Booking"
        Picklist Resolution_Status__c "Pending, Resolved, Escalated"
        Lookup Resolved_By__c FK "Resolving user"
        LongTextArea Resolution_Notes__c "Resolution details (32768)"
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
        Picklist Notification_Preference__c "Email, SMS, Both"
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
    
    %% Salesforce Relationships
    
    %% User to Booking (One-to-Many Lookup)
    USER ||--o{ BOOKING__C : "Booking_User__c"
    
    %% User to Task (One-to-Many Lookup)
    USER ||--o{ TASK : "WhoId"
    
    %% User to Booking Conflict (One-to-Many Lookup)
    USER ||--o{ BOOKING_CONFLICT__C : "Resolved_By__c"
    
    %% Room to Booking (One-to-Many Lookup)
    ROOM__C ||--o{ BOOKING__C : "Room__c"
    
    %% Equipment to Booking (One-to-Many Lookup)
    EQUIPMENT__C ||--o{ BOOKING__C : "Equipment__c"
    
    %% Booking to Task (One-to-Many Lookup)
    BOOKING__C ||--o{ TASK : "WhatId"
    
    %% Booking to Booking Conflict (One-to-Many Lookup)
    BOOKING__C ||--o{ BOOKING_CONFLICT__C : "Primary_Booking__c"
    BOOKING__C ||--o{ BOOKING_CONFLICT__C : "Conflicting_Booking__c"
```

## Salesforce Relationship Details

### Primary Lookup Relationships

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

### Conflict Management Relationships

5. **BOOKING__C → BOOKING_CONFLICT__C** (1:M Lookup)
   - **Fields**: 
     - `Primary_Booking__c` (Lookup to Booking__c)
     - `Conflicting_Booking__c` (Lookup to Booking__c)
   - **Type**: Required Lookup
   - **Description**: A booking can be involved in multiple conflicts
   - **On Delete**: Cascade

6. **USER → BOOKING_CONFLICT__C** (1:M Lookup)
   - **Field**: `Resolved_By__c` (Lookup to User)
   - **Type**: Optional Lookup
   - **Description**: Admin users resolve conflicts
   - **On Delete**: Set Null

### Salesforce Field Constraints & Validation Rules

- **Booking Either/Or Validation**: 
  ```
  AND(ISBLANK(Room__c), ISBLANK(Equipment__c))
  ```
- **External ID Uniqueness**: 
  - `External_Room_ID__c` (Unique, External ID, Case Insensitive)
  - `External_Equipment_ID__c` (Unique, External ID, Case Insensitive)
- **Serial Number Constraint**: 
  - `Serial_Number__c` (Unique, Required when Is_Active__c = true)
- **DateTime Validation**: 
  ```
  Start_DateTime__c >= End_DateTime__c
  ```
- **Future Booking Rule**: 
  ```
  AND(ISNEW(), Start_DateTime__c <= NOW())
  ```
- **Business Hours Validation**:
  ```
  OR(
    HOUR(Start_DateTime__c) < 8,
    HOUR(End_DateTime__c) > 20
  )
  ```

### Salesforce Indexes & Performance

- **Custom Indexes**:
  - `Room__c`: (`Is_Active__c`, `Room_Type__c`)
  - `Equipment__c`: (`Is_Available__c`, `Equipment_Type__c`)
  - `Booking__c`: (`Start_DateTime__c`, `End_DateTime__c`, `Status__c`)

- **External ID Indexes** (Auto-created):
  - `External_Room_ID__c`
  - `External_Equipment_ID__c`
  - `Serial_Number__c`

### Organization-Wide Defaults (OWD)

| Object | OWD Setting | Reason |
|--------|-------------|---------|
| `Room__c` | Public Read Only | All users need to see available rooms |
| `Equipment__c` | Public Read Only | All users need to see available equipment |
| `Booking__c` | Private | Users should only see their own bookings |
| `API_Sync_Log__c` | Private | Admin/System only |
| `Booking_Conflict__c` | Private | Admin only for conflict resolution |

### Sharing Rules & Permission Sets

**Sharing Rules**:
- `Booking__c` shared with "All Employees" (Read Only) for calendar view
- `Booking__c` shared with "Office Administrators" role (Read/Write)

**Permission Sets**:
1. **Space_Asset_User_PS**: 
   - Create/Read/Edit own Booking__c records
   - Read Room__c and Equipment__c
2. **Space_Asset_Admin_PS**: 
   - Full CRUD on all custom objects
   - Manage conflicts and sync logs
3. **Space_Asset_Manager_PS**: 
   - Read-only access for reporting and dashboards

### Field-Level Security (FLS)

**Restricted Fields**:
- `API_Sync_Log__c.*` → Admin only
- `Booking_Conflict__c.*` → Admin only
- `External_Room_ID__c` → System/Admin only
- `External_Equipment_ID__c` → System/Admin only
- `Last_Sync_Date__c` → System/Admin only 