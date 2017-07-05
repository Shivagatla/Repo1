@isTest
public class EMSEmailNotificationPageCtrlTest {
	@testSetup static void testData() {
        String profileId = [SELECT Id FROM Profile WHERE Name =: Constants.EMS_EXTERNAL_USER LIMIT 1].Id;
        String recTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grower_Agreement' AND IsActive = true AND SobjectType = 'Agreement__c'].Id;
        
        //Create a pdf Ag Tech Agreement document.
        Document document = new Document();
        document.Body = Blob.valueOf('Ag Tech Agreement document');
        document.ContentType = 'application/pdf';
        document.DeveloperName = 'Test_Ag_Tech_Agreement';
        document.IsPublic = true;
        document.Name = 'Test Ag Tech Agreement';
        document.FolderId = UserInfo.getUserId();
        insert document;
        
        //Create a custom settings.
        List<Environment_Record_Ids__c> envList = new List<Environment_Record_Ids__c>();
        envList.add(new Environment_Record_Ids__c(Name = 'Agreement Grower Record Type', Record_Id__c = recTypeId));
        envList.add(new Environment_Record_Ids__c(Name = 'Agreement Document Id', Record_Id__c = document.Id));        
        Database.insert(envList);
        
        //Create test account.
        Account a = new Account();
        a.Name = 'Test Account';
        a.Customer_Number__c = '7303726';
        a.GUID__c = 'WF718540';
        Database.SaveResult srA = Database.insert(a);
        String accId = srA.getId();
        
        //Create grower test contact.
        Contact newUserContactG = new Contact(
            FirstName = 'TestG',
            Lastname = 'User',
            AccountId = accId,
            Email = 'testg@email.com'
        );
        
        Database.SaveResult srC = Database.insert(newUserContactG);
        
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail = false;
        
        //Create grower test user.
        User newUserG = new User();        
        
        newUserG.Username = '9fgxm90ouw@landolakes.com.ems.dev';
        newUserG.Initial_password__c = 'welcome1';
        newUserG.CommunityNickname = '9fgxm90ouw';
        newUserG.ProfileId = profileId;
        newUserG.Email = 'testg@email.com';
        newUserG.Phone = '9999999999';
        newUserG.FirstName = 'TestG';
        newUserG.LastName = 'User';
        newUserG.JobClassification__c = 'Farmer';
        newUserG.seed__c = true;
        newUserG.Grower__c = true;
        newUserG.Alias = '9fgxm90ouw'.substring(0,7);
        newUserG.LocaleSidKey = 'en_US';
        newUserG.EmailEncodingKey = 'UTF-8';
        newUserG.LanguageLocaleKey = 'en_US';
        newUserG.timezonesidkey = 'America/Los_Angeles';
        newUserG.ContactId = srC.getId();
        
        Database.saveresult srU = Database.insert(newUserG, dlo);
    }
    
    @isTest
    static void testPasswordAndAgTechAgreement(){
        List<User> uList = [Select id, Username from User where Username = '9fgxm90ouw@landolakes.com.ems.dev'];
        system.debug('=== UList ===' + uList);
        String keyToken = EMSForgotPasswordCntrl.issueJWT(uList[0].username, 1800);
        
        PageReference pageRef = Page.EMSEmailNotificationPage;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('key', keyToken);
        
        EMSEmailNotificationPageCtrl eenp = new EMSEmailNotificationPageCtrl();
        eenp.password = 'Wel@12345';
        eenp.confirmPassword = 'Wel@12345';
        eenp.submit();
        
        eenp.isAgThAgreement = false;
        eenp.subject = '';
        eenp.submit();
    }
}