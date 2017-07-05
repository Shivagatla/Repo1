trigger EMSInitialUserAssignmentTrigger on User ( after update) {
	System.debug('About to determine if secondary apps need to be provisioned.');

	for (User so : Trigger.new) {
		if (Trigger.oldMap.get( so.Id ).Ag2Ag_Id__C == null && Trigger.newMap.get( so.Id ).Ag2Ag_Id__c <> null && Trigger.newMap.get( so.Id ).Ag2Ag_Id__c.length() > 1){
		
			System.debug(LoggingLevel.DEBUG,'The user has baseline access.  Starting to do secondary access.');
			
			EMSEntitlementAssignment.assignEntitlements(so.Id+'',false);
			
		}
	}

}