@isTest
private class GeneralEMSTest {
    
    @isTest static void testMainController() {
        EMSMainPageCntrl cntrl = new EMSMainPageCntrl();
        cntrl.redir();
    }
    @isTest static void tesCreateCaseCntrl() {
        Case c = new Case(
            Priority = 'Medium',
            Type='Review',
            Status = 'New'
        );
        Database.SaveResult sr = Database.insert(c);
        Case caseDb = [Select Id, Status from Case Where Id=: sr.getId()];
        caseDb.Status = 'Reviewed and Accepted';
        Database.update(caseDb);
    }
    /*@isTest static void tesCreateCaseCntrl2() {
        CreateCaseCntrl cntrl = new CreateCaseCntrl();
        cntrl.userID = generateRandomString(10);
        cntrl.createCase();
    }*/
    @isTest static void tesSetPasswordCntrl() {
        SetPasswordCntrl cntrl = new SetPasswordCntrl();
        User usr = [Select External_fed_Id__c from User where isActive=true LIMIT 1];
        cntrl.userID = usr.External_fed_Id__c;
        cntrl.newPassword = generateRandomString(8);
        cntrl.setPassword();
    }
    @isTest static void tesSetPasswordCntrl2() {
        SetPasswordCntrl cntrl = new SetPasswordCntrl();
        cntrl.userID = generateRandomString(10);
        cntrl.setPassword();
        cntrl.cancel();
    }
    @isTest static void testMainController2() {
        Map<ID, User> m = new Map<ID, User>([Select Id from User where isActive=true LIMIT 2]);
        EMSInactiveUser.inactivateUser(new List<Id>(m.keySet()));
    }
    
    @isTest static void testContants() {
        System.assert(EMSCOnstants.CREATUSER_ACT == 'CREATEUSER');
        System.assert(EMSCOnstants.UPDATECONTACT_ACT == 'UPDATECONTACt');
        System.assert(EMSCOnstants.CHANGEPASSWORD_ACT == 'CHANGEPASSWORD');
        System.assert(EMSCOnstants.DISABLEUSER_ACT == 'DISABLEUSER');
    }
    
    @isTest  static  void testGenerate(){
        String x = EMSUtils.generateRandomString(5);
        System.assert(x != null);
        System.assert(x.length()==5);
    }
    
    @IsTest(SeeAllData=true) public static void testEMSForgotPasswordController() {
        User u = createUser2(true);
        EMSForgotPasswordCntrl controller = new EMSForgotPasswordCntrl();
        controller.username = u.Username;
        controller.forgotPassword();
        EMSForgotPasswordCntrl.issueJWT('test@salesforce.com', 120);
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        EMSForgotPasswordCntrl.base64URLencode(bodyBlob);
        EMSForgotPasswordCntrl.sendEmail(u, u.Username);
    }
    
    @IsTest(SeeAllData=true) public static void testEMSRequestNonMigrated() {
        // Instantiate a new controller with all parameters in the page
        EMSRequest e = new EMSRequest();
        User u = createUser();
        e.requestedUser.Related_External_User__c = u.Id;
        e.connectedApp = fetchConnectedAppId(false);
        e.getUsers();
        e.showList();
        e.cancel();
        System.assertEquals(e.createRequest(),null);
    }
    
    @IsTest(SeeAllData=true) public static void testEMSRequestMigrated() {
        // Instantiate a new controller with all parameters in the page
        EMSRequest e = new EMSRequest();
        User u = createUser();
        insert u;
        e.requestedUser.Related_External_User__c = u.Id;
        e.connectedApp = fetchConnectedAppId(true);
        ApplicationHelper ah = new Applicationhelper(e.connectedApp);
        ah.getApplication();
        System.assertEquals(e.createRequest(),null);
    }
    
    
    @IsTest(SeeAllData=true) public static void testUPRSubmission() {
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            // Instantiate a new controller with all parameters in the page
            Test.startTest();
            EMSRequest e = new EMSRequest();
            User u = createUser();
            insert u;
            e.requestedUser.Related_External_User__c = u.Id;
            e.getItems();
            e.connectedApp = fetchConnectedAppId(true);
            ApplicationHelper ah = new Applicationhelper(e.connectedApp);
            e.createRequest();
            Test.stopTest();
        }
    }
    @IsTest(SeeAllData=true) public static void testBasePolicyAssignment() {
        // Instantiate a new controller with all parameters in the page
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            Test.startTest();
            EMSDefaultAssignCntrl e = new EMSDefaultAssignCntrl();
            User u = [SELECT Id, FirstName, LastName,username,External_fed_id__c FROM User WHERE isActive = true AND username like 'uprowner@landolakes.com.ems%' LIMIT 1];
            e.userIDforAssign = u.username;
            e.basePolicy = true;
            //e.assignEntitlements();            
        }
        Test.stopTest();
    }
    
    @IsTest(SeeAllData=true) public static void testPolicyAssignment() {
        // Instantiate a new controller with all parameters in the page
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            Test.startTest();
            EMSDefaultAssignCntrl e = new EMSDefaultAssignCntrl();
            User u = [SELECT Id, FirstName, LastName,username,External_fed_id__c FROM User WHERE isActive = true AND username like 'uprowner@landolakes.com.ems%' LIMIT 1];
            e.userIDforAssign = u.username;
            e.basePolicy = false;
            e.assignEntitlements();
        }
        Test.stopTest();
    }
    @IsTest private static void testAccountWrapper() {
        new AccountWrapper('Test','Test','Test');
    }
    
    private static User createUser(){
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
    
    private static User createUser2(boolean externalfedId){
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
        u.External_Fed_Id__c=u.Username;
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
    
    private static Id fetchConnectedAppId(boolean isMig) {
        List<Application__c> apps = [SELECT Connected_App_ID__c from Application__c where isDeleted =false and Migrated__c=:isMig ];
        Id cid;
        If(apps.size() > 0) {
            cid = apps.get(0).Connected_App_ID__c;
        }
        return cid;
    }
}