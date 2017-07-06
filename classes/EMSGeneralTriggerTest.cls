@isTest
private class EMSGeneralTriggerTest {
	
	@isTest static void testApplicationTrigger() {
		Test.startTest();
		Application__c app =  new Application__c(name='Test1__test1',app_code__c='123123',Description__C='Test');
        insert app;
        Test.stopTest();

	}
	
	@isTest(SeeAllData=true) static void testCartEntitlementTrigger() {
		Test.startTest();
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
        upr.SalesforceUserId = [SELECT ID from user where isActive = true LIMIT 1].Id;
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
		Test.stopTest();

		
	}
	
}