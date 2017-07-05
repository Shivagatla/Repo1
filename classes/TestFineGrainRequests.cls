@isTest(SeeAllData=true)
private class   TestFineGrainRequests
{
    
  private static testmethod void testGetRequestFields()
  {
     Account parentAccount = createParentAccount();
     User parentUser = createUser(parentAccount,false);
     for (Account a:getChildrenAccounts(parentAccount)){
           createUser(a,false);
     }

    Test.startTest();

        AccountHierarchy ah = new AccountHierarchy(parentAccount,'Te',false);
        AccountHierarchy ah1 = new AccountHierarchy(parentAccount.Id,'Te',false);
        System.assert(ah.isChildAccount() == false);
        System.assert(ah1.isChildAccount() == false);
        System.assert(ah.getChildren(true).size()==2);
        System.assert(ah.getParentAndChildren(true).size()==2);
        System.assert(ah.getSelf().Name == 'Testing Communities Company');

        Application__c app = createApp('TestNV','No Validation',false);
        Application__c app2 = createApp('TestUSF','Use User Account Search Filter',true);
        ApplicationHelper appH = new ApplicationHelper('TestNV');
        ApplicationHelper appH2 = new ApplicationHelper('TestUSF',true);
         System.debug('Queue Name: '+appH.getQueueName());
        System.assert(appH.getQueueName()=='Customer_Support');
        System.assert(ApplicationHelper.getAppGUIDValue(app, parentAccount)=='testingaccountonly');
        System.assert(appH.getAppGUIDValue(parentAccount)=='testingaccountonly');
        //System.assert(appH.getFineGrainAccounts(parentUser.Id).size()==0);

        Application__c appNoTest = [SELECT Name,Connected_App_ID__c from Application__c LIMIT 1];
    
        System.runAs(parentUser){
            List<RequestField> rfs = ExternalRequestCntrl.prepopRequestFields(appNoTest.Id, parentUser.Id);
            List<AccountWrapper> acts = ExternalRequestCntrl.fetchAccountsForRequest(app.Id,parentUser.Id);
            System.assert(acts.get(0).Name == 'Testing Communities Company');
            ExternalRequestCntrl.submitRequest(appNoTest.Id,acts,rfs,'test',parentUser.Id);
            System.assert(acts.size()==1);
            
        
        }

        UserProvAccount upa = new UserProvAccount();
        upa.SalesforceUserId = parentUser.Id;
        upa.ConnectedAppId = appNoTest.Connected_App_ID__c;
        upa.ExternalEmail = 'StubAccount@foo.com';
        upa.ExternalUserId = 'test';
        upa.LinkState = 'Linked';
        insert upa;
       
        //ID jobID = System.enqueueJob(new EMSProvExtendObjectUtils(upa));
   
    
        test.stopTest();
    } 

    private static testmethod void testNewControllers(){
        
        UserProvisionEntitlement__c UPE = [Select UPA_Parent__r.ConnectedApp.Id
                                           from UserProvisionEntitlement__c LIMIT 1];

        PageReference pageRef = Page.CustomAccountLookup;

        Test.setCurrentPage(pageRef);
            // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('userId', UserInfo.getUserId());
        ApexPages.currentPage().getParameters().put('lksrch', 'FARM'); 
        ApexPages.currentPage().getParameters().put('appId', UPE.UPA_Parent__r.ConnectedApp.Id);    
 
        CustomAccountLookupController calc = new CustomAccountLookupController();
        calc.search();
        

        EMSApprovalsController appControl = new EMSApprovalsController();

        pageRef = Page.EMSUPRMainPage;
        Test.setCurrentPage(pageRef);
        UserProvisioningRequest upr = [SELECT Id,SalesforceUserId,ConnectedAppId,Operation from UserProvisioningRequest where operation <> null LIMIT 1];
        ApexPages.currentPage().getParameters().put('uprId', upr.Id);

        EMSUPRController emsupr = new EMSUPRController();
        emsupr.addtnComments = 'test';
        emsupr.saveComments();

        EMSUIMultiselectCntrl uimulti = new EMSUIMultiselectCntrl();



        pageRef = Page.EMSRequestModifyPopup;

        Test.setCurrentPage(pageRef);
            // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('userId', upr.SalesforceUserId);
        ApexPages.currentPage().getParameters().put('uprId', upr.Id); 
        ApexPages.currentPage().getParameters().put('appId', upr.ConnectedAppId);   
        ApexPages.currentPage().getParameters().put('mode', 'EDIT');  

        EMSRequestModificationPopup reqControl = new EMSRequestModificationPopup();
        reqControl.cancel();
        reqControl.updateRequest();

         ID jobID = System.enqueueJob(new StartFlowQueueable(upr));


    }


     @IsTest(SeeAllData=true) public static void testAppMenuItem() {
        EMSAppMenuItemCntl emsapp = new EMSAppMenuItemCntl();
     }

  private static testmethod void testFGApplicationhelper(){
    UserProvisionEntitlement__c UPE = [Select Related_SF_User__r.Id,Related_SF_User__r.Contact.ID,
                                           ParentApp__r.App_Code__c,ParentApp__r.Id,ParentApp__r.Group_Designation__c,ParentApp__r.Home_Page__c,ParentApp__r.Migrated__c,
                                           Related_SF_User__r.Ag2Ag_ID__c,Related_SF_User__r.Username,Related_SF_User__r.Email,UPA_Parent__r.ConnectedApp.Id
                                           from UserProvisionEntitlement__c LIMIT 1];
        String ag2ag = UPE.Related_SF_User__r.Ag2Ag_ID__c;
        String appcode = UPE.ParentApp__r.App_Code__c;
        ApplicationHelper ah = new ApplicationHelper(appcode,true);
        List<Account> accts = ah.getProvisionedFEnts(UPE.Related_SF_User__c);
        


  }

  private static testmethod void testGenericCase(){
    Account acct = createParentAccount();
    User u = createUser(acct,false);
    Test.startTest();
    String uprId;
    EMSCreateCase.createCase(u.ContactId,'This is a test','EMS_Provisioning','Need to fix the issue here.','EMSCustomer_Support',uprId);


    Test.stopTest();

  }
//************************testing web services


  static testMethod void testDoGetForFineGrain() {
        UserProvisionEntitlement__c UPE = [Select Related_SF_User__r.Id,Related_SF_User__r.Contact.ID,
                                           ParentApp__r.App_Code__c,ParentApp__r.Id,ParentApp__r.Group_Designation__c,ParentApp__r.Home_Page__c,ParentApp__r.Migrated__c,
                                           Related_SF_User__r.Ag2Ag_ID__c,Related_SF_User__r.Username,Related_SF_User__r.Email,UPA_Parent__r.ConnectedApp.Id
                                           from UserProvisionEntitlement__c LIMIT 1];
        String ag2ag = UPE.Related_SF_User__r.Ag2Ag_ID__c;
        String appcode = UPE.ParentApp__r.App_Code__c;
    

    RestRequest req = new RestRequest(); 
    RestResponse res = new RestResponse();

    req.requestURI = '/services/apexrest/ems/v1/user/'+ag2ag+'/app/'+appcode+'/fineents';  
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    UserFineEntService.ResponseContainer results = UserFineEntService.doGet();
     req.requestURI = '/services/apexrest/ems/v1/user/unknown/app/'+appcode+'/fineents';  
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    results = UserFineEntService.doGet();
     req.requestURI = '/services/apexrest/ems/v1/user//app/'+appcode+'/fineents';  
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    results = UserFineEntService.doGet();
        results = UserFineEntService.doGet();
     req.requestURI = '/services/apexrest/ems/v1/user/'+ag2ag+'/app//fineents';  
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    results = UserFineEntService.doGet();


  }

  static testMethod void testDoGetForUserEntitlementService() {
        UserProvisionEntitlement__c UPE = [Select Related_SF_User__r.Id,Related_SF_User__r.Contact.ID,
                                           ParentApp__r.App_Code__c,ParentApp__r.Id,ParentApp__r.Group_Designation__c,ParentApp__r.Home_Page__c,ParentApp__r.Migrated__c,
                                           Related_SF_User__r.Ag2Ag_ID__c,Related_SF_User__r.Username,Related_SF_User__r.Email,UPA_Parent__r.ConnectedApp.Id
                                           from UserProvisionEntitlement__c LIMIT 1];
        String ag2ag = UPE.Related_SF_User__r.Ag2Ag_ID__c;
        String appcode = UPE.ParentApp__r.App_Code__c;
    

    RestRequest req = new RestRequest(); 
    RestResponse res = new RestResponse();

    req.requestURI = '/services/apexrest/ems/v1/user/'+ag2ag+'/apps';  
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    UserEntitlementsService.ResponseContainer results = UserEntitlementsService.doGet();

    req.requestURI = '/services/apexrest/ems/v1/user//apps';  
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    results = UserEntitlementsService.doGet();
    


  }









//************** data operations

public static Account createParentAccount(){
        Account acct = new Account(Name = 'Testing Communities Company',GUID__c='testingaccountonly',PAES_Number__c='1231241111');
        insert acct;
        List<Account> partnerAccounts = new List<Account>();
        partnerAccounts.add(new Account(Name = 'Testing Communities Company Child 1',GUID__c='testingaccountonly1',PAES_Number__c='123141343141',ParentId=acct.Id));
        partnerAccounts.add(new Account(Name = 'Testing Communities Company Child 2',GUID__c='testingaccountonly2',PAES_Number__c='1234567899',ParentId=acct.Id));
        insert partnerAccounts;
        return acct;
    }


    public static List<Account> getChildrenAccounts(Account acct){
        return [SELECT Id,Name,GUID__C from Account where ParentId=:acct.id];
    }


     public static User createUser(Account acct, boolean delegate){
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
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz1234567890';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
   
   
    
    public static Id fetchConnectedAppId(boolean isMig) {
        List<Application__c> apps = [SELECT Connected_App_ID__c from Application__c where isDeleted =false and Migrated__c=:isMig ];
        Id cid;
        If(apps.size() > 0) {
            cid = apps.get(0).Connected_App_ID__c;
        }
        return cid;
    }

    public static Application__c createApp(String appName, String validation,boolean requireApproval){
        Application__c app =  new Application__c(name=appName,app_code__c=appName,Description__C='Test',FG_mgmt__c=true);
        app.FG_Filter_prefix__c = 'WF';
        app.FG_Search_Filter__c = 'No Validation';
        app.FG_Default_user_acct__c = true;
        app.Provisioning_Queue__c = 'Customer_Support';
        app.FG_Account_Field__c = 'GUID__c';
        app.FG_Max_Ents__c =5;
        app.Requires_Approval__c = requireApproval;
        app.ApproverType__c='Queue';
        app.Queue_Name__c = 'Customer_Support';
        app.Connected_App__c = false;
        insert app;
         Entitlements__c ent = new Entitlements__c(name='Test2',ent_code__c='testingupetrigger / user',parentapp__c=app.Id);
         insert ent;

        //create request fields
        Request_Field__c rf = new Request_Field__c(field_name__c='Manager_Name__c',field_label__c='Manager\'s Name',required__c=true,Save_to_object__c='Contct',Application__c=app.Id,Field_type__c='Text');
        insert rf;
        Request_Field__c rf2 = new Request_Field__c(field_name__c='Phone',field_label__c='Phone',required__c=true,Save_to_object__c='User',Application__c=app.Id,Field_type__c='Phone');
        insert rf2;
        return app;
    }
}