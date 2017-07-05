public class UserHelper {   
    
    
    @future public static void updateUserEmailVerification(String userId, Boolean verified){        
        User[] users = [SELECT Id, Email,Email_Verified__c,FirstName,LastName FROM User WHERE Username=:userId LIMIT 1];        
        if (users == null) {
            System.DEBUG('ERROR: Unable to locate user ' + userId + ' and mark their email address as verified');
            return;
        }        
        User user = users[0];
        user.Email_Verified__c = verified;
        try{
            update user;
        }
        catch(Exception e){
            System.DEBUG('ERROR: Unable to mark user\'s email address as verified: ' + userId);
        }
    }
    
    
    
    @future(callout=true)
    public static void disableUserContact(String contactId){        
        System.DEBUG('INFO: Disabling contact ' + contactID);
        User[] users = [SELECT Id, Ag2Ag_ID__c,Email, Registration_Status__c,IsActive,IsPortalEnabled FROM User WHERE ContactId=:contactId];
        if (users == null || users.isEmpty()) {
            System.DEBUG('ERROR: Unable to locate contact ' + contactId + ' and disable its User record');
            return;
        }
        User u = users[0];
        List<User> finalListToBeUpdated = new List<User>();
        try {
            Datetime nowDate = Datetime.now();
            String dateOutput = nowDate.format('yyyyMMddHHmmss');
            u.Registration_Status__c = 'Denied';
            u.IsActive = false;
            u.InactiveDate__c = System.now();
            u.Email = 'DIS_'+dateOutput+'_'+u.Email;
            u.External_Fed_Id__c = '';
            Database.update(u, false);
            ID jobID = System.enqueueJob(new UserProvisioningServiceQueuable(EMSConstants.DISABLEUSER_ACT, u,null));
        } catch (Exception e) {
            System.DEBUG('ERROR: Unable to disable user ' + u.Ag2Ag_ID__c + ' based on contact ' + contactId);
        }
    }
    
    @future
    public static void scrambleContactEmail(String conId) {
        Datetime nowDate = Datetime.now();
        String dateOutput = nowDate.format('yyyyMMddHHmmss');
        Contact dbCon = [Select email from Contact where Id =: conId LIMIT 1];
        dbCon.Email = 'DIS_'+dateOutput+'_'+dbCon.Email;
        Database.SaveResult results = Database.update(dbCon, false);
    }
}