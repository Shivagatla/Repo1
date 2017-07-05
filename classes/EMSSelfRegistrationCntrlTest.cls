@isTest(SeeAllData=true)
private class EMSSelfRegistrationCntrlTest {
    @isTest static void test1() {
        EMSSelfRegistrationCntrl ems = new EMSSelfRegistrationCntrl();
        
        ems.email = 'abcd@test.com';
        ems.password = 'p@55word';
        ems.confirmPassword = 'p@55word';
        ems.primaryPhone = '(545) 454-5545';
        ems.jobClassification = 'Farmer';
        ems.firstName = 'Test';
        ems.lastName = 'User';
        ems.isAgThAgreement=true;
        
        Test.startTest();
        Account acc = [SELECT Name,BillingCity,BillingState FROM Account WHERE Name != null LIMIT 1];
        ems.accountNumber = '56755464';
        ems.retailerName = acc.Name;
        ems.retailerCity = acc.BillingCity;
        ems.retailerState = acc.BillingState;
        
        ems.registerUser();
        Test.stopTest();
    }
    
    @isTest static void test2() {
        EMSSelfRegistrationCntrl ems = new EMSSelfRegistrationCntrl();
        
        ems.email = 'abcd2@test2.com';
        ems.password = 'p2@55word';
        ems.confirmPassword = 'p2@55word';
        ems.primaryPhone = '(545) 454-5545';
        ems.jobClassification = 'Farmer';
        ems.firstName = 'Test2';
        ems.lastName = 'User2';
        ems.managerEmail = 'manager2@test2.com';
        ems.managerName = 'Ma User2';
        ems.managerPhone = '(545) 454-5545';
        ems.isWinfield = true;
        
        Test.startTest();
        Account acc = [SELECT Name,Customer_Number__c FROM Account WHERE Customer_Number__c != null LIMIT 1];
        ems.retailerNumber = acc.Customer_Number__c;
        ems.registerUser();
        Test.stopTest();
    }
    
    @isTest static void test3() {
        EMSSelfRegistrationCntrl ems = new EMSSelfRegistrationCntrl();
        
        ems.email = 'abcd3@test3.com';
        ems.password = 'p3@55word';
        ems.confirmPassword = 'p3@55word';
        ems.primaryPhone = '(545) 454-5545';
        ems.jobClassification = 'Retailer Sales';
        ems.firstName = 'Test3';
        ems.lastName = 'User3';
        
        Test.startTest();        
        Account acc = [SELECT Name,AIMS_Number__c FROM Account WHERE AIMS_Number__c != null LIMIT 1];
        ems.accountNumber = acc.AIMS_Number__c;
        ems.company = acc.Name;
        ems.getCustomSettings();
        ems.getBRDesc();
        ems.getItems();
        ems.registerUser();
        Test.stopTest();
    }
    
    @isTest static void test4() {
        EMSSelfRegistrationCntrl ems = new EMSSelfRegistrationCntrl();
        
        ems.email = 'abcd33@test33.com';
        ems.password = 'p33@55word';
        ems.confirmPassword = 'p33@55word';
        ems.primaryPhone = '(545) 454-5545';
        ems.jobClassification = 'Retailer Sales';
        ems.firstName = 'Test33';
        ems.lastName = 'User33';
        
        Test.startTest();        
        Account acc = [SELECT Name FROM Account WHERE Name != null LIMIT 1];
        ems.company = acc.Name;
        
        ems.registerUser();
        Test.stopTest();
    }
    
    @isTest static void test5() {
        EMSSelfRegistrationCntrl ems = new EMSSelfRegistrationCntrl();
        
        ems.email = 'abcd4@test4.com';
        ems.password = 'p4@55word';
        ems.confirmPassword = 'p4@55word';
        ems.primaryPhone = '(545) 454-5545';
        ems.jobClassification = 'Retailer Sales';
        ems.firstName = 'Test4';
        ems.lastName = 'User4';
        
        Test.startTest();
        Account acc = [SELECT Farm_ID__c FROM Account WHERE Farm_ID__c != null LIMIT 1];
        ems.farmId = acc.Farm_ID__c;
        ems.registerUser();
        
        Test.stopTest();
    }
    @isTest static void test6(){
        EMSSelfRegistrationCntrl ems = new EMSSelfRegistrationCntrl();
        
        ems.firstName = 'testuserfname';
        ems.lastName = 'testuserlname';
        ems.email = 'abcd@test.com';
        ems.primaryPhone = '(545) 454-5545';
        ems.jobClassification = 'Reporting';
        ems.brand1 = true;
        ems.brand2 = true;
        ems.brand3 = true;        
        ems.password ='p@55word';
        ems.confirmPassword ='p@55word';

        Test.startTest();
        Account acc = [SELECT Name,BillingCity,BillingState FROM Account WHERE Name != null LIMIT 1];
        
        ems.fgiCompany = acc.Name;
        ems.fgiCompanyCity = acc.BillingCity;
        ems.fgiCompanyState = acc.BillingState;
        ems.registerUser();
        
        EMSSelfRegistrationCntrl.doesUserExist('test@landolakes.com');
        EMSSelfRegistrationCntrl.doesUserExist('abcd@test.com');
        ems.cancel();
        
        Test.stopTest();
    }

     @isTest static void test7(){
         EMSSelfRegistrationCntrl ems = new EMSSelfRegistrationCntrl();
         
         ems.email = 'abcd5@test5.com';
         ems.password = 'p5@55word';
         ems.confirmPassword = 'p5@55word';
         ems.primaryPhone = '(545) 454-5545';
         ems.jobClassification = 'Marketing';
         ems.firstName = 'Test5';
         ems.lastName = 'User5';
         
         Test.startTest();
         Account acc = [SELECT Name,BillingCity,BillingState FROM Account WHERE Name != null LIMIT 1];
         ems.fgiLicensee = acc.Name;
         ems.fgiLicenseeCity = acc.BillingCity;
         ems.fgiLicenseeState = acc.BillingState;
         
         ems.registerUser();
         Test.stopTest();

    }
}