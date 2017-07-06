trigger EMSContactDenied on Contact (after update) {
    for (Contact a : Trigger.new) {
        if (a.Registration_Denied__c == true) {
            User usr = [SELECT Id, Ag2Ag_ID__c,Email, Registration_Status__c,IsActive,IsPortalEnabled FROM User WHERE ContactId=:a.Id LIMIT 1];
            if(usr != null) {
                List<UserProvAccount> finalListToBeUpdated = new List<UserProvAccount>();
                for(UserProvAccount upa : [Select SalesforceUserId,Status from UserProvAccount where SalesforceUserId =: usr.Id]) {
                    if('Active'.equalsIgnoreCase(upa.Status))
                        upa.Status = 'Deactivated';
                    finalListToBeUpdated.add(upa);
                }
                Database.update(finalListToBeUpdated);   
            }
            UserHelper.disableUserContact(a.Id);
        }
    }
}