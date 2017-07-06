trigger NewApplicationTrigger on Application__c (after insert) {

	
	ID jobID = System.enqueueJob(new ConnectAppQueueable(Trigger.new, UserInfo.getSessionId()));


}