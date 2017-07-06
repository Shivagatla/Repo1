public without sharing class StartFlowQueueable implements Queueable,Database.AllowsCallouts{

	UserProvisioningRequest upr;

	public StartFlowQueueable(UserProvisioningRequest upr) {
		this.upr = upr;
		
	}

	public void execute(QueueableContext context){
		System.debug(LoggingLevel.DEBUG,'The manual case has been finished. Starting to do baseline access.');
				
		Map<String,Object> newMap2 = new Map<String,Object>();
		//newMap.add('connectedAppId',upr.ConnectedAppId);
		//newMap.add('reconOffset',null);
		//newMap.add('User',so.Related_External_User__c);
		newMap2.put('UserProvisioningRequest',upr);
		Flow.Interview.Final_Provisioning_Process_Flow gpf = new Flow.Interview.Final_Provisioning_Process_Flow(newMap2);
		gpf.start();
		System.debug('started the flow');

	}
}