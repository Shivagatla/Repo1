public class EMSCallout{
    @future(callout = true)
    public static void sendCases(Set<Id> cObjIds){
        List<Case> caseList = [select id, Contact.Account.Name, Contact.Account.Customer_Number__c, Contact.Account.BillingCity, 
            Contact.Account.BillingState, Related_External_User__r.Name, Related_External_User__r.Phone, 
            Related_External_User__r.Email, Related_External_User__r.Ag2Ag_ID__c, Contact.Name, Status, Origin, CaseNumber, Description, 
            Priority, Ag_Tech_Agreement__c from Case where Id =: cObjIds];
        
        if(!caseList.isEmpty() && !Test.isRunningTest())
            SendCasesToCRMCtrl.sendCasesList(caseList);
    }
}