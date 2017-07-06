@isTest
public class NewUsersMassUploadValidateBatchTest {
    @testSetup static void testData() {
        //Create test accounts.
        List<Account> listOfAccs = new List<Account>();
        listOfAccs.add(new Account(Name = 'Test Winfield Account',Customer_Number__c = '123456',GUID__c = 'ZA703911'));
        listOfAccs.add(new Account(Name = 'Test Purina Account',Business_Unit_Key__c = 'FEED', AIMS_Number__c = '654321',GUID__c = 'YB716812'));
        listOfAccs.add(new Account(Name = 'Test Dairy Account',GUID__c = 'XC729713'));
        
        List<Database.SaveResult> srAList = Database.insert(listOfAccs);
    }
    
    @isTest
    static void testValidateBatch(){
        String profileId = [SELECT Id FROM Profile WHERE Name =: Constants.EMS_EXTERNAL_USER LIMIT 1].Id;
        List<NewUsersWrapper> nuwList = new List<NewUsersWrapper>();
        
        for(Account a : [Select id, Name, Business_Unit_Key__c, BillingState, Customer_Number__c, AIMS_Number__c, GUID__c from Account
                                 where Name in ('Test Winfield Account','Test Purina Account','Test Dairy Account')]){
            if(a.Name == 'Test Winfield Account')
                nuwList.add(new NewUsersWrapper(TestDataUtil.createUser(1,'test1@user1.com', 'bgf32yr834h',String.valueOf(a.Id),profileId),TestDataUtil.createContact(1,a.Id),a,'123654','','','',
                                            'MgrName1','mgr@email.com','1111111111','RetailerName1','RetailerCity1','RetailerState1'));
                                     
            if(a.Name == 'Test Purina Account')
                nuwList.add(new NewUsersWrapper(TestDataUtil.createUser(2,'test2@user2.com','ges67b2bojk',String.valueOf(a.Id),profileId),TestDataUtil.createContact(2,a.Id),a,'123654','','','',
                                            'MgrName2','mgr@email.com','2222222222','RetailerName2','RetailerCity2','RetailerState2'));
            if(a.Name == 'Test Dairy Account')
                nuwList.add(new NewUsersWrapper(TestDataUtil.createUser(3,'test3@landolakes.com','cvn34jsd234',String.valueOf(a.Id),profileId),TestDataUtil.createContact(3,a.Id),a,'123654','','','',
                                            'MgrName3','mgr@email.com','3333333333','RetailerName3','RetailerCity3','RetailerState3'));
        }
        
        NewUsersMassUploadValidateBatch numuvb = new NewUsersMassUploadValidateBatch(nuwList);
        
        Test.startTest();
        Database.executeBatch(numuvb);
        Test.stopTest();
    }
}