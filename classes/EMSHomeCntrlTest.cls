@isTest(SeeAllData=true)
private class EMSHomeCntrlTest {
    @isTest static void test1() {
        UserProvisioningRequest upr = [SELECT ConnectedAppId,SalesforceUserId FROM UserProvisioningRequest WHERE State != 'Completed' and State != 'Failed'].get(0);
        List<UserProvAccount> granted = [SELECT ConnectedAppId FROM UserProvAccount WHERE SalesforceUserId = :upr.SalesforceUserId AND Status != 'Deactivated'];
            if(!granted.isEmpty()) {
                User u3 = [SELECT Id FROM User WHERE Id =: upr.SalesforceUserId];
                System.runAs(u3) {
                    EMSHomeCntrl cntrl2 = new EMSHomeCntrl();
                }   
            }
    }
    
    @isTest static void test2() {
        EMSHomeCntrl cntrl2 = new EMSHomeCntrl();
        cntrl2.redir();
        cntrl2.requestAccess();
    }
}