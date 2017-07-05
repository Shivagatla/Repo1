@isTest
private class TestEMSContactReviewCaseCreation {    
    @isTest static void testCreation() {
        String userN = '123562';
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company', GUID__c='thisisfortestingpurposes'));
        insert partnerAccounts;
        //Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
        List<Contact> partnerContacts = new List<Contact>();
        partnerContacts.add(new Contact(AccountId = partnerAccounts[0].Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN));
        insert partnerContacts;
        List<User> newUsers = new List<User>();
        
        User u = new User();
        u.Username = userN+'@landolakes.com.ems.testing';
        u.Email = userN+'@landolakes.com.ems.testing';
        u.FirstName = userN;
        u.LastName = userN;
        u.CommunityNickname = userN;
        u.Phone = '111-222-3333';
        u.ProfileId = profile.Id;
        //u.Verify_Hash__c = generateHash(userN+userN);
        u.Alias = 'test01';
        u.ContactId = partnerContacts[0].Id;
        u.EmailEncodingKey = 'ISO-8859-1';
        u.IsActive = false;
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'America/New_York';
        
        newUsers.add(u);
        insert newUsers;
        Test.startTest();
        EMSContactReviewCaseCreation.createCase( partnerContacts );
        Test.stopTest();
    }
    
    @isTest static void testAllBUCaseCreation() {
        String userN = '343434';
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company', GUID__c='thisisfortestingpurposes'));
        insert partnerAccounts;
        //Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
        List<Contact> partnerContacts = new List<Contact>();
        partnerContacts.add(new Contact(AccountId = partnerAccounts[0].Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN));
        insert partnerContacts;
        List<User> newUsers = new List<User>();
        
        User u = new User();
        u.Username = userN+'@landolakes.com.ems.testing';
        u.Email = userN+'@landolakes.com.ems.testing';
        u.FirstName = userN;
        u.LastName = userN;
        u.CommunityNickname = userN;
        u.Phone = '111-222-3333';
        u.ProfileId = profile.Id;
        //u.Verify_Hash__c = generateHash(userN+userN);
        u.Alias = 'test01';
        u.ContactId = partnerContacts[0].Id;
        u.EmailEncodingKey = 'ISO-8859-1';
        u.IsActive = false;
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'America/New_York';
        u.FGI__c = true;
        u.purina__c = true;
        u.lol__c = true;
        u.seed__c = true;
        u.corporate__c = true;
        
        newUsers.add(u);
        insert newUsers;
        Test.startTest();
        EMSContactReviewCaseCreation.createCase( partnerContacts );
        Test.stopTest();
    }
    
    @isTest static void testAg2AgIDUpdate() {
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            String userN = '123562';
            
            Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
            List<Account> partnerAccounts = new List<Account>();
            partnerAccounts.add(new Account(Name = 'Testing Communities Company', GUID__c='thisisfortestingpurposes'));
            insert partnerAccounts;
            //Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
            List<Contact> partnerContacts = new List<Contact>();
            partnerContacts.add(new Contact(AccountId = partnerAccounts[0].Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN));
            insert partnerContacts;
            List<User> newUsers = new List<User>();
            
            User u = new User();
            u.Username = userN+'@landolakes.com.ems.testing';
            u.Email = userN+'@landolakes.com.ems.testing';
            u.FirstName = userN;
            u.LastName = userN;
            u.CommunityNickname = userN;
            u.Phone = '111-222-3333';
            u.ProfileId = profile.Id;
            //u.Verify_Hash__c = generateHash(userN+userN);
            u.Alias = 'test01';
            u.ContactId = partnerContacts[0].Id;
            u.EmailEncodingKey = 'ISO-8859-1';
            u.IsActive = false;
            u.LanguageLocaleKey = 'en_US';
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'America/New_York';
            
            insert u; 
            
            Test.startTest();            
            u.Ag2Ag_ID__c = '1231411';
            update u;
            Test.stopTest();
            Contact contact = [SELECT Id, Ag2Ag_ID__c,Ex_Username__c, Related_External_User__c from Contact where Id=:u.ContactId LIMIT 1];
            if (contact != null){
                System.assert(contact.Ex_Username__c == '1231411');
            }
        }
    }
    
    @isTest static void testDisableContact() {
        String userN = '12356233';
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company', GUID__c='thisisfortestingpurposes'));
        insert partnerAccounts;
        //Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
        List<Contact> partnerContacts = new List<Contact>();
        Contact c = new Contact(AccountId = partnerAccounts[0].Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN);
        partnerContacts.add(c);
        insert partnerContacts;
        List<User> newUsers = new List<User>();
        
        User u = new User();
        u.Username = userN+'@landolakes.com.ems.testing';
        u.Email = userN+'@landolakes.com.ems.testing';
        u.FirstName = userN;
        u.LastName = userN;
        u.CommunityNickname = userN;
        u.Phone = '111-222-3333';
        u.ProfileId = profile.Id;
        //u.Verify_Hash__c = generateHash(userN+userN);
        u.Alias = 'test01';
        u.ContactId = partnerContacts[0].Id;
        u.EmailEncodingKey = 'ISO-8859-1';
        u.IsActive = false;
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'America/New_York';
        insert u;
        Test.startTest();
        
        c.Registration_Denied__c = true;
        update c;
        Test.stopTest();
        User user = [SELECT Id, Ag2Ag_ID__c,isActive from User where Id=:u.Id LIMIT 1];
        if (user != null){
            System.assert(user.isActive == false);
        }
    }
}