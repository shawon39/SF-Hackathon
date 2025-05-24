/**
 * API Service for fetching rooms and equipment data from Dropillo's external API
 * Handles authentication and data retrieval
 */
public class DroplloApiService {
    
    private static final String API_ENDPOINT = 'https://raw.githubusercontent.com/twentyTwo/sf-hackathon-bd-2025/refs/heads/main/data.json';
    
    /**
     * Fetch all rooms and equipment data from external API
     * @return ApiResponse containing rooms and equipment data or error info
     */
    public static ApiResponse fetchResourcesData() {
        ApiResponse response = new ApiResponse();
        
        try {
            
            // Make API call
            HttpRequest req = new HttpRequest();
            req.setEndpoint(API_ENDPOINT);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(60000); // 60 seconds timeout
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('API Response Status: ' + res.getStatusCode());
            System.debug('API Response Body: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                // Parse response
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                response.isSuccess = true;
                response.roomsData = (List<Object>) responseMap.get('rooms');
                response.equipmentData = (List<Object>) responseMap.get('equipment');
                response.lastUpdated = (String) responseMap.get('last_updated');
                
                System.debug('Rooms fetched: ' + (response.roomsData != null ? response.roomsData.size() : 0));
                System.debug('Equipment fetched: ' + (response.equipmentData != null ? response.equipmentData.size() : 0));
                System.debug('Last updated: ' + response.lastUpdated);
                
            } else {
                response.isSuccess = false;
                response.errorMessage = 'API call failed with status: ' + res.getStatusCode() + ' - ' + res.getBody();
            }
            
        } catch (Exception e) {
            response.isSuccess = false;
            response.errorMessage = 'API call exception: ' + e.getMessage();
            System.debug('API Exception: ' + e.getMessage());
        }
        
        return response;
    }
    
    /**
     * Wrapper class for API response
     */
    public class ApiResponse {
        public Boolean isSuccess = false;
        public String errorMessage;
        public List<Object> roomsData;
        public List<Object> equipmentData;
        public String lastUpdated;
    }
    
    /**
     * Room data structure from API
     */
    public class RoomData {
        public String id;
        public String name;
        public Integer capacity;
        public List<String> amenities;
    }
    
    /**
     * Equipment data structure from API
     */
    public class EquipmentData {
        public String id;
        public String name;
        public String type;
        public String serial_number;
    }
    
    public static void multiLineDebug(Object debugContents, string tag){
        String debugText = JSON.serialize(debugContents);
        Pattern lengthLimit = Pattern.compile('(.{200})');
        debugText = lengthLimit.matcher(debugText).replaceAll('$1\n');
        system.debug(tag + debugText);
	}
}