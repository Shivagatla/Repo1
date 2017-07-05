@isTest
private class EMSEmailVerificationCntrlTest {
    
    @isTest static void tetverification() {
        
        //set up user

        String userN = generateRandomString(4);

        Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company',GUID__c='Testing111'));
        insert partnerAccounts;
        //Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
        List<Contact> partnerContacts = new List<Contact>();
        partnerContacts.add(new Contact(AccountId = partnerAccounts[0].Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN));
        insert partnerContacts;
        List<User> newUsers = new List<User>();
        String hash=generateHash(userN+userN);
        User u = new User();
        u.Username = userN+'@landolakes.com.ems.testing';
        u.Email = userN+'@landolakes.com.ems.testing';
        u.FirstName = userN;
        u.LastName = userN;
        u.CommunityNickname = userN;
        u.Phone = '111-222-3333';
        u.ProfileId = profile.Id;
        u.Verify_Hash__c = hash;
        u.Alias = 'test01';
        u.ContactId = partnerContacts[0].Id;
        u.EmailEncodingKey = 'ISO-8859-1';
        u.IsActive = false;
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'America/New_York';

      insert u;
   
    
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {


      
        String uid = userN+'@landolakes.com.ems.testing';
        String email = userN+'@landolakes.com.ems.testing';
        PageReference pRef = Page.EMSVerification;
        pRef.getParameters().put('key', hash);
        pRef.getParameters().put('em',email);
        pRef.getParameters().put('uid',uid);
        Test.setCurrentPage(pRef);
        
        Test.startTest(); 
        
        EMSEmailVerificationCntrl pc = new EMSEmailVerificationCntrl();
        System.debug('Before run:'+pc.hasRun);
//          User[] users = [SELECT Id, Email,Email_Verified__c,FirstName,LastName FROM User WHERE Username=:uid and Email=:email LIMIT 1];
//       User user = users[0];
//       System.debug('Comparing: '+ hash + ' with: ' + generateHash(user.FirstName + user.LastName));
//       if (hash.equalsIgnoreCase(generateHash(user.FirstName + user.LastName)) && user != null){
//          user.Email_Verified__c = true;
//          update user;
//          System.debug('able to update user');
//      }
        pc.verify();
        System.debug('After run:'+pc.hasRun);
        System.assert(pc.hasRun);
        Test.stopTest();
    }
}

  public static String generateRandomString(Integer len) {
    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    String randStr = '';
    while (randStr.length() < len) {
       Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
       randStr += chars.substring(idx, idx+1);
    }
    return randStr; 
    }
    

     public static String generateHash(String string2Hash) {
    
        Blob targetBlob = Blob.valueOf(string2Hash);
        Blob hashSHA1 = Crypto.generateDigest('SHA1', targetBlob);
        // For Rackspace Compatiblity encode the binary into BASE 64
        // this will result in 28 chars long string 
        return base64URLencode (hashSHA1);    
    }

       public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }

    
}