trigger SetInitialUPAStatus on UserProvAccount (before insert, before update) {

	for (UserProvAccount so : Trigger.new) {
		if (so.ExternalEmail == 'StubAccount@foo.com'){
			so.Status='Deactivated';
			so.ExternalEmail = [SELECT Email from User where Id=:so.SalesforceuserId].Email;
		}
		
	}

}