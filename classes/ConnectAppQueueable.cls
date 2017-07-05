/**********************************
Class Name: ConnectAppQueueable
Description:This class helps in the migration of applications, creating the SF connect app object automatically.
Version: 1.0
***********************************/
public class ConnectAppQueueable implements Queueable,Database.AllowsCallouts {

    Application__c[] apps {get;set;}
    String sessionId {get;set;}

    public ConnectAppQueueable(Application__c[] apps, String sessionIdIn) {
        this.apps = apps;
        this.sessionId = sessionIdIn;
    }

    public void execute(QueueableContext context){

        //because this is in a queueable, we have to keep session context.  EMSMetadataserviceHelper class provides the throughway
        MetadataService.MetadataPort service = EMSMetadataServiceHelper.createService(sessionId);
        for (Application__c app : apps) {
        //need to create a new connected app for this application.

        //MetadataService.AppMenu appMenuList = (MetadataService.AppMenu) service.readMetadata('AppMenu', new String[] { }).getRecords()[0];
        //List<MetadataService.AppMenuItem> items = appMenuList.appMenuItems;

            MetadataService.ConnectedApp newItem = new MetadataService.ConnectedApp();
        
            newItem.label = app.Name;
            newItem.fullName = app.App_Code__c;
            newItem.infoURL = app.App_URL__c;
            newItem.type = 'ConnectedApp';
            newItem.contactEmail = 'websitesupport@landolakes.com';
        
         if(Test.isRunningTest()==false){
            List<MetadataService.SaveResult> results =
            service.createMetadata(
                new MetadataService.Metadata[] { newItem });
            EMSMetadataServiceHelper.handleSaveResults(results[0]);
        }



        }

        //now we need to call the job to update the application objects
         if(Test.isRunningTest()==false){
            ID jobID = System.enqueueJob(new UpdateAppQueueable());
        }
        System.debug('Started the job to update applications.');

    }
}