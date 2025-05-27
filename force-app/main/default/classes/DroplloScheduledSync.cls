/**
 * Scheduled Apex job for daily synchronization of rooms and equipment data
 * Runs daily to fetch latest data from external API
 */
public class DroplloScheduledSync implements Schedulable {
    
    /**
     * Execute method called by Salesforce scheduler
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        System.debug('Starting scheduled sync of Dropillo resources...');
        
        try {
            // Perform the sync using the scheduled method
            DroplloDataSyncService.SyncResult result = DroplloDataSyncService.syncAllResourcesScheduled();
            
            if (result.isSuccess) {
                System.debug('Scheduled sync completed successfully');
                System.debug('Rooms synced: ' + result.roomsSynced);
                System.debug('Equipment synced: ' + result.equipmentSynced);
                System.debug('API last updated: ' + result.apiLastUpdated);
                
                // Create sync log record
                createSyncLog(result, true, null);
                
            } else {
                System.debug('Scheduled sync failed: ' + result.errorMessage);
                createSyncLog(result, false, result.errorMessage);
            }
            
        } catch (Exception e) {
            System.debug('Scheduled sync exception: ' + e.getMessage());
            DroplloDataSyncService.SyncResult errorResult = new DroplloDataSyncService.SyncResult();
            createSyncLog(errorResult, false, 'Scheduled sync exception: ' + e.getMessage());
        }
    }
    
    /**
     * Create a sync log record for tracking
     * @param result SyncResult from the sync operation
     * @param success Whether the sync was successful
     * @param errorMessage Error message if sync failed
     */
    private void createSyncLog(DroplloDataSyncService.SyncResult result, Boolean success, String errorMessage) {
        try {
            // Create a task to log the sync activity
            Task syncLog = new Task();
            syncLog.Subject = 'Daily Dropillo Resource Sync - ' + Date.today();
            syncLog.Status = success ? 'Completed' : 'Not Started';
            syncLog.Priority = success ? 'Normal' : 'High';
            syncLog.ActivityDate = Date.today();
            
            String description = 'Daily sync of Dropillo resources from external API\n';
            description += 'Sync Time: ' + DateTime.now() + '\n';
            description += 'Status: ' + (success ? 'SUCCESS' : 'FAILED') + '\n';
            description += 'Sync Type: ' + (result.syncType != null ? result.syncType : 'Daily_Sync') + '\n';
            description += 'Rooms Synced: ' + (result.roomsSynced != null ? result.roomsSynced : 0) + '\n';
            description += 'Equipment Synced: ' + (result.equipmentSynced != null ? result.equipmentSynced : 0) + '\n';
            
            if (result.apiLastUpdated != null) {
                description += 'API Last Updated: ' + result.apiLastUpdated + '\n';
            }
            
            if (result.getSyncDurationMs() != null) {
                description += 'Sync Duration: ' + result.getSyncDurationMs() + ' ms\n';
            }
            
            if (!success && String.isNotBlank(errorMessage)) {
                description += 'Error: ' + errorMessage + '\n';
            }
            
            syncLog.Description = description;
            
            insert syncLog;
            
        } catch (Exception e) {
            System.debug('Failed to create sync log: ' + e.getMessage());
        }
    }
    
    /**
     * Schedule the daily sync job
     * Convenience method to schedule this job
     * @param cronExpression Cron expression for scheduling (e.g., '0 0 1 * * ?' for daily at 1 AM)
     * @return String job ID
     */
    public static String scheduleDailySync(String cronExpression) {
        DroplloScheduledSync scheduledSync = new DroplloScheduledSync();
        return System.schedule('Dropillo Daily Resource Sync', cronExpression, scheduledSync);
    }
    
    /**
     * Schedule daily sync at 1 AM every day
     * @return String job ID
     */
    public static String scheduleDailySync() {
        return scheduleDailySync('0 0 1 * * ?'); // Every day at 1 AM
    }
} 