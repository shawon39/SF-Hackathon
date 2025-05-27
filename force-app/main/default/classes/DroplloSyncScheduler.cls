/**
 * Scheduler class for daily synchronization of Dropillo API data
 * Runs at the beginning of each day to sync rooms and equipment
 */
public class DroplloSyncScheduler implements Schedulable {
    
    /**
     * Execute method required by the Schedulable interface
     * Called when the scheduled job runs
     * @param context The SchedulableContext
     */
    public void execute(SchedulableContext context) {
        // Call the sync service to process data
        String syncResults = DroplloSyncService.syncData();
        
        // Log results
        System.debug('Daily Dropillo sync completed: ' + syncResults);
    }
    
    /**
     * Utility method to schedule this job to run daily at a specific time
     * @param jobName The name to give this scheduled job
     * @param hour The hour to run the job (0-23)
     * @param minute The minute to run the job (0-59)
     * @return Id The scheduled job ID
     */
    public static Id scheduleDaily(String jobName, Integer hour, Integer minute) {
        // Default job name if not provided
        if (String.isBlank(jobName)) {
            jobName = 'Dropillo Daily Sync';
        }
        
        // Create a CRON expression for daily execution at the specified time
        String cronExp = '0 ' + minute + ' ' + hour + ' * * ?';
        
        // Schedule the job
        DroplloSyncScheduler scheduler = new DroplloSyncScheduler();
        return System.schedule(jobName, cronExp, scheduler);
    }
    
    /**
     * Convenience method to schedule this job to run at the beginning of each day (12:01 AM)
     * @return Id The scheduled job ID
     */
    public static Id scheduleForDailyMorning() {
        return scheduleDaily('Dropillo Daily Morning Sync', 0, 1);
    }
    
    /**
     * Run the sync process immediately (for testing or manual execution)
     * @return String The sync results
     */
    public static String runNow() {
        return DroplloSyncService.syncData();
    }
} 