/**
 * Test class for Dropillo synchronization classes
 */
@isTest
private class DroplloSyncTest {
    
    // Mock HTTP callout response for tests
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Sample response data
            String mockResponseBody = '{"rooms": [' +
                '{"id": "room-001", "name": "Conference Room 1", "capacity": 10, "amenities": ["Projector", "Whiteboard"]},' +
                '{"id": "room-002", "name": "Meeting Room A", "capacity": 6, "amenities": ["TV", "Phone"]}' +
                '], "equipment": [' +
                '{"id": "equip-001", "name": "Projector 1", "type": "Projector", "serial_number": "PRJ-123456"},' +
                '{"id": "equip-002", "name": "Laptop 1", "type": "Computer", "serial_number": "LPT-789012"}' +
                '], "last_updated": "2023-05-01T08:00:00Z"}';
            
            res.setBody(mockResponseBody);
            return res;
        }
    }
    
    /**
     * Test the sync functionality for creating new records
     */
    @isTest
    static void testSyncNewRecords() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Start test
        Test.startTest();
        
        // Run sync
        String results = DroplloSyncScheduler.runNow();
        
        // End test
        Test.stopTest();
        
        // Verify results - should have created rooms
        List<Room__c> rooms = [SELECT Id, Name, External_Room_ID__c, Capacity__c, Amenities__c 
                              FROM Room__c 
                              WHERE External_Room_ID__c IN ('room-001', 'room-002')];
        
        System.assertEquals(2, rooms.size(), 'Should have created 2 rooms');
        
        // Find Conference Room 1
        Room__c conferenceRoom = null;
        for(Room__c r : rooms) {
            if(r.External_Room_ID__c == 'room-001') {
                conferenceRoom = r;
                break;
            }
        }
        
        System.assertNotEquals(null, conferenceRoom, 'Conference Room 1 should exist');
        System.assertEquals('Conference Room 1', conferenceRoom.Name, 'Room name should match');
        System.assertEquals(10, conferenceRoom.Capacity__c, 'Room capacity should match');
        System.assertEquals('Projector;Whiteboard', conferenceRoom.Amenities__c, 'Room amenities should match');
        
        // Verify equipment
        List<Equipment__c> equipment = [SELECT Id, Name, External_Equipment_ID__c, Equipment_Type__c, Serial_Number__c 
                                       FROM Equipment__c 
                                       WHERE External_Equipment_ID__c IN ('equip-001', 'equip-002')];
        
        System.assertEquals(2, equipment.size(), 'Should have created 2 equipment records');
        
        // Find Projector
        Equipment__c projector = null;
        for(Equipment__c e : equipment) {
            if(e.External_Equipment_ID__c == 'equip-001') {
                projector = e;
                break;
            }
        }
        
        System.assertNotEquals(null, projector, 'Projector should exist');
        System.assertEquals('Projector 1', projector.Name, 'Equipment name should match');
        System.assertEquals('Projector', projector.Equipment_Type__c, 'Equipment type should match');
        System.assertEquals('PRJ-123456', projector.Serial_Number__c, 'Serial number should match');
    }
    
    /**
     * Test the sync functionality for updating existing records
     */
    @isTest
    static void testSyncExistingRecords() {
        // Create test records first
        Room__c room = new Room__c(
            Name = 'Old Room Name',
            External_Room_ID__c = 'room-001',
            Capacity__c = 5,
            Amenities__c = 'Old Amenity',
            Is_Active__c = true
        );
        insert room;
        
        Equipment__c equipment = new Equipment__c(
            Name = 'Old Equipment Name',
            External_Equipment_ID__c = 'equip-001',
            Equipment_Type__c = 'Old Type',
            Serial_Number__c = 'OLD-123',
            Is_Active__c = true
        );
        insert equipment;
        
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Start test
        Test.startTest();
        
        // Run sync
        String results = DroplloSyncScheduler.runNow();
        
        // End test
        Test.stopTest();
        
        // Verify results - should have updated rooms
        Room__c updatedRoom = [SELECT Id, Name, External_Room_ID__c, Capacity__c, Amenities__c 
                              FROM Room__c 
                              WHERE External_Room_ID__c = 'room-001'];
        
        System.assertEquals('Conference Room 1', updatedRoom.Name, 'Room name should be updated');
        System.assertEquals(10, updatedRoom.Capacity__c, 'Room capacity should be updated');
        System.assertEquals('Projector;Whiteboard', updatedRoom.Amenities__c, 'Room amenities should be updated');
        
        // Verify equipment
        Equipment__c updatedEquipment = [SELECT Id, Name, External_Equipment_ID__c, Equipment_Type__c, Serial_Number__c 
                                        FROM Equipment__c 
                                        WHERE External_Equipment_ID__c = 'equip-001'];
        
        System.assertEquals('Projector 1', updatedEquipment.Name, 'Equipment name should be updated');
        System.assertEquals('Projector', updatedEquipment.Equipment_Type__c, 'Equipment type should be updated');
        System.assertEquals('PRJ-123456', updatedEquipment.Serial_Number__c, 'Serial number should be updated');
    }
    
    /**
     * Test the sync functionality for deactivating records that no longer exist in API
     */
    @isTest
    static void testSyncDeactivateRecords() {
        // Create test records first
        Room__c room = new Room__c(
            Name = 'Room To Deactivate',
            External_Room_ID__c = 'room-999', // Not in API response
            Capacity__c = 5,
            Amenities__c = 'Test',
            Is_Active__c = true
        );
        insert room;
        
        Equipment__c equipment = new Equipment__c(
            Name = 'Equipment To Deactivate',
            External_Equipment_ID__c = 'equip-999', // Not in API response
            Equipment_Type__c = 'Test',
            Serial_Number__c = 'TEST-999',
            Is_Active__c = true
        );
        insert equipment;
        
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Start test
        Test.startTest();
        
        // Run sync
        String results = DroplloSyncScheduler.runNow();
        
        // End test
        Test.stopTest();
        
        // Verify results - should have deactivated records not in API
        Room__c deactivatedRoom = [SELECT Id, Is_Active__c 
                                  FROM Room__c 
                                  WHERE External_Room_ID__c = 'room-999'];
        
        System.assertEquals(false, deactivatedRoom.Is_Active__c, 'Room should be deactivated');
        
        // Verify equipment
        Equipment__c deactivatedEquipment = [SELECT Id, Is_Active__c 
                                           FROM Equipment__c 
                                           WHERE External_Equipment_ID__c = 'equip-999'];
        
        System.assertEquals(false, deactivatedEquipment.Is_Active__c, 'Equipment should be deactivated');
    }
    
    /**
     * Test the scheduler functionality
     */
    @isTest
    static void testScheduler() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Start test
        Test.startTest();
        
        // Schedule the job
        Id jobId = DroplloSyncScheduler.scheduleForDailyMorning();
        
        // Verify the job was scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled');
        
        // End test
        Test.stopTest();
        
        // Can't verify scheduled jobs in test context as they don't actually execute
    }
} 