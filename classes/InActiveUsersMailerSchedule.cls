public class InActiveUsersMailerSchedule implements Schedulable {    
    public void execute(SchedulableContext SC) {
        
        EmailTemplate templateId = [SELECT Id from EmailTemplate where developername = 'First_Warning_User_Inactivity' LIMIT 1];
        Profile prof = [SELECT Id,Name FROM Profile where Name = 'EMS External User' LIMIT 1];
        List<Messaging.MassEmailMessage> emailsList = new List<Messaging.MassEmailMessage>();
        
        if(prof != null && templateId != null) {
            Map<ID, User> usersMap = new Map<ID, User>([SELECT Id from User WHERE Last_Access_Date__c < N_DAYS_AGO:330 AND Last_Access_Date__c > N_DAYS_AGO:365 AND IsActive = true 
                                                        AND ProfileId =: prof.Id AND Ag2Ag_ID__c != null]);
            List<ID> usersList = new List<ID>(usersMap.keySet());
            List<List<ID>> lstWrapper = new List<List<ID>>();
            if(usersList.size() > 250) {
                for(Integer i = 0 ; i < (usersList.size()/250)+1 ; i++){
                    List<ID> lstTemp = new List<ID>();
                    for(Integer j=(i*250);(j<(i*250)+250) && j<usersList.size() ; j++){
                        lstTemp.add(usersList.get(j));
                    }
                    lstWrapper.add(lstTemp);
                }
            } else {
                lstWrapper.add(usersList);
            }
            
            for(List<ID> LH : lstWrapper)  {
                Messaging.MassEmailMessage email = new Messaging.MassEmailMessage();        
                email.setTargetObjectIds(LH);
                email.setTemplateId(templateId.Id);
                email.setSaveAsActivity(false);
                email.setSenderDisplayName('Website Support');
                emailsList.add(email);
            }
        }
        System.debug('Step 1 ################## => Warning Emails Sent');
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(emailsList);   
        }
        System.debug('Step 2 ################## => Fetching users to disable');
        List<User> userLists = [SELECT Id,IsActive,InactiveDate__c,Email,Last_Access_Date__c,External_Fed_Id__c 
                                from User WHERE Last_Access_Date__c < N_DAYS_AGO:365 AND IsActive = true AND ProfileId =: prof.Id AND Ag2Ag_ID__c != null];
        if(userLists != null && !userLists.isEmpty() && !Test.isRunningTest()) {
            Database.executeBatch(new DisableUserBatch(userLists), 10);
        }
    }
}