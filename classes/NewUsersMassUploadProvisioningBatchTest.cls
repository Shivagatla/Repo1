@istest(seealldata=true)
public class NewUsersMassUploadProvisioningBatchTest {
    @isTest
    static void testMassProvisioning(){
        String profileId = [SELECT Id FROM Profile WHERE Name =: Constants.EMS_EXTERNAL_USER LIMIT 1].Id;
        
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail = false;
        
        //Create test accounts.
        List<Account> listOfAcc = new List<Account>();
        listOfAcc.add(new Account(Name = 'Test Account1',Customer_Number__c = '7000026',GUID__c = 'WF008522'));
        listOfAcc.add(new Account(Name = 'Test Account2',Customer_Number__c = '7334719',GUID__c = 'WFP78047'));
        
        List<Database.SaveResult> srAList = Database.insert(listOfAcc);
        String accId1 = srAList[0].getId();
        String accId2 = srAList[1].getId();
        
        List<Contact> listOfCons = new List<Contact>();
        listOfCons.add(new Contact(FirstName = 'STest',Lastname = 'User',AccountId = accId1,Email = 'stest@email.com'));
        listOfCons.add(new Contact(FirstName = 'ETest',Lastname = 'User',AccountId = accId2,Email = 'etest@email.com'));
        
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
        sUser.Status__c = 'Validated';        
        
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
        eUser.Status__c = 'Validated';
        
        List<User> lUsers = new List<User>();
        lUsers.add(sUser);
        lUsers.add(eUser);
        
        List<Database.SaveResult> srList =  Database.insert(lUsers, dlo);
        
        NewUsersMassUploadProvisioningBatch numupb = new NewUsersMassUploadProvisioningBatch();
        
        Test.startTest();
        Database.executeBatch(numupb);
        Test.stopTest();
    }
}