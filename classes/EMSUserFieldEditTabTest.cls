@isTest
private class EMSUserFieldEditTabTest {	
    @IsTest(SeeAllData=true) 
    public static void testSave() {
    	User u = createuser();
    	insert u;
    	PageReference pageRef = Page.EMSUserFieldEditTab;

    	Test.setCurrentPage(pageRef);
        
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('sfdc.userId', u.Id);   
    	EMSUserFieldEditTab controller = new EMSUserFieldEditTab();
    	
    	System.assert(controller.getIsEdit() == false);
    	controller.edit();
    	System.assert(controller.getIsEdit() == true);
    	controller.cancel();
    	System.assert(controller.getIsEdit() == false);
        
        controller.getItems();
        controller.save();        
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