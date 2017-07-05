@isTest(seeAllData=true)
public class NewUsersMassUploadCtrlTest {
    @isTest
    static void testMassUploadCtrl(){
        String string2Hash = 'string to Hash';
        String recId = [SELECT Id FROM RecordType WHERE Name = 'Corporate' AND SobjectType = 'Account' limit 1].Id;
        //Create test accounts.
        List<Account> listOfAccs = new List<Account>();
        listOfAccs.add(new Account(Name = 'Test Winfield Account',Customer_Number__c = '123456',GUID__c = 'ZA703911',billingCity = 'Test City',billingState = 'Test State'));
        listOfAccs.add(new Account(Name = 'Test Purina Account',Business_Unit_Key__c = 'FEED', AIMS_Number__c = '654321',GUID__c = 'YB716812'));
        listOfAccs.add(new Account(Name = 'Test Dairy Account',GUID__c = 'XC729713'));
        listOfAccs.add(new Account(Name = 'Test Corporate Account',Farm_ID__c = '123120',PAES_Number__c = '654321',GUID__c = 'WD732614',recordTypeId = recId));
        
        List<Database.SaveResult> srAList = Database.insert(listOfAccs);
        
        String csvData = 'FirstName,LastName,Email,Phone,Job,MgrName,MgrEmail,MgrPhone,RetailerName,RetailerCity,RetailerState,IsWinfield,RetailerNo,IsPurina,AccountNo,IsCorporate,FarmOrCoopName,IsDairy,CompanyName,IsMassLoad,Status'+Constants.NEWLINE;
        
        csvData = csvData + 'wTest1,User1,test1@user1.com,1111111111,Farmer,MgrName1,MgrEmail1,MgrPhone1,RetailerName1,RetailerState1,RetailerState1,TRUE,123456,FALSE,12,FALSE,12,FALSE,12,TRUE,Validated,'+Constants.NEWLINE;
        csvData = csvData + 'pTest2,User2,test2@user2.com,2222222222,Accounting,,,,,,,FALSE,12,TRUE,654321,FALSE,12,FALSE,12,TRUE,Validated,'+Constants.NEWLINE;
        csvData = csvData + 'Test,User,test@user.com,3333333333,Farmer,,,,,,,FALSE,123654,FALSE,12,FALSE,12,FALSE,12,TRUE,Validated,'+Constants.NEWLINE;
        csvData = csvData + 'dTest4,User4,test4@user4.com,4444444444,Farmer,,,,,,,FALSE,12,FALSE,12,FALSE,12,TRUE,Test Dairy Account,TRUE,Validated,'+Constants.NEWLINE;
        csvData = csvData + 'cTest5,User5,test5@user5.com,5555555555,Farmer,,,,,,,,,,,TRUE,654321,FALSE,12,TRUE,Validated,'+Constants.NEWLINE;
        csvData = csvData + 'cTest6,User6,test6@user6.com,6666666666,Farmer,,,,Test Winfield Account,Test City,Test State,TRUE,456,,,,,,,TRUE,Validated,'+Constants.NEWLINE;
        csvData = csvData + 'cTest7,User7,test7@user7.com,7777777777,Farmer,m,m@m.com,9999999999,,,,FALSE,12,TRUE,123120,TRUE,654321,FALSE,12,TRUE,Validated,'+Constants.NEWLINE;
        csvData = csvData + ',User8,test8@user8.com,8888888888,Farmer,,,,,,,FALSE,,FALSE,45,FALSE,44,FALSE,12,TRUE,Validated,'+Constants.NEWLINE;
        
        Blob bFile = Blob.valueOf(csvData);
        
        NewUsersMassUploadCtrl numuc = new NewUsersMassUploadCtrl();
        numuc.csvFileBodyImportNew = bFile;
        numuc.contentTypeImportNew = '.csv';
        numuc.fileSizeImportNew = 8933;
        
        numuc.doValidateAndUpload();
        numuc.doMassProvisioning();
        numuc.doMassEmailing();
        numuc.createEmailBody();
        
        //Covering MassUploadUtil class code coverage.
        MassUploadUtil utilObj = new MassUploadUtil();
        
        utilObj.uploadingFalied();
        utilObj.generateHash(string2Hash);
        
        //Covering Constant class code coverage.
        Constants c = new Constants();
    }
}