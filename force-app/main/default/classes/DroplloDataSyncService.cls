/**
 * Data Sync Service for processing API data and upserting into Salesforce
 * Handles room and equipment data synchronization with external API
 * 
 * Features:
 * - Full sync of rooms and equipment from Dropillo API
 * - Automatic type mapping from API values to Salesforce picklist values
 * - Support for both manual and scheduled sync operations
 * - JSON amenities storage and proper field mapping
 * - External ID-based upsert operations for data consistency
 * 
 * @version 1.2
 * @author Dropillo Team
 */
public class DroplloDataSyncService {
    
    /**
     * Sync all resources with scheduled sync type
     * Used by scheduled jobs
     * @return SyncResult containing sync status and details
     */
    public static SyncResult syncAllResourcesScheduled() {
        SyncResult result = syncAllResourcesWithType('Daily_Sync');
        return result;
    }
    
    /**
     * Internal method to sync with specific sync type
     * @param syncType Type of sync (Daily_Sync or Manual_Sync)
     * @return SyncResult containing sync status and details
     */
    private static SyncResult syncAllResourcesWithType(String syncType) {
        SyncResult result = new SyncResult();
        result.syncType = syncType;
        result.startTime = DateTime.now();
        
        try {
            // Fetch data from API
            DroplloApiService.ApiResponse apiResponse = DroplloApiService.fetchResourcesData();
            
            if (!apiResponse.isSuccess) {
                result.isSuccess = false;
                result.errorMessage = 'API fetch failed: ' + apiResponse.errorMessage;
                result.endTime = DateTime.now();
                System.debug('API fetch failed: ' + apiResponse.errorMessage);
                return result;
            }
            
            // Capture API timestamp
            if (apiResponse != null && apiResponse.lastUpdated != null) {
                result.apiLastUpdated = apiResponse.lastUpdated;
            }
            
            // Sync rooms
            if (apiResponse.roomsData != null && !apiResponse.roomsData.isEmpty()) {
                Integer roomsSynced = syncRooms(apiResponse.roomsData);
                result.roomsSynced = roomsSynced;
                System.debug('Rooms synced: ' + roomsSynced);
            }
            
            // Sync equipment
            if (apiResponse.equipmentData != null && !apiResponse.equipmentData.isEmpty()) {
                Integer equipmentSynced = syncEquipment(apiResponse.equipmentData);
                result.equipmentSynced = equipmentSynced;
                System.debug('Equipment synced: ' + equipmentSynced);
            }
            
            result.isSuccess = true;
            result.syncDateTime = DateTime.now();
            result.endTime = DateTime.now();
            result.successMessage = 'Successfully synced ' + result.roomsSynced + ' rooms and ' + result.equipmentSynced + ' equipment items';
            System.debug(result.successMessage);
            
        } catch (Exception e) {
            result.isSuccess = false;
            result.errorMessage = 'Sync exception: ' + e.getMessage();
            result.endTime = DateTime.now();
            System.debug('Sync Exception: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Sync all resources (rooms and equipment) from external API
     * @return SyncResult containing sync status and details
     */
    public static SyncResult syncAllResources() {
        return syncAllResourcesWithType('Manual_Sync');
    }
    
    /**
     * Sync rooms data from API response
     * @param roomsData List of room objects from API
     * @return Integer number of rooms synced
     */
    private static Integer syncRooms(List<Object> roomsData) {
        List<Room__c> roomsToUpsert = new List<Room__c>();
        
        for (Object roomObj : roomsData) {
            Map<String, Object> roomMap = (Map<String, Object>) roomObj;
            
            Room__c room = new Room__c();
            room.External_Room_ID__c = (String) roomMap.get('id');
            room.Name = (String) roomMap.get('name');
            
            // Map room type based on name
            String roomName = (String) roomMap.get('name');
            room.Room_Type__c = mapRoomType(roomName);
            
            // Handle capacity
            Object capacityObj = roomMap.get('capacity');
            if (capacityObj != null) {
                room.Capacity__c = capacityObj instanceof Integer ? (Integer) capacityObj : Integer.valueOf(String.valueOf(capacityObj));
            }
            
            // Handle amenities array - store as JSON
            List<Object> amenitiesList = (List<Object>) roomMap.get('amenities');
            if (amenitiesList != null && !amenitiesList.isEmpty()) {
                room.Amenities__c = JSON.serialize(amenitiesList);
            }
            
            // Set sync timestamp
            room.Last_Sync_Date__c = DateTime.now();
            room.Is_Active__c = true;
            
            roomsToUpsert.add(room);
        }
        
        if (!roomsToUpsert.isEmpty()) {
            try {
                upsert roomsToUpsert External_Room_ID__c;
                return roomsToUpsert.size();
            } catch (DmlException e) {
                System.debug('Room upsert failed: ' + e.getMessage());
                return 0;
            }
        }
        
        return 0;
    }
    
    /**
     * Sync equipment data from API response
     * @param equipmentData List of equipment objects from API
     * @return Integer number of equipment items synced
     */
    private static Integer syncEquipment(List<Object> equipmentData) {
        List<Equipment__c> equipmentToUpsert = new List<Equipment__c>();
        
        for (Object equipmentObj : equipmentData) {
            Map<String, Object> equipmentMap = (Map<String, Object>) equipmentObj;
            
            Equipment__c equipment = new Equipment__c();
            equipment.External_Equipment_ID__c = (String) equipmentMap.get('id');
            equipment.Name = (String) equipmentMap.get('name');
            
            // Map equipment type to picklist value
            String equipmentType = (String) equipmentMap.get('type');
            equipment.Equipment_Type__c = mapEquipmentType(equipmentType);
            equipment.Serial_Number__c = (String) equipmentMap.get('serial_number');
            
            // Set sync timestamp and availability
            equipment.Last_Sync_Date__c = DateTime.now();
            equipment.Is_Active__c = true;
            equipment.Is_Available__c = true; // Default to available
            
            equipmentToUpsert.add(equipment);
        }
        
        if (!equipmentToUpsert.isEmpty()) {
            try {
                upsert equipmentToUpsert External_Equipment_ID__c;
                return equipmentToUpsert.size();
            } catch (DmlException e) {
                System.debug('Equipment upsert failed: ' + e.getMessage());
                return 0;
            }
        }
        
        return 0;
    }
    
    /**
     * Map room name to room type picklist value
     * @param roomName Name from API
     * @return String picklist value
     */
    private static String mapRoomType(String roomName) {
        if (roomName == null) return null;
        
        String lowerName = roomName.toLowerCase();
        
        if (lowerName.contains('focus pod')) {
            return 'Focus_Pod';
        } else if (lowerName.contains('huddle room')) {
            return 'Huddle_Room';
        } else if (lowerName.contains('collaboration room')) {
            return 'Collaboration_Room';
        } else if (lowerName.contains('boardroom')) {
            return 'Boardroom';
        }
        
        // Default fallback
        return 'Huddle_Room';
    }
    
    /**
     * Map equipment type from API to picklist value
     * @param equipmentType Type from API
     * @return String picklist value
     */
    private static String mapEquipmentType(String equipmentType) {
        if (equipmentType == null) return null;
        
        // Direct mapping based on API data structure
        switch on equipmentType {
            when 'VCU Type A' {
                return 'VCU_Type_A';
            }
            when 'VCU Type B' {
                return 'VCU_Type_B';
            }
            when 'Smartboard' {
                return 'Smartboard';
            }
            when 'VR/AR Testing Kit' {
                return 'VR_AR_Testing_Kit';
            }
            when 'Portable Projector' {
                return 'Portable_Projector';
            }
            when 'Digital Drawing Tablet' {
                return 'Digital_Drawing_Tablet';
            }
            when 'Wireless Presentation Clicker' {
                return 'Wireless_Presentation_Clicker';
            }
            when 'Portable Monitor' {
                return 'Portable_Monitor';
            }
            when 'Tablet' {
                return 'Tablet';
            }
            when 'Smartphone' {
                return 'Smartphone';
            }
            when else {
                return equipmentType; // Fallback to original value
            }
        }
    }
    
    /**
     * Wrapper class for sync results
     */
    public class SyncResult {
        public Boolean isSuccess = false;
        public String errorMessage;
        public String successMessage;
        public Integer roomsSynced = 0;
        public Integer equipmentSynced = 0;
        public DateTime syncDateTime;
        public DateTime startTime;
        public DateTime endTime;
        public String syncType;
        public String apiLastUpdated;
        
        // Helper method to get total items synced
        public Integer getTotalSynced() {
            return (roomsSynced != null ? roomsSynced : 0) + (equipmentSynced != null ? equipmentSynced : 0);
        }
        
        // Helper method to get sync duration in milliseconds
        public Long getSyncDurationMs() {
            if (startTime != null && endTime != null) {
                return endTime.getTime() - startTime.getTime();
            }
            return null;
        }
    }
}