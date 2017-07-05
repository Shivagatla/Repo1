@isTest
public class NewUsersUploadEmailNotifyingBatchTest {
    @testSetup static void testData() {
        String profileId = [SELECT Id FROM Profile WHERE Name =: Constants.EMS_EXTERNAL_USER LIMIT 1].Id;
        
        EmailNotificationUrl__c enu = new EmailNotificationUrl__c();
        enu.Name = 'EMS';
        enu.Url__c = 'testUrl';        
        Database.insert(enu);
        
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail = false;
        
        //Create test account.
        Account a = new Account();
        a.Name = 'Test Account';
        a.Customer_Number__c = '7303726';
        a.GUID__c = 'WF718540';
        Database.SaveResult srA = Database.insert(a);
        String accId = srA.getId();
        
        List<Contact> listOfCons = new List<Contact>();
        listOfCons.add(new Contact(FirstName = 'STest',Lastname = 'User',AccountId = accId,Email = 'stest@email.com'));
        listOfCons.add(new Contact(FirstName = 'ETest',Lastname = 'User',AccountId = accId,Email = 'etest@email.com'));
        
        List<Database.SaveResult> srCList = Database.insert(listOfCons);
        String conId1 = srCList[0].getId();
        String conId2 = srCList[1].getId();
        
        //Create user which has UPA created.
        User sUser = new User();
        
        sUser.Username = '2dhgm88oio@landolakes.com.ems.dev';
        sUser.Initial_password__c = 'welcome1';
        sUser.CommunityNickname = '2dhgm88oio';
        sUser.ProfileId = profileId;
        sUser.Email = 'stest@email.com';
        sUser.Phone = '9999999999';
        sUser.FirstName = 'STest';
        sUser.LastName = 'User';
        sUser.JobClassification__c = 'Farmer';
        sUser.seed__c = true;
        sUser.Grower__c = true;
        sUser.Alias = '2dhgm88oio'.substring(0,7);
        sUser.LocaleSidKey = 'en_US';
        sUser.EmailEncodingKey = 'UTF-8';
        sUser.LanguageLocaleKey = 'en_US';
        sUser.timezonesidkey = 'America/Los_Angeles';
        sUser.ContactId = conId1;
        sUser.isActive = true;
        sUser.IsMassLoaded__c = true;
        sUser.Ag2Ag_ID__c = 'stest01';
        sUser.Status__c = 'Provisioned';        
        
        //Create user which has no UPA created.
        User eUser = new User();        
        
        eUser.Username = '12oxkjl1iv@landolakes.com.ems.dev';
        eUser.Initial_password__c = 'welcome1';
        eUser.CommunityNickname = '12oxkjl1iv';
        eUser.ProfileId = profileId;
        eUser.Email = 'etest@email.com';
        eUser.Phone = '9999999999';
        eUser.FirstName = 'ETest';
        eUser.LastName = 'User';
        eUser.JobClassification__c = 'Farmer';
        eUser.seed__c = true;
        eUser.Grower__c = true;
        eUser.Alias = '12oxkjl1iv'.substring(0,7);
        eUser.LocaleSidKey = 'en_US';
        eUser.EmailEncodingKey = 'UTF-8';
        eUser.LanguageLocaleKey = 'en_US';
        eUser.timezonesidkey = 'America/Los_Angeles';
        eUser.ContactId = conId2;
        eUser.isActive = true;
        eUser.IsMassLoaded__c = true;
        eUser.Status__c = 'Provisioned';
        
        List<User> lUsers = new List<User>();
        lUsers.add(sUser);
        lUsers.add(eUser);
        
        List<Database.SaveResult> srList =  Database.insert(lUsers, dlo);   
        system.debug('=== sr list ===' + srList);
        String uId = srList[0].getId();
        
        UserProvAccount upa = new UserProvAccount();
        upa.SalesforceUserId = uId;
        upa.ExternalUserId = 'stes092';
        upa.LinkState = 'linked';
        upa.Status = 'Active';
        
        Database.insert(upa);
    }
    
    @isTest
    static void testEmailNotification(){
        EmailTemplate et = new EmailTemplate (developerName = 'Mass_New_Users_Email_Notification', folderId = UserInfo.getUserId(), TemplateType = 'Text', Name = 'Mass New Users Email Notification',
                                              body = 'Mass new users email notification email template.');
        Database.insert(et);
        
        NewUsersUploadEmailNotifyingBatch nuuenb = new NewUsersUploadEmailNotifyingBatch();       
        
        Test.startTest();
        Database.executeBatch(nuuenb);
        Test.stopTest();
    }
}