@isTest(SeeAllData=false)
private class DisableUserBatchTest {
    
    static testmethod void test() {
        List<User> usr = new List<User>();
        usr.add(createUser(Datetime.now().addDays(-340)));
        usr.add(createUser(Datetime.now().addDays(-350)));
        usr.add(createUser(Datetime.now().addDays(-360)));
        usr.add(createUser(Datetime.now().addDays(-370)));
        Test.startTest();
        new InActiveUsersMailerSchedule().execute(null);
        Test.stopTest();
    }
    
    static testmethod void test2() {
        List<User> usr = new List<User>();
        usr.add(createUser(Datetime.now().addDays(-340)));
        usr.add(createUser(Datetime.now().addDays(-350)));
        usr.add(createUser(Datetime.now().addDays(-360)));
        usr.add(createUser(Datetime.now().addDays(-370)));
        Test.startTest();
		DisableUserBatch dbBatch = new DisableUserBatch([Select Id,IsActive,InactiveDate__c,Email,Last_Access_Date__c,External_Fed_Id__c from User Where 
                                                        Phone = '111-222-3333']);
        Database.executeBatch(dbBatch); 
        Test.stopTest();
    }
    
    static testmethod void test3() {
        List<User> usr = new List<User>();
        usr.add(createUser(Datetime.now().addDays(-340)));
        usr.add(createUser(Datetime.now().addDays(-350)));
        usr.add(createUser(Datetime.now().addDays(-360)));
        usr.add(createUser(Datetime.now().addDays(-370)));
        Test.startTest();
        List<UserProvAccount> finalListToBeUpdated = new List<UserProvAccount>();
        Set<Id> urIds = new Set<Id>();
        for(User ur : usr) {
            urIds.add(ur.Id);
        }
        Database.executeBatch(new DisableUserBatchUPAs([Select Id, Status from UserProvAccount Where SalesforceUserId IN : urIds])); 
        Test.stopTest();
    }

    
    private static User createUser(Datetime lastAccessDate){
        String userN = generateRandomString(4);
        Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company'+userN,GUID__c='testingaccountonly'+userN));
        insert partnerAccounts;
        //Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
        List<Contact> partnerContacts = new List<Contact>();
        partnerContacts.add(new Contact(AccountId = partnerAccounts[0].Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN));
        insert partnerContacts;
        
        User u = new User();
        u.Username = userN+'@landolakes.com.ems.testing';
        u.Email = userN+'@e.t';
        u.FirstName = userN;
        u.LastName = userN;
        u.CommunityNickname = userN;
        u.Phone = '111-222-3333';
        u.ProfileId = profile.Id;
        u.Alias = 'test01';
        u.ContactId = partnerContacts[0].Id;
        u.EmailEncodingKey = 'ISO-8859-1';
        u.IsActive = true;
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'America/New_York';
        u.External_Fed_Id__c=userN;
        u.Last_Access_Date__c = lastAccessDate;
        u.Ag2Ag_ID__c = userN+userN;
        insert u;
        return u;
    }
    private static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz1234567890';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}