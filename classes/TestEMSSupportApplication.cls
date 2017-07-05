@isTest
private class TestEMSSupportApplication{


  
    public static testMethod void testSetPassword() {
        User user1 = new User();
        // Instantiate a new controller with all parameters in the page 
        ApexPages.StandardController sc2 = new ApexPages.StandardController(user1);
       
        EMSSupportApplication controller = new EMSSupportApplication(sc2);

        User newuser = createUser();
        insert newuser;

        controller.userID= newuser.External_Fed_Id__c;
        controller.newPassword= 'NewPassword123';
        Test.startTest();
     
           
        controller.setPassword();
        System.assertEquals('',controller.userId);
              
        Test.stopTest();
       }
       
   public static testMethod void testCancel() {
   
       
        User user1 = new User();
        // Instantiate a new controller with all parameters in the page 
        ApexPages.StandardController sc2 = new ApexPages.StandardController(user1);
        EMSSupportApplication controller = new EMSSupportApplication(sc2);
        
        Test.startTest();
        try{
            controller.cancel(); 
            System.assertEquals('1','1');   
        }
        catch(Exception e){
        System.assertEquals('1','0');   
        }

    }
public static User createUser(){
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
        u.External_Fed_Id__c=userN;

        return u;

    }

     public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz1234567890';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
 
}