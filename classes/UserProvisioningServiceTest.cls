@isTest(SeeAllData=true)
private class UserProvisioningServiceTest {
    
    static testMethod void testCreateUser() {
        
        Test.setMock(HttpCalloutMock.class, new UserProvisioningServiceTest.MockHttpResponseGenerator());
        
        
        UserProvisioningService svc = new UserProvisioningService();
        String firstName = 'Alex';
        String lastName = 'Smith';
        String email = EMSUtils.generateRandomString(10) + '@identigral.com';
        String company = 'Identigral';
        String division = 'Winfield';
        String password = 'Welcome1!';
        String phone = '111-222-2222';
        String state = 'MN';
        String aimsNumber = '123566';
        try {
            String ag2agID = svc.createUser(password,firstName,lastName,email,phone,company,division,'Broker',aimsNumber,state);
            //(String password,String firstName, String lastName, String email,String phone, String company,String division,String userType) {
        }
        catch (Exception e) {
            //System.assert(false,'Failed to generate Ag2Ag ID : ' + e.getMessage());
        }
    }
    
    @isTest static void testImportCSVNewError3() {
        Test.setMock(HttpCalloutMock.class, new UserProvisioningServiceTest.MockHttpResponseGenerator());
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,Entitlement_Code__r.Id,Entitlement_Code__r.AD_Group__c,Entitlement_Code__r.Ad_Group_Optional__c,
                                           Entitlement_Code__r.Name,Related_SF_User__r.Id,Related_SF_User__r.Contact.ID,
                                           ParentApp__r.App_Code__c,ParentApp__r.Use_AD_Role_Name__c,ParentApp__r.Id,ParentApp__r.Group_Designation__c,ParentApp__r.Home_Page__c,ParentApp__r.Migrated__c,
                                           Related_SF_User__r.Ag2Ag_ID__c,Related_SF_User__r.Username,Related_SF_User__r.Email,UPA_Parent__r.ConnectedApp.Id
                                           from UserProvisionEntitlement__c LIMIT 1];
        String conId = UPE.Related_SF_User__r.Contact.ID;
        UserProvisioningService svc = new UserProvisioningService();
        svc.entitleUser(UPE.Related_SF_User__r, UPE.ParentApp__r, new Set<Entitlements__c>{UPE.Entitlement_Code__r}, 'reason');
        svc.entitleUser(UPE.Related_SF_User__r, UPE.ParentApp__r, new Set<Entitlements__c>{UPE.Entitlement_Code__r});
        svc.modifyUserEntitlementsByAction(UPE.Related_SF_User__r, UPE.ParentApp__r, new Set<Entitlements__c>{UPE.Entitlement_Code__r}, 'reason','action');
        svc.modifyUserAccess(UPE.Related_SF_User__r, UPE.ParentApp__r, new Set<Entitlements__c>{UPE.Entitlement_Code__r}, 'reason');
        svc.disableUserAccess(UPE.Related_SF_User__r, UPE.ParentApp__r, new Set<Entitlements__c>{UPE.Entitlement_Code__r}, 'reason');
        svc.changePassword(UPE.Related_SF_User__r, 'changePassword');
        Contact con = [Select Related_External_User__r.BYOID__c,Lastname,FirstName,Email,Phone from Contact where Id=: conId];
        svc.changeContact(UPE.Related_SF_User__r.Ag2Ag_ID__c, con);
        svc.findUser(UPE.Related_SF_User__r.Email);
        svc.disableUser(UPE.Related_SF_User__r);
        UserHelper.updateUserEmailVerification(UPE.Related_SF_User__r.Username, true);
    }
    
    class MockHttpResponseGenerator implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint and method.
            // System.assertEquals('http://api.salesforce.com/foo/bar', req.getEndpoint());
            //System.assertEquals('POST', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(200);
            return res;
        }
    }
}