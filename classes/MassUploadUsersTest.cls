@isTest(SeeAllData=true)
private class MassUploadUsersTest {
    @isTest static void testImportCSV() {
        MassUploadUsers controller = new MassUploadUsers();
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,ParentApp__r.App_Code__c,Related_SF_User__r.Ag2Ag_ID__c from UserProvisionEntitlement__c LIMIT 1];
        String csvString = 'ID,Application,Entitlement\n'+UPE.Related_SF_User__r.Ag2Ag_ID__c+','+UPE.ParentApp__r.App_Code__c+','+UPE.Entitlement_Code__r.Ent_Code__c;
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImport = blobForImport;
        controller.contentTypeImport = 'TestFile.csv';
        controller.fileSizeImport = 1;
        controller.importCSVFile();
    }
    
    @isTest static void testImportCSV11() {
        MassUploadUsers controller = new MassUploadUsers();
        List<UserProvisionEntitlement__c> UPE = [Select Entitlement_Code__r.Ent_Code__c,ParentApp__r.App_Code__c,Related_SF_User__r.Ag2Ag_ID__c from UserProvisionEntitlement__c LIMIT 10];
        String csvString = 'ID,Application,Entitlement\n'
            +UPE.get(0).Related_SF_User__r.Ag2Ag_ID__c+','+UPE.get(0).ParentApp__r.App_Code__c+','+UPE.get(0).Entitlement_Code__r.Ent_Code__c+'\n'
            +getUniqueName()+','+getUniqueName()+','+getUniqueName()+'\n'
            +UPE.get(0).Related_SF_User__r.Ag2Ag_ID__c+','+UPE.get(2).ParentApp__r.App_Code__c+','+UPE.get(3).Entitlement_Code__r.Ent_Code__c+'\n'
            +UPE.get(0).Related_SF_User__r.Ag2Ag_ID__c+','+UPE.get(0).ParentApp__r.App_Code__c+','+UPE.get(3).Entitlement_Code__r.Ent_Code__c+'\n';
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImport = blobForImport;
        controller.contentTypeImport = 'TestFile.csv';
        controller.fileSizeImport = 1;
        controller.importCSVFile();
    }
    
    @isTest static void testImportCSVError1() {
        MassUploadUsers controller = new MassUploadUsers();
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,ParentApp__r.App_Code__c,Related_SF_User__r.Ag2Ag_ID__c from UserProvisionEntitlement__c LIMIT 1];
        String csvString = 'ID,Application,Entitlement\n'+UPE.Related_SF_User__r.Ag2Ag_ID__c+','+UPE.ParentApp__r.App_Code__c+','+UPE.Entitlement_Code__r.Ent_Code__c;
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImport = blobForImport;
        controller.contentTypeImport = 'TestFile.csv';
        controller.fileSizeImport = 0;
        controller.importCSVFile();
    }
    
    @isTest static void testImportCSVError2() {
        MassUploadUsers controller = new MassUploadUsers();
        String csvString = 'ID,Application,Entitlement';
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImport = blobForImport;
        controller.contentTypeImport = 'TestFile.csv';
        controller.fileSizeImport = 1;
        controller.importCSVFile();
    }
    
    @isTest static void testImportCSVError3() {
        MassUploadUsers controller = new MassUploadUsers();
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,ParentApp__r.App_Code__c,Related_SF_User__r.Ag2Ag_ID__c from UserProvisionEntitlement__c LIMIT 1];
        String csvString = 'ID,Application,Entitlement\n'+UPE.Related_SF_User__r.Ag2Ag_ID__c+','+UPE.ParentApp__r.App_Code__c+','+UPE.Entitlement_Code__r.Ent_Code__c+',HUH';
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImport = blobForImport;
        controller.contentTypeImport = 'TestFile.csv';
        controller.fileSizeImport = 1;
        controller.importCSVFile();
    }
    
    @isTest static void testImportCSVError4() {
        MassUploadUsers controller = new MassUploadUsers();
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,ParentApp__r.App_Code__c,Related_SF_User__r.Ag2Ag_ID__c from UserProvisionEntitlement__c LIMIT 1];
        String csvString = 'ID,Application,Entitlement\n'+' '+','+UPE.ParentApp__r.App_Code__c+','+UPE.Entitlement_Code__r.Ent_Code__c;
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImport = blobForImport;
        controller.contentTypeImport = 'TestFile.csv';
        controller.fileSizeImport = 1;
        controller.importCSVFile();
    }
    
    @isTest static void testImportCSVNew() {
        MassUploadUsers controller = new MassUploadUsers();
        String csvString = 'FirstName,LastName,email,PhoneNbr,AccountNbr,MgrAg2AgID,Business Unit,job\n'
            +getUniqueName()+','+getUniqueName()+',test@test.com,1231231231,pendingregistrations-SFonly,,Winfield,Retailer Sales';
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImportNew = blobForImport;
        controller.contentTypeImportNew = 'TestFile.csv';
        controller.fileSizeImportNew = 1;
    }
    
    @isTest static void testImportCSVNewError1() {
        MassUploadUsers controller = new MassUploadUsers();
        UserProvisionEntitlement__c UPE = [Select ParentApp__r.App_Code__c,Related_SF_User__r.Ag2Ag_ID__c from UserProvisionEntitlement__c where UPA_Parent__c != null LIMIT 1];
        String csvString = 'Id,Application\n'+UPE.Related_SF_User__r.Ag2Ag_ID__c+','+UPE.ParentApp__r.App_Code__c;
        Blob blobForImport = Blob.valueof(csvString);
        controller.csvFileBodyImportDelete = blobForImport;
        controller.contentTypeImportDelete = 'TestFile.csv';
        controller.fileSizeImportDelete = 1;
        controller.importDeleteAccessCSVFile();
    }
    
    @isTest static void testImportCSVNewError2() {
        MassUploadUsers controller = new MassUploadUsers();
        Blob blobForImport = Blob.valueof('Id,Application\n');
        controller.csvFileBodyImportDelete = blobForImport;
        controller.contentTypeImportDelete = null;
        controller.fileSizeImportDelete = 1;
        controller.importDeleteAccessCSVFile();
    }
    
    @isTest static void testImportCSVNewError3() {
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,Entitlement_Code__r.Id,
                                           ParentApp__r.App_Code__c,ParentApp__r.Id,
                                           Related_SF_User__r.Ag2Ag_ID__c,Related_SF_User__r.Username,
                                           Related_SF_User__r.Email,Related_SF_User__r.Firstname,Related_SF_User__r.Lastname,
                                           UPA_Parent__r.ConnectedApp.Id
                                           from UserProvisionEntitlement__c LIMIT 1];
        MassUploadInsertOnlySuccesses controller = new MassUploadInsertOnlySuccesses();
        controller.insertRecords(new List<PayLoadUser>{new PayLoadUser(new Payload(UPE.Related_SF_User__r.Ag2Ag_ID__c, UPE.ParentApp__r.App_Code__c,
                                                                                   1,'Migrated', 'Huh', new List<String>{'CN=GG_Portal_FD_Prdcr_Dev,OU=PortalDev,OU=Applications'},
                                                                                   UPE.Entitlement_Code__r.Ent_Code__c),String.valueOf(UPE.UPA_Parent__r.ConnectedApp.Id),
                                                                       String.valueOf(UPE.Related_SF_User__r.Id),String.valueOf(UPE.Related_SF_User__r.Username),
                                                                       String.valueOf(UPE.Entitlement_Code__r.Id),String.valueOf(UPE.ParentApp__r.Id),
                                                                       UPE.Related_SF_User__r.Email,UPE.Related_SF_User__r.Firstname,UPE.Related_SF_User__r.Lastname)});
    }
    
    private static String getUniqueName() {
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        String orgId = UserInfo.getOrganizationId();
        Integer randomInt = Integer.valueOf(math.round(math.random() * 1000000));
        return orgId + dateString + randomInt;
    }
    
    @isTest static void myUnitTest() {
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,Entitlement_Code__r.AD_Group__c,
                                           ParentApp__r.App_Code__c,ParentApp__r.Home_Page__c,ParentApp__r.Migrated__c,
                                           Related_SF_User__r.Ag2Ag_ID__c from UserProvisionEntitlement__c LIMIT 1];
        Integer IsDefaultHomePage = Boolean.valueOf(UPE.ParentApp__r.Home_Page__c) ? 1 : 0;
        String ApplicationMigrationStatus = Boolean.valueOf(UPE.ParentApp__r.Migrated__c) ? 'Migrated' : 'NonMigrated';
        Payload pl = new Payload(UPE.Related_SF_User__r.Ag2Ag_ID__c,UPE.ParentApp__r.App_Code__c,IsDefaultHomePage,ApplicationMigrationStatus,'Test Class'
                                 ,new List<String>{UPE.Entitlement_Code__r.AD_Group__c},UPE.Entitlement_Code__r.Ent_Code__c.substringAfter('/').trim());
        MassUploadDeleteAccessBatch.ExcelRow ER = new MassUploadDeleteAccessBatch.ExcelRow(pl, 'Message');
        Map<String,String> fields = new Map<String,String>();
        fields.put('Key', 'value');
        MassUploadDeleteAccessBatch.PayloadDelete pd = new MassUploadDeleteAccessBatch.PayloadDelete(
            UPE.Related_SF_User__r.Ag2Ag_ID__c,UPE.ParentApp__r.App_Code__c,
            ApplicationMigrationStatus,
            new List<String>{UPE.Entitlement_Code__r.AD_Group__c},
            new List<String>{UPE.Entitlement_Code__r.Ent_Code__c.substringAfter('/').trim()}
        );
        MassUploadDeleteAccessBatch mdb = new MassUploadDeleteAccessBatch(new List<Payload>{pl}, fields);
        mdb.errorList = new Set<MassUploadDeleteAccessBatch.ExcelRow> {ER};
            mdb.successList = new Set<Payload>{pl};
                Database.executeBatch(mdb, 10);   
    }
    
    @isTest static void myUnitTest2() {
        UserProvisionEntitlement__c UPE = [Select Entitlement_Code__r.Ent_Code__c,Entitlement_Code__r.AD_Group__c,Entitlement_Code__r.Id,
                                           ParentApp__r.App_Code__c,ParentApp__r.Home_Page__c,ParentApp__r.Migrated__c,ParentApp__r.Connected_App_ID__c,ParentApp__r.Id,
                                           Related_SF_User__r.email,Related_SF_User__r.firstname,Related_SF_User__r.lastname,Related_SF_User__r.Ag2Ag_ID__c,
                                           Related_SF_User__r.id,Related_SF_User__r.username from UserProvisionEntitlement__c LIMIT 1];
        Integer IsDefaultHomePage = Boolean.valueOf(UPE.ParentApp__r.Home_Page__c) ? 1 : 0;
        String ApplicationMigrationStatus = Boolean.valueOf(UPE.ParentApp__r.Migrated__c) ? 'Migrated' : 'NonMigrated';
        Payload pl = new Payload(UPE.Related_SF_User__r.Ag2Ag_ID__c,UPE.ParentApp__r.App_Code__c,IsDefaultHomePage,ApplicationMigrationStatus,'Test Class'
                                 ,new List<String>{UPE.Entitlement_Code__r.AD_Group__c},UPE.Entitlement_Code__r.Ent_Code__c.substringAfter('/').trim());
        PayLoadUser pu = new PayLoadUser(pl,UPE.ParentApp__r.Connected_App_ID__c,UPE.Related_SF_User__r.Id,UPE.Related_SF_User__r.username,
                                        UPE.Entitlement_Code__r.Id,UPE.ParentApp__r.Id,UPE.Related_SF_User__r.email,UPE.Related_SF_User__r.firstname,UPE.Related_SF_User__r.lastname);
        
        MassUploadUsersBatch.ExcelRow ER = new MassUploadUsersBatch.ExcelRow(pu, 'Message');
        MassUploadUsersBatch mdb = new MassUploadUsersBatch(new List<PayLoadUser>{pu});
        mdb.errorList = new List<MassUploadUsersBatch.ExcelRow> {ER};
        mdb.successList = new List<PayLoadUser>{pu};
        Database.executeBatch(mdb, 10);   
    }
}