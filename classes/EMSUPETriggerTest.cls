@isTest
private class EMSUPETriggerTest
{

	private class WebServiceMockImpl implements WebServiceMock 
	{
		public void doInvoke(
			Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName,
			String responseNS, String responseName, String responseType) 
		{
			if(request instanceof MetadataService.retrieve_element)
				response.put('response_x', new MetadataService.retrieveResponse_element());
		
            else if(request instanceof  MetadataService.createMetadata_element)
                response.put('response_x', new MetadataService.createMetadataResponse_element());
       
			return;
		}
	}    


	@isTest
	static void testTrigger()
	{



		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		Test.startTest();
		Application__c app = new Application__c(name='Testing UPE Traigger', App_Code__c='testingupetrigger');
		insert app;
		 List<Entitlements__c> ents = new List<Entitlements__c>();
		 Entitlements__c ent = new Entitlements__c(name='Test2',ent_code__c='testingupetrigger / user',parentapp__c=app.Id);
		  ents.add(ent);
        insert ents;
        User u = createUser();
        insert u;
        User u2 = [SELECT Id from User where id=:u.Id LIMIT 1];
        UserProvAccount upa = new UserprovAccount();
        upa.ConnectedAppId = app.Connected_App_Id__c;
        upa.SalesforceUserId = u2.Id;
        System.debug('setting the user id:' + u2.Id);
        upa.Status = 'Active';
        upa.LinkState = 'Linked';
        upa.ExternalUserId = u.username;
        insert upa;

        UserProvisionEntitlement__c upe = new UserProvisionEntitlement__c();
        upe.UPA_Parent__c = upa.Id;
        upe.entitlement_code__c = ent.Id;
        insert upe;
        Test.stopTest();
        UserProvisionEntitlement__c upe2 = [select Id, ParentApp__c,Related_Sf_User__c, UPA_Parent__r.SalesforceUserId from UserProvisionEntitlement__c where Id=:upe.Id limit 1];
        System.debug('app id:' +upe2.ParentApp__c);
        System.debug('user is: ' + upe2.UPA_Parent__r.SalesforceUserId);
        System.assert(upe2.ParentApp__c == null);
        System.assert(upe2.Related_Sf_User__c == null);



	}




	public static User createUser(){
		String userN = generateRandomString(4);

		Profile profile = [SELECT Id FROM Profile WHERE Name='EMS External User' LIMIT 1];
		List<Account> partnerAccounts = new List<Account>();
		partnerAccounts.add(new Account(Name = 'Testing Communities Company'+userN,GUID__c='testingaccountonly'+userN));
		insert partnerAccounts;
		//Create some Contacts because we want to create portal users we are required to provide a corresponding contactId
		List<Contact> partnerContacts = new List<Contact>();
		partnerContacts.add(new Contact(AccountId = partnerAccounts[0].Id, Email = userN+'@landolakes.com.ems.testing', FirstName = userN, LastName = userN));
		insert partnerContacts;

		User u = new User();
        u.Username = userN+'@landolakes.com.ems.testing';
        u.Email = userN+'@landolakes.com.ems.testing';
        u.FirstName = userN;
        u.LastName = userN;
        u.CommunityNickname = userN;
        u.Phone = '111-222-3333';
        u.ProfileId = profile.Id;
        //u.Verify_Hash__c = generateHash(userN+userN);
        u.Alias = 'test01';
        u.ContactId = partnerContacts[0].Id;
        u.EmailEncodingKey = 'ISO-8859-1';
        u.IsActive = false;
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'America/New_York';
        u.External_Fed_Id__c=userN;


        return u;

	}

		 public static String generateRandomString(Integer len) {
	    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz1234567890';
	    String randStr = '';
	    while (randStr.length() < len) {
	       Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
	       randStr += chars.substring(idx, idx+1);
	    }
	    return randStr; 
    }
}