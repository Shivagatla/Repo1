@isTest
private class CatalogWrapperTest {
	

	
	@isTest
    public static void testMe() {

        CatalogWrapper cw = new CatalogWrapper();
        System.assertEquals(cw.checked,false);
        List<Entitlements__c> ents = new List<Entitlements__c>();
        List<Entitlements__c> provents = new List<Entitlements__c>();
        Application__c app =  new Application__c(name='Test1__test1',app_code__c='123123',Description__C='Test');
        insert app;
        ents.add(new Entitlements__c(name='User',ent_code__c='test1__test1 / user',parentapp__c=app.Id));
        ents.add(new Entitlements__c(name='Test3',ent_code__c='test1__test1 / test3',parentapp__c=app.Id));
        provents.add(new Entitlements__c(name='Test1',ent_code__c='test1__test1 / Test1',parentapp__c=app.Id));
        insert ents;
        insert provents;
        CatalogWrapper cw2 = new CatalogWrapper(app,ents,provents);
        CatalogWrapper cw1 = new CatalogWrapper(app,ents);
        System.assertEquals(cw2.getAppName(),'Test1__test1');
        System.assertEquals(cw2.ents[0].name,'User');
        System.assertEquals(cw2.getAppDescription(),'Test');
        System.assertEquals(cw2.checked,false);
        System.assertEquals(cw1.getAppName(),'Test1__test1');
        System.assertEquals(cw1.ents[0].name,'User');
        System.assertEquals(cw1.getAppDescription(),'Test');
        System.assertEquals(cw1.checked,false);
        System.assert(cw2.getEntOptions().size()>0);
        System.assertEquals('',cw2.getReason());
        System.assert(cw2.getRoleDisplay().contains('Test3'));
        System.assert(cw2.getApp().Name == 'Test1__test1');
        System.assert(cw2.getSelectedEnt() == null);
        System.assert(cw2.isChecked() == false);



    }


    @isTest
    public static void testNegate() {

        CatalogWrapper cw = new CatalogWrapper();
        System.assertEquals(cw.checked,false);
        List<Entitlements__c> ents = new List<Entitlements__c>();
        List<Entitlements__c> provents = new List<Entitlements__c>();
        Application__c app =  new Application__c(name='Test1__test1',app_code__c='123123',Description__C='Test');
        insert app;
        ents.add(new Entitlements__c(name='User',ent_code__c='test1__test1 / user',parentapp__c=app.Id));
        ents.add(new Entitlements__c(name='Test3',ent_code__c='test1__test1 / test3',parentapp__c=app.Id));
        //provents.add(new Entitlements__c(name='Test1',ent_code__c='test1__test1 / Test1',parentapp__c=app.Id));
        insert ents;
        insert provents;
        CatalogWrapper cw2 = new CatalogWrapper(app,ents,provents);
        CatalogWrapper cw1 = new CatalogWrapper(app,ents);
        System.assertEquals(cw2.getAppName(),'Test1__test1');
        System.assertEquals(cw2.ents[0].name,'User');
        System.assertEquals(cw2.getAppDescription(),'Test');
        System.assertEquals(cw2.checked,false);
        System.assertEquals(cw1.getAppName(),'Test1__test1');
        System.assertEquals(cw1.ents[0].name,'User');
        System.assertEquals(cw1.getAppDescription(),'Test');
        System.assertEquals(cw1.checked,false);
        System.assert(cw2.getEntOptions().size()==0);
        System.assertEquals('',cw2.getReason());

    }

	
}