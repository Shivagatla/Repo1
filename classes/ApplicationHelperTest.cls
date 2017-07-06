@isTest
private class ApplicationHelperTest {
    @isTest static void testDataRetrieval() {
        Application__c app = createApplication('Test App1010');
        insert app;
        Application__c app2 = createApplication('Test App1001');
        insert app2;
        ApplicationHelper ah = new ApplicationHelper(app.Name);
        Test.startTest();
        System.assert(ah.getName() == 'Test App1010');
        System.assertEquals(ah.needsApproval(),false);
        Test.stopTest();
        ApplicationHelper ah2 = new ApplicationHelper(app.Id);
        
        System.assert(ah2.getName() == '');
        System.assertEquals(ah2.needsApproval(),false);
        
        ApplicationHelper ah3 = new ApplicationHelper(app);
        
        System.assert(ah3.getName() == 'Test App1010');
        System.assertEquals(ah3.needsApproval(),false);
        System.assert(ah3.getQueueName() == 'test');
        System.assert(ah3.isApproverUser() == false);
        System.assert(ah3.isApproverQueue() == true);        
    }
    
    @isTest static void testAppCreation() {
        Test.startTest();
        Application__c app = createApplication('Test App1010');
        insert app;
        List<Application__c> apps1 = new List<Application__c>();
        apps1.add(app);
        ID jobID = System.enqueueJob(new ConnectAppQueueable(apps1, UserInfo.getSessionId()));
        Test.stopTest();
        List<AppmenuItem> apps = [SELECt Id, Label from AppMenuItem where Name=:app.App_code__c];
        
        System.assert(apps.size()==0);
    }
    
    @isTest static void testUserFunctions() {
        Application__c app = createApplication('Test App1010');
        insert app;
        String userN = generateRandomString(4);
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company',GUID__c='testingaccountonly'));
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
        // Implement test code
        
        ApplicationHelper ah = new ApplicationHelper();
        
        System.assertEquals(ah.getProvisionedApps(u.Id).size(),0);
        System.assert(ah.getAvailableSFApps(u.Id).size()>0);
        System.assert(ah.getAvailableSFAppsAsCataLogWrapper(u.Id).size() >0);
        System.assert(ah.getProvisionedAppsAsCataLogWrapper(u.Id).size() ==0);
    }
    
    @IsTest(SeeAllData=true)  static void testUPAFunctions(){
        
        Test.startTest();
        Application__c app = new Application__c(name='Testing UPE Traigger', App_Code__c='testingupetrigger');
        insert app;
        List<Entitlements__c> ents = new List<Entitlements__c>();
        Entitlements__c ent = new Entitlements__c(name='Test2',ent_code__c='testingupetrigger / user',parentapp__c=app.Id);
        ents.add(ent);
        insert ents;
        User u = createUser();
        insert u;
        User u2 = [SELECT Id from User where id=:u.Id LIMIT 1];
        UserProvAccount upa = new UserprovAccount();
        upa.ConnectedAppId = app.Connected_App_Id__c;
        upa.SalesforceUserId = u2.Id;
        System.debug('setting the user id:' + u2.Id);
        upa.Status = 'Active';
        upa.LinkState = 'Linked';
        upa.ExternalUserId = u.username;
        insert upa;
        
        UserProvisionEntitlement__c upe = new UserProvisionEntitlement__c();
        upe.UPA_Parent__c = upa.Id;
        upe.entitlement_code__c = ent.Id;
        insert upe;
        
        ApplicationHelper ah = new ApplicationHelper(app.Connected_App_Id__c);
        ah.getAvailableSFApps(u2.Id);
        ah.getAvailableSFApps(u2.Id);
        ah.getProvisionedApps(u2.Id);
        ah.getAvailableSFAppsAsCataLogWrapper(u2.Id);
        Test.stopTest();
        //System.assert(ah.getAvailableSFApps(u2.Id).size()>0);
        //System.assert(ah.getProvisionedApps(u2.Id).size()==1);
        //System.assert(ah.getAvailableSFAppsAsCataLogWrapper(u2.Id).size()>0);
        //System.assert(ah.getProvisionedAppsAsCataLogWrapper(u2.Id).size()>0);
        ah.getProvisionedAppsAsCataLogWrapper(u2.Id,false);
        ah.getProvisionedAppsEntsAsCataLogWrapper(u2.Id,false);
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
    
    
    // Use: Application__c varApplication = UnitTestDataFactory.createApplication();
    private static Application__c createApplication(String nameIn)
    {
        return new Application__c(
            // Id							= '',
            // OwnerId						= '',
            // IsDeleted					= '',
            Name							= nameIn,
            // CreatedDate					= '',
            // CreatedById					= '',
            // LastModifiedDate				= '',
            // LastModifiedById				= '',
            // SystemModstamp				= '',
            // LastActivityDate				= '',
            App_Code__c					= '22'+nameIn,
            // App_Portal_URL__c			= '',
            // App_URL__c					= '',
            // Approver__c					= '',
            // Connected_App_ID__c			= '',
            // Connected_App__c				= '',
            // Description__c				= '',
            // Group_Designation__c			= '',
            // Home_Page__c					= '',
            // Internal_Group__c			= '',
            Requires_Approval__c			= false,
            Migrated__c					= false,
            System_Application__c		= false,
            ApproverType__c				= 'QUEUE',
            Queue_Name__c				= 'test'
            // Provisioning_Queue__c		= '',
            // Base_Access__c				= ''
        );
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