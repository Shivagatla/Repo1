global class ContactWebService {
    webservice static void updateContact(String conId) { 
        User usr = [SELECT Id, Ag2Ag_ID__c,Email, Registration_Status__c,IsActive,IsPortalEnabled FROM User WHERE ContactId=:conId LIMIT 1];
        if(usr != null) {
            List<UserProvAccount> finalListToBeUpdated = new List<UserProvAccount>();
            for(UserProvAccount upa : [Select SalesforceUserId,Status from UserProvAccount where SalesforceUserId =: usr.Id]) {
                if('Active'.equalsIgnoreCase(upa.Status))
                    upa.Status = 'Deactivated';
                finalListToBeUpdated.add(upa);
            }
            Database.update(finalListToBeUpdated);
            UserHelper.disableUserContact(conId);
            UserHelper.scrambleContactEmail(conId);
        }
    }
}