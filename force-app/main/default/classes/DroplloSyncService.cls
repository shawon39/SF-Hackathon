/**
 * Service class to handle synchronization of Rooms and Equipment data 
 * from Dropillo API to Salesforce records
 */
public class DroplloSyncService {
    
    /**
     * Synchronizes rooms and equipment data from the API with Salesforce records
     * @return String Status message with sync results
     */
    public static String syncData() {
        // Call API to fetch latest data
        DroplloApiService.ApiResponse apiResponse = DroplloApiService.fetchResourcesData();
        
        if (!apiResponse.isSuccess) {
            return 'Sync failed: ' + apiResponse.errorMessage;
        }
        
        String syncResults = '';
        
        // Sync rooms
        String roomResults = syncRooms(apiResponse.roomsData);
        syncResults += roomResults;
        
        // Sync equipment
        String equipmentResults = syncEquipment(apiResponse.equipmentData);
        syncResults += '\n' + equipmentResults;
        
        return syncResults;
    }
    
    /**
     * Synchronizes room data from API with Room__c records
     * @param roomsData List of room data from API
     * @return String Status message with results
     */
    private static String syncRooms(List<Object> roomsData) {
        if (roomsData == null || roomsData.isEmpty()) {
            return 'No rooms data to sync';
        }
        
        // Get all existing rooms
        Map<String, Room__c> existingRoomsByExternalId = new Map<String, Room__c>();
        for (Room__c room : [SELECT Id, Name, External_Room_ID__c, Capacity__c, Amenities__c, Is_Active__c 
                             FROM Room__c]) {
            existingRoomsByExternalId.put(room.External_Room_ID__c, room);
        }
        
        // Track which external IDs we process
        Set<String> processedExternalIds = new Set<String>();
        
        // Lists for DML operations
        List<Room__c> roomsToUpsert = new List<Room__c>();
        
        // Process each room from API
        for (Object roomObj : roomsData) {
            Map<String, Object> roomMap = (Map<String, Object>) roomObj;
            
            String externalId = (String) roomMap.get('id');
            processedExternalIds.add(externalId);
            
            // Create or update room
            Room__c room;
            if (existingRoomsByExternalId.containsKey(externalId)) {
                room = existingRoomsByExternalId.get(externalId);
            } else {
                room = new Room__c(
                    External_Room_ID__c = externalId,
                    Is_Active__c = true
                );
            }
            
            // Update fields
            room.Name = (String) roomMap.get('name');
            room.Capacity__c = (Integer) roomMap.get('capacity');
            
            // Handle amenities (convert list to semicolon-separated string)
            List<Object> amenitiesObj = (List<Object>) roomMap.get('amenities');
            if (amenitiesObj != null && !amenitiesObj.isEmpty()) {
                List<String> amenitiesList = new List<String>();
                for (Object amenity : amenitiesObj) {
                    amenitiesList.add((String) amenity);
                }
                room.Amenities__c = String.join(amenitiesList, ';');
            }
            
            room.Last_Sync_Date__c = DateTime.now();
            roomsToUpsert.add(room);
        }
        
        // Find rooms to deactivate (those in SF but not in API response)
        List<Room__c> roomsToDeactivate = new List<Room__c>();
        for (String externalId : existingRoomsByExternalId.keySet()) {
            if (!processedExternalIds.contains(externalId)) {
                Room__c room = existingRoomsByExternalId.get(externalId);
                room.Is_Active__c = false;
                room.Last_Sync_Date__c = DateTime.now();
                roomsToUpsert.add(room);
            }
        }
        
        // Perform DML operations
        Integer createdCount = 0;
        Integer updatedCount = 0;
        Integer deactivatedCount = 0;
        
        if (!roomsToUpsert.isEmpty()) {
            upsert roomsToUpsert External_Room_ID__c;
            
            // Count created vs updated
            for (Room__c room : roomsToUpsert) {
                if (existingRoomsByExternalId.containsKey(room.External_Room_ID__c)) {
                    if (room.Is_Active__c) {
                        updatedCount++;
                    } else {
                        deactivatedCount++;
                    }
                } else {
                    createdCount++;
                }
            }
        }
        
        return 'Rooms sync complete. Created: ' + createdCount + ', Updated: ' + updatedCount + ', Deactivated: ' + deactivatedCount;
    }
    
    /**
     * Synchronizes equipment data from API with Equipment__c records
     * @param equipmentData List of equipment data from API
     * @return String Status message with results
     */
    private static String syncEquipment(List<Object> equipmentData) {
        if (equipmentData == null || equipmentData.isEmpty()) {
            return 'No equipment data to sync';
        }
        
        // Get all existing equipment
        Map<String, Equipment__c> existingEquipmentByExternalId = new Map<String, Equipment__c>();
        for (Equipment__c equipment : [SELECT Id, Name, External_Equipment_ID__c, Equipment_Type__c, 
                                      Serial_Number__c, Is_Active__c 
                                      FROM Equipment__c]) {
            existingEquipmentByExternalId.put(equipment.External_Equipment_ID__c, equipment);
        }
        
        // Track which external IDs we process
        Set<String> processedExternalIds = new Set<String>();
        
        // Lists for DML operations
        List<Equipment__c> equipmentToUpsert = new List<Equipment__c>();
        
        // Process each equipment from API
        for (Object equipObj : equipmentData) {
            Map<String, Object> equipMap = (Map<String, Object>) equipObj;
            
            String externalId = (String) equipMap.get('id');
            processedExternalIds.add(externalId);
            
            // Create or update equipment
            Equipment__c equipment;
            if (existingEquipmentByExternalId.containsKey(externalId)) {
                equipment = existingEquipmentByExternalId.get(externalId);
            } else {
                equipment = new Equipment__c(
                    External_Equipment_ID__c = externalId,
                    Is_Active__c = true
                );
            }
            
            // Update fields
            equipment.Name = (String) equipMap.get('name');
            equipment.Equipment_Type__c = (String) equipMap.get('type');
            equipment.Serial_Number__c = (String) equipMap.get('serial_number');
            equipment.Last_Sync_Date__c = DateTime.now();
            
            equipmentToUpsert.add(equipment);
        }
        
        // Find equipment to deactivate (those in SF but not in API response)
        List<Equipment__c> equipmentToDeactivate = new List<Equipment__c>();
        for (String externalId : existingEquipmentByExternalId.keySet()) {
            if (!processedExternalIds.contains(externalId)) {
                Equipment__c equipment = existingEquipmentByExternalId.get(externalId);
                equipment.Is_Active__c = false;
                equipment.Last_Sync_Date__c = DateTime.now();
                equipmentToUpsert.add(equipment);
            }
        }
        
        // Perform DML operations
        Integer createdCount = 0;
        Integer updatedCount = 0;
        Integer deactivatedCount = 0;
        
        if (!equipmentToUpsert.isEmpty()) {
            upsert equipmentToUpsert External_Equipment_ID__c;
            
            // Count created vs updated
            for (Equipment__c equipment : equipmentToUpsert) {
                if (existingEquipmentByExternalId.containsKey(equipment.External_Equipment_ID__c)) {
                    if (equipment.Is_Active__c) {
                        updatedCount++;
                    } else {
                        deactivatedCount++;
                    }
                } else {
                    createdCount++;
                }
            }
        }
        
        return 'Equipment sync complete. Created: ' + createdCount + ', Updated: ' + updatedCount + ', Deactivated: ' + deactivatedCount;
    }
} 