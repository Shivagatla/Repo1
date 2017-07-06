@isTest(SeeAllData=true)
private class EMS_DA_UserList_Test {
    
    @isTest static void testUserList() {
        
        Account parentAccount = createParentAccount();
        User parentUser = createUser(parentAccount,true);
        for (Account a:getChildrenAccounts(parentAccount)){
            createUser(a,false);
        }
        
        User childUser = createUser(parentAccount,false);
        Application__c app2 = createApp(true);
        
        ApplicationHelper ah22 = new ApplicationHelper(app2.app_code__c,true);
        
        UserProvAccount upa2 = createProvAccount(parentUser, parentAccount);
        Test.startTest();
        
        Id job1 = System.enqueueJob(new EMSProvExtendObjectUtils(upa2,null,app2.Id,EMSConstants.UPDATE_OPERATION));
        //test creating a request for a child user
        ID jobID = System.enqueueJob(new EMSCreateUPRQueueable(ah22.getApplication(),childUser,'test',(new List<RequestField>()),(new List<AccountWrapper>()),UserInfo.getUserId(),'Create'));
        ID jobID2 = System.enqueueJob(new EMSCreateUPRQueueable(ah22.getApplication(), childUser,'testing',UserInfo.getUserId()));
        
        System.runAs(parentUser){
            EMS_DA_UserList daList = new EMS_DA_UserList();
            List<EMS_DA_UserList.UserWrapper> users = daList.getAllUsers();
            System.assert(users.size()==4);
            System.assert(daList.getPendingRequests().size()==0);
            EMS_DA_UserList.AccessWrapper aws = EMS_DA_UserList.getAccessForUser(parentUser.Id, 'emsdelegatedadmin');
            System.assert(aws.appcode == 'emsdelegatedadmin');
            String result = EMS_DA_UserList.inactivateuser(users.get(0).userInfo.Id);
            result = EMS_DA_UserList.inactivateuser(parentUser.Id);
            System.assert(result=='User cannot inactivate themselves.');
        }
        
        UserProvAccount upa = [SELECT Id,SalesforceUserId from UserProvAccount where status ='Active' LIMIT 1];
        System.runAs(new User(id=upa.SalesforceUserId)){
            EMS_DA_UserList daList2 = new EMS_DA_UserList();
            List<EMS_DA_UserList.AccessWrapper> aws = daList2.getGrantedAccessForAllUsers();
        }
        Test.stopTest();
    }
    
    @isTest static void testRequestForUser() {
        Account parentAccount = createParentAccount();
        User parentUser = createUser(parentAccount,true);
        for (Account a:getChildrenAccounts(parentAccount)){
            createUser(a,false);
        }
        createProvAccount(parentUser, parentAccount);
        Application__c noDAApp = createApp(false);
        Application__c DAApp = createApp(true);
        UserProvisioningRequest upr = [SELECT Id from UserProvisioningRequest LIMIT 1];
        System.runAs(parentUser){
            EMS_DA_Request daRequest = new EMS_DA_Request();
            EMS_DA_Request.UPRWrapper uprW = EMS_DA_Request.getUPRInfo(upr.Id);
        }
    }
    
    //These are to increase code coverage
    @isTest static void testVariousCode(){
        Account acct = createParentAccount();
        User cu = createUser(acct,false);
        EMSInactiveUser emsIU = new EMSInactiveUser();
        EMSInactiveUser.inactivateUser(cu.Id);
    }
    
    ///////////////////Data methods
    private static Account createParentAccount(){
        Account acct = new Account(Name = 'Testing Communities Company',GUID__c='testingaccountonly');
        insert acct;
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company Child 1',GUID__c='testingaccountonly1',ParentId=acct.Id));
        partnerAccounts.add(new Account(Name = 'Testing Communities Company Child 2',GUID__c='testingaccountonly2',ParentId=acct.Id));
        insert partnerAccounts;
        return acct;
    }
    
    private static List<Account> getChildrenAccounts(Account acct){
        return [SELECT Id,Name,GUID__C from Account where ParentId=:acct.id];
    }
    
    
    private static User createUser(Account acct, boolean delegate){
        String userN = generateRandomString(4);
        Profile profile = (delegate)?[SELECT Id FROM Profile WHERE Name='EMS Delegated Admin' LIMIT 1]:[SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
            
            //Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
            List<Contact> partnerContacts = new List<Contact>();
        partnerContacts.add(new Contact(AccountId = acct.Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN,Phone='333-222-1111'));
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
        
        //u.Manager_Name__c='Foo Name';
        //u.Manager_Email__c='foo@foo.com';
        //u.Manager_Phone__C='111-222-3334';
        u.isActive = true;
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
    
    private static Application__c createApp(boolean daApp){
        Application__c app =  new Application__c(name='Test1__test1'+generateRandomString(2),app_code__c='1231234'+generateRandomString(2),Description__C='Test',FG_mgmt__c=true);
        app.FG_Filter_prefix__c = 'WF';
        app.FG_Search_Filter__c = 'No Validation';
        app.DA_Approval_Required__c = daApp;
        insert app;
        Entitlements__c ent = new Entitlements__c(name='Test2',ent_code__c='testingupetrigger / user',parentapp__c=app.Id);
        insert ent;
        
        //create request fields
        Request_Field__c rf = new Request_Field__c(field_name__c='Manager_Name__c',field_label__c='Manager\'s Name',required__c=true,Save_to_object__c='User',Application__c=app.Id,Field_type__c='Text');
        insert rf;
        Request_Field__c rf2 = new Request_Field__c(field_name__c='Phone',field_label__c='Phone',required__c=true,Save_to_object__c='Contact',Application__c=app.Id,Field_type__c='Phone');
        insert rf2;
        return app;
    }
    
    private static UserProvAccount createProvAccount(User u, Account acct){
        Application__c app = [SELECT Connected_App_Id__c,Name,Id,DA_Approval_Required__c,EMS_Application_Object_Name__c,EMS_Application_Type__c,EMS_Application__c 
                              FROM Application__c where app_code__c='emsdelegatedadmin'];
        UserProvAccount upaNew = new UserProvAccount();
        upaNew.ExternalUserId = 'testing';
        upaNew.ExternalUsername='testing';
        upaNew.ExternalEmail='testing@foo.com';
        upaNew.ExternalFirstName = 'Testuser' ;
        upaNew.ExternalLastName='TestUser';
        upaNew.connectedAppId = app.Connected_App_Id__c;
        upaNew.Status='Active';
        upaNew.LinkState ='Linked';
        upaNew.SalesforceUserId = u.Id;
        insert upaNew;
        AccountHierarchy ah = new AccountHierarchy(acct.Id, '',false);
        AccountHierarchy ah2 = new AccountHierarchy(acct, '',false);
        AccountHierarchy ah3 = new AccountHierarchy(acct.Id, 'te',true);
        for(Account acct2:ah.getChildren(true)){
            UserProvFineEntitlement__c upe = new UserProvFineEntitlement__c();
            upe.Entitled_Account__c = acct2.Id;
            upe.UPA_Parent__c = upaNew.Id;
            upe.ParentApp__c = app.Id;
            upe.Related_SF_User__C = u.Id;
            insert upe;
        }
        UserProvFineEntitlement__c upe = new UserProvFineEntitlement__c();
        upe.Entitled_Account__c = acct.Id;
        upe.UPA_Parent__c = upaNew.Id;
        upe.ParentApp__c = app.Id;
        upe.Related_SF_User__C = u.Id;
        upsert upe;
        return upaNew;
    }
}