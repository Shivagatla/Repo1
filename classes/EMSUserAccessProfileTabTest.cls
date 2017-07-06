@isTest
private class EMSUserAccessProfileTabTest {

	
	  @IsTest(SeeAllData=true) 
    public static void testSave() {

    	User u = createuser();
    	insert u;
    	PageReference pageRef = Page.EMSUserAccessProfileTab;

    	Test.setCurrentPage(pageRef);
    	    // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('sfdc.userId', u.Id);   
    	EMSUserAccessProfileTabCntrl controller = new EMSUserAccessProfileTabCntrl();
      

     	Test.startTest();
    	
    	System.assert(controller.getCurrentUser()==u.Id);
  		Application__c app =  new Application__c(name='Test1__test1',app_code__c='123123',Description__C='Test');
        insert app;
         Entitlements__c ent = new Entitlements__c(name='Test2',ent_code__c='testingupetrigger / user',parentapp__c=app.Id);
         insert ent;
		UserProvisioningRequest upr = new UserProvisioningRequest();

            upr.ExternalUserId = 'test111';
            upr.ApprovalStatus = 'NotRequired';
            //upr.ConnectedAppId = [SELECT Id from AppMenuItem LIMIT 1].Id;
            upr.AppName = app.Name;
            upr.Application__c = app.Id;
            upr.Operation ='Create';
            upr.State='New';
            upr.SalesforceUserId = u.Id;
    		insert upr;
		Cart_Application__c capp = new Cart_Application__c();
    		capp.UPR_Number__c = upr.Id;
    		capp.Catalog_App__c = app.Id;
    		insert capp;

		Cart_Entitlement__c cent = new Cart_Entitlement__C();
    		cent.RelatedUPR__c = upr.Id;
    		cent.ent_code__c = ent.Id;
    		cent.Parent_app__c = capp.Id;
            cEnt.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_CG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;
    		insert cent;
        


        Cart_Entitlement__c cEnt2 = new Cart_Entitlement__c();
            cEnt2.Account__c = [SELECT Contact.Account.Id from User where Id=:u.Id].Contact.Account.Id;
            cEnt2.Parent_App__c = capp.Id;
            cEnt2.RelatedUPR__c = upr.Id;
            cEnt2.RecordTypeId = [select Id from RecordType where DeveloperName = :EMSConstants.CART_FG_RT and SobjectType = 'Cart_Entitlement__c' LIMIT 1].Id;      
            insert cEnt2;

    

    	List<CatalogWrapper> cwList = controller.getPendingRequests();

    	for(CatalogWrapper cw:cwList){
    		EMSUserAccessProfileTabCntrl.cancelRequest(cw.requestName);
    	}


    	for(CatalogWrapper cw:cwList){
    		EMSUserAccessProfileTabCntrl.deleteRequest(cw.requestName);
    	}

    	Test.stopTest();
    	
    	

    }



@isTest(seeallData=true)
public static void testPopups(){
 	User u = createuser();
    	insert u;
    	PageReference pageRef = Page.EMSRequestModifyPopup;

    	Test.setCurrentPage(pageRef);
    	    // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('userId', u.Id);   
    	
      

     	Test.startTest();
    	
    	
  		Application__c app =  new Application__c(name='Test1__test1',app_code__c='123123',Description__C='Test');
        insert app;
        ApplicationHelper ah = new ApplicationHelper(app);
         Entitlements__c ent = new Entitlements__c(name='Test2',ent_code__c='testingupetrigger / user',parentapp__c=app.Id);
         insert ent;
		UserProvisioningRequest upr = new UserProvisioningRequest();

        upr.ExternalUserId = 'test111';
        upr.ApprovalStatus = 'NotRequired';
        upr.ConnectedAppId = ah.getApplication().Connected_App_ID__c;
        upr.AppName = app.Name;
        upr.Application__c = app.Id;
        upr.Operation ='Create';
        upr.State='New';
        upr.SalesforceUserId = u.Id;
		insert upr;
		Cart_Application__c capp = new Cart_Application__c();
		capp.UPR_Number__c = upr.Id;
		capp.Catalog_App__c = app.Id;
		insert capp;

		Cart_Entitlement__c cent = new Cart_Entitlement__C();
		cent.RelatedUPR__c = upr.Id;
		cent.ent_code__c = ent.Id;
		//cent.Parent_app__c = capp.Id;
		insert cent;

		ApexPages.currentPage().getParameters().put('appId', app.Name); 
		ModifyAccessPopupCntrl controller = new ModifyAccessPopupCntrl();
		System.assert(controller.userForRequest.Id ==u.Id);
		controller.submitRequest();
		controller.cancel();

}

@isTest(seeallData=true)
public static void testDeletePopups(){
    User u = createuser();
        insert u;
        PageReference pageRef = Page.RemoveAccessPopup;

        Test.setCurrentPage(pageRef);
            // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('userId', u.Id);   
        
      

        Test.startTest();
        
        
        Application__c app =  new Application__c(name='Test1__test1',app_code__c='123123',Description__C='Test');
        insert app;
        ApplicationHelper ah = new ApplicationHelper(app);
         Entitlements__c ent = new Entitlements__c(name='Test2',ent_code__c='testingupetrigger / user',parentapp__c=app.Id);
         insert ent;
        UserProvisioningRequest upr = new UserProvisioningRequest();

        upr.ExternalUserId = 'test111';
        upr.ApprovalStatus = 'NotRequired';
        upr.ConnectedAppId = ah.getApplication().Connected_App_ID__c;
        upr.AppName = app.Name;
        upr.Application__c = app.Id;
        upr.Operation ='Create';
        upr.State='New';
        upr.SalesforceUserId = u.Id;
        insert upr;
        Cart_Application__c capp = new Cart_Application__c();
        capp.UPR_Number__c = upr.Id;
        capp.Catalog_App__c = app.Id;
        insert capp;

        Cart_Entitlement__c cent = new Cart_Entitlement__C();
        cent.RelatedUPR__c = upr.Id;
        cent.ent_code__c = ent.Id;
        //cent.Parent_app__c = capp.Id;
        insert cent;

        ApexPages.currentPage().getParameters().put('appId', app.Name); 
        RemoveAccessPopupCntrl controller = new RemoveAccessPopupCntrl();
        System.assert(controller.userForRequest.Id ==u.Id);
        controller.submitRequest();
        controller.cancel();

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
	
   public static Id fetchConnectedAppId(boolean isMig) {
        List<Application__c> apps = [SELECT Connected_App_ID__c from Application__c where isDeleted =false and Migrated__c=:isMig ];
        Id cid;
        If(apps.size() > 0) {
            cid = apps.get(0).Connected_App_ID__c;
        }
        return cid;
    }
	
}