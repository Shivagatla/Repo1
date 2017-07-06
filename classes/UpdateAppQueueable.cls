public class UpdateAppQueueable implements Queueable{

	public UpdateAppQueueable() {
		
	}

	public void execute(QueueableContext context){
		    Application__c[] apps = [SELECT Id,Name, App_URL__c, Connected_App_ID__c, App_Code__c from Application__c where Connected_App_ID__c = null LIMIT 30];
     
        for(Application__c app:apps){

        AppMenuItem[] amis = [SELECT Id, ApplicationId from AppMenuItem where name=:app.App_Code__c limit 1];
        if (amis != null && amis.size() >0){
            app.Connected_App_ID__c = amis[0].ApplicationId;
            update app;

            }
        }
	}

}