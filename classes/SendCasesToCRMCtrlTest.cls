@isTest
public class SendCasesToCRMCtrlTest{
    @testSetup static void setup() {
        RecordType accRT = [select id from RecordType where SobjectType = 'Account' LIMIT 1];
        RecordType caseRT = [select id from RecordType where SobjectType = 'Case' AND Name = 'New Customer Registration' LIMIT 1];
        
        CalloutSettings__c callout = new CalloutSettings__c();
        callout.Name = 'Focus';
        callout.Salesforce_Instance__c = 'https://focus--RGDev.cs43.my.salesforce.com';
        callout.Customer_Key__c = '3MVG9GnaLrwG9TQQUTjvaYOEKdnK0njgXFIMq8DXtPwZYG.VONq5efDUReFWR0vNpSZ.0zSdST_dhuhsgEyup';
        callout.Customer_Secret_Key__c = '6582018088481538566';
        callout.Username__c = 'dhruv.singh%40sf.winfield.rgdev';
        callout.Password__c = 'winfieldzif5yrqfhpiBwkYNpJFvKMzuk';
        insert callout;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
        User u = [Select id from User where ProfileId =: p.Id AND JobClassification__c = 'Farmer' LIMIT 1];
                
        Account acc = new Account();
        acc.Name = 'test account';
        acc.GUID__c = 'testaccount';
        acc.RecordTypeId = accRT.Id;
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'test';
        con.LastName = 'contact';
        con.AccountId = acc.Id;
        con.Related_External_User__c = u.Id;       
        insert con;      
        
        List<case> lCases = new List<case>{new case(RecordTypeId = caseRT.Id, ContactId = con.Id, Related_External_User__c = u.Id, Status = 'New', Subject = 'New Case for Test Class 1'),
            new case(RecordTypeId = caseRT.Id, ContactId = con.Id, Related_External_User__c = u.Id, Status = 'New', Subject = 'New Case for Test Class 2')};
        insert lCases;
    }
    
    @isTest static void testSyncCasesToCRM() {
        List<case> listOfcases = [select id, Contact.Account.Name, Contact.Account.Customer_Number__c, Contact.Account.BillingCity, 
            Contact.Account.BillingState, Related_External_User__r.Name, Related_External_User__r.Phone, 
            Related_External_User__r.Email, Related_External_User__r.Ag2Ag_ID__c, Contact.Name, Status, Origin, CaseNumber, Description, 
            Priority, Ag_Tech_Agreement__c from case where subject like 'New Case for Test Class%'];
                
        for(case c : listOfcases){
            c.status = 'Reviewed and Accepted';
        }
        
        update listOfcases;  
        
        Contact con = [select id, Ag2Ag_ID__c from contact where name like 'test%' limit 1];
        con.Ag2Ag_ID__c = 'test012';
        
        update con;               
        
        String jsonStr = '{{'+
                '"access_token":"00D630000008o4i!AQkAQBFgR_I5lF58UW6lC.UoYiP0nRsA2RVto5kTwG._pTokDFrklemAlyIgRR3mKoqm9P2ciNav1QJqZcLcwaWrXsfTDjzI",'+
                '"instance_url":"https://focus--RGDev.cs43.my.salesforce.com",'+
                '"id":"https://test.salesforce.com/id/00D630000008o4iEAA/00563000000T1f9AAC",'+
                '"token_type":"Bearer",'+
                '"issued_at":"1469511541846",'+
                '"signature":"467OwTpGWn9ZnYKhmswA8LeOqHV/q6QfpJO9CeF40LU="'+
                '}}';
        
        SendCasesToCRMCtrl.oauth = jsonStr;
        String result = SendCasesToCRMCtrl.sendCasesList(listOfcases);
        System.assertEquals('Success', result);
    }
}