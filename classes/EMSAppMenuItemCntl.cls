/**********************************
Class Name: EMSAppMenuItemCntl
Description: An Apex page controller for managing applications and their connected apps
Version: 1.0
***********************************/
public with sharing class EMSAppMenuItemCntl {

	public String applicationName{get;set;}
    public String messages {get; private set;}
    public List<Application__C> appToBeCreated {get;set;}
    public boolean renderList {get;set;}

	public EMSAppMenuItemCntl() {
		renderList = false;
        appToBeCreated = new List<Application__c>();
	}

	public PageReference createAppMenuItem(){
		//allinone_replace

		Application__c[] apps = [SELECT Id,Name, App_URL__c, Connected_App_ID__c, App_Code__c from Application__c where App_Code__c=:applicationName  and Connected_App_ID__c = null LIMIT 1];

		Application__c app = null;
		if (apps != null && apps.size() > 0)
                app = apps[0];

  		if (app == null){
             messages = messages + 'Unable to find the application.  Please try again.';
          
            return null;
        }

        MetadataService.MetadataPort service = createService();
        //MetadataService.AppMenu appMenuList = (MetadataService.AppMenu) service.readMetadata('AppMenu', new String[] { }).getRecords()[0];
        //List<MetadataService.AppMenuItem> items = appMenuList.appMenuItems;

		MetadataService.ConnectedApp newItem = new MetadataService.ConnectedApp();
        
        newItem.label = app.Name;
        newItem.fullName = app.App_Code__c;
        newItem.StartURL = app.App_URL__c;
        newItem.type = 'ConnectedApp';
        newItem.contactEmail = 'dvolk+metadata@identigral.com';
        
        
        List<MetadataService.SaveResult> results =
            service.createMetadata(
                new MetadataService.Metadata[] { newItem });
        handleSaveResults(results[0]);

        System.debug('Just created the new app menu item.'+applicationName);
        AppMenuItem[] amis = [SELECT Id, ApplicationId from AppMenuItem where name=:applicationName limit 1];

        app.Connected_App_ID__c = amis[0].ApplicationId;
        update app;
        System.debug('Just updated the custom object');

        //finish
		applicationName='';
		return null;

	}

    public PageReference assignProfile(){

    MetadataService.MetadataPort service = createService();
        MetadataService.Profile ps =
            (MetadataService.Profile) service.readMetadata('Profile',
                new String[] { 'EMS External User' }).getRecords()[0];
            System.debug(ps);

        //ProfileApplicationVisibility
        List<AppMenuItem> apps = [Select id, ApplicationId, Name,Label,Description from AppMenuItem where type='ConnectedApplication'];

        MetadataService.Profile admin = new MetadataService.Profile();
        admin.fullName = 'EMS External User';
        admin.custom = false;

        List<MetadataService.ProfileApplicationVisibility> profsVisibility = new List<MetadataService.ProfileApplicationVisibility>();
        for(AppMenuItem app :apps){
            MetadataService.ProfileApplicationVisibility profApp = new MetadataService.ProfileApplicationVisibility();
            profApp.application=app.Id;
            profApp.visible=true;
            profApp.default_x=false;
            profsVisibility.add(profApp);
             admin.applicationVisibilities  = new MetadataService.ProfileApplicationVisibility[] {profApp} ;
        }

       
         List<MetadataService.SaveResult> results =
            service.updateMetadata(
                new MetadataService.Metadata[] { admin });
        handleSaveResults(results[0]);
     
        return null;


    }

    public PageReference fixData(){
        //this makes a connected app for any missing app.
        messages = '';
        renderList=false;
        Application__c[] apps = [SELECT Id,Name, App_URL__c, Connected_App_ID__c, App_Code__c from Application__c where Connected_App_ID__c = null];
        integer count = 0;
      /*  for(Application__c app:apps){

        MetadataService.MetadataPort service = createService();
        //MetadataService.AppMenu appMenuList = (MetadataService.AppMenu) service.readMetadata('AppMenu', new String[] { }).getRecords()[0];
        //List<MetadataService.AppMenuItem> items = appMenuList.appMenuItems;

        MetadataService.ConnectedApp newItem = new MetadataService.ConnectedApp();
        
        newItem.label = app.Name;
        newItem.fullName = app.App_Code__c;
        newItem.StartURL = app.App_URL__c;
        newItem.type = 'ConnectedApp';
        newItem.contactEmail = 'dvolk+metadata@identigral.com';
        
        
        List<MetadataService.SaveResult> results =
            service.createMetadata(
                new MetadataService.Metadata[] { newItem });
        handleSaveResults(results[0]);

        System.debug('Just created the new app menu item.'+applicationName);
        }
        */
        ID jobID = System.enqueueJob(new ConnectAppQueueable(apps, UserInfo.getSessionId()));

        //finish
        messages = messages + 'Started job to create '+apps.size() +' connected apps';
        return null;
    }

	public PageReference cancelAppMenuItem(){
		applicationName='';
        appToBeCreated =new List<Application__c>();
        renderList=false;
		return null;
	}


    public PageReference listConnectedApps(){
        appToBeCreated = [SELECT Id,Name, App_URL__c, Connected_App_ID__c, App_Code__c from Application__c where Connected_App_ID__c = null];
        renderList = true;
        return null;

    }

    public PageReference linkData(){
        messages= '';
        renderList=false;
        Application__c[] apps = [SELECT Id,Name, App_URL__c, Connected_App_ID__c, App_Code__c from Application__c where Connected_App_ID__c = null LIMIT 30];
        integer count = 0;
        for(Application__c app:apps){

        AppMenuItem[] amis = [SELECT Id, ApplicationId from AppMenuItem where name=:app.App_Code__c limit 1];
        if (amis != null && amis.size() >0){
            app.Connected_App_ID__c = amis[0].ApplicationId;
            update app;
            System.debug('Just updated the custom object');

            count++;
            }
        }
        messages = messages + 'Created and updated ' + count + ' applications.';
        return null;
    }



	public static MetadataService.MetadataPort createService()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }

     /**
     * Example helper method to interpret a SaveResult, throws an exception if errors are found
     **/
    public static void handleSaveResults(MetadataService.SaveResult saveResult)
    {
        // Nothing to see?
        if(saveResult==null || saveResult.success)
            return;
        // Construct error message and throw an exception
        if(saveResult.errors!=null)
        {
            List<String> messages = new List<String>();
            messages.add(
                (saveResult.errors.size()==1 ? 'Error ' : 'Errors ') +
                    'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors)
                messages.add(
                    error.message + ' (' + error.statusCode + ').' +
                    ( error.fields!=null && error.fields.size()>0 ?
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            if(messages.size()>0)
                throw new EMSConnectedAppCreationException(String.join(messages, ' '));
        }
        if(!saveResult.success)
            throw new EMSConnectedAppCreationException('Request failed with no specified error.');
    }


	public class EMSConnectedAppCreationException extends Exception { }
}