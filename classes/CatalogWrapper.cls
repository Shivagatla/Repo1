/**********************************
Class Name: CatalogWrapper
Description:This class wraps each row in the myaccess page so that rows can be enacted upon.
Version: 1.0
***********************************/
public class CatalogWrapper {
	


    public Boolean checked{ get; set; }
    public Application__c app { get; set;}
    public List<Entitlements__c> ents {get;set;}
    public List<Entitlements__c> entsAvailable {get;set;}
    public List<Account> provAccounts{get;set;}
    public SelectOption[] entOptions {get;set;}
    public Id selectedEntId {get;set;}
    public boolean isGranted {get;set;}
    public boolean hasEntstoOffer {get;set;}
    public String reason{get;set;}
    private Map<Id,Entitlements__c> entMap;
    public boolean pendingRequest {get;set;}
    public boolean migrated{get;set;}
    public String operation{get;set;}
    public String requestName{get;set;}


    public CatalogWrapper(){
        app = new Application__c();
        ents = new List<Entitlements__c>();
        checked = false;
        this.entOptions = new SelectOption[]{};
        reason='';
        migrated = false;
        provAccounts = new List<Account>();
    }

   public CatalogWrapper(Application__c appIn,List<Entitlements__c> provEnts,List<Entitlements__c> entsAvailableIn){
        app = appIn;
        ents = provEnts;
        entsAvailable = entsAvailableIn;
        checked = false;
        isGranted = true;
        this.entOptions = new SelectOption[]{};
        entMap = new Map<Id,Entitlements__c>();
        reason='';
        if (entsAvailableIn.size()>0) hasEntstoOffer=true;
        else hasEntstoOffer=false;
         for (Entitlements__c ent:entsAvailableIn){
            entOptions.add(new SelectOption(ent.Id,ent.Name));
            entMap.put(ent.Id,ent);
        }
        provAccounts = new List<Account>();

    }

     public CatalogWrapper(Application__c appIn,List<Entitlements__c> provEnts,List<Entitlements__c> entsAvailableIn,String operationIn){
        app = appIn;
        ents = provEnts;
        entsAvailable = entsAvailableIn;
        operation = operationIn;
        checked = false;
        isGranted = true;
        this.entOptions = new SelectOption[]{};
        entMap = new Map<Id,Entitlements__c>();
        reason='';
        if (entsAvailableIn.size()>0) hasEntstoOffer=true;
        else hasEntstoOffer=false;
         for (Entitlements__c ent:entsAvailableIn){
            entOptions.add(new SelectOption(ent.Id,ent.Name));
            entMap.put(ent.Id,ent);
        }
        provAccounts = new List<Account>();

    }

   public CatalogWrapper(Application__c appIn,List<Entitlements__c> entsIn){
        app = appIn;
        ents = entsIn;
        entMap = new Map<Id,Entitlements__c>();
        isGranted = false;
        checked = false;
        reason='';
        this.entOptions = new SelectOption[]{};
        for (Entitlements__c ent:ents){
            entOptions.add(new SelectOption(ent.Id,ent.Name));
            entMap.put(ent.Id,ent);
        }
        hasEntstoOffer=entOptions.size()>0;
        provAccounts = new List<Account>();
        
    }

    public String getAppName(){
        return app.Name;
    }

    public String getAppDescription(){
        return app.Description__c;
    }
    
    public String getAppShortDescription(){
        return String.isNotBlank(app.Short_description__c) ? app.Short_description__c : 'N/A';
    }
    public String getFineGrainInstructions(){
        return String.isNotBlank(app.FG_Instructions__c) ? app.FG_Instructions__c : 'N/A';
    }
    public String getFGMaxEnts(){
        return String.valueOf(app.FG_Max_Ents__c);
    }
    public boolean getFGmgmt(){
        return app.FG_mgmt__c;
    }

    public String getAppId(){
        return app.Id;
    }

    public String getRoleDisplay(){
        if (!isGranted) return '';
        String entNames = '';
        Integer count=1;
        for (Entitlements__c ent:ents){
            if (count < ents.size())
            entNames = entNames + ent.Name+', ';
            else
            entNames = entNames + ent.Name;
            count++;
        }
        return entNames;

    }

    public String getAccountDisplay(){
     
      String entNames = '';
        Integer count=1;
        Integer maxCount = 2;
        for (Account ent:provAccounts){ //
          
            if (count < provAccounts.size() && count <= maxCount)
                entNames = entNames +  ent.Name+' ('+ent.GUID__c +'), ';
            else if (count == provAccounts.size() && count <= maxCount)
                entNames = entNames +  ent.Name+' ('+ent.GUID__c +')';
            else if (count == (maxCount+1)) entNames = entNames +' ... and ' + (provAccounts.size()-count+1) + ' more';

            count++;
        
        }
        return entNames;
    }



    public SelectOption[] getEntOptions(){
        return entOptions;
    }

    public Application__c getApp(){
        return app;
    }

    public Entitlements__c getSelectedEnt(){
        return entMap.get(selectedEntId);
    }

    public String getReason(){

        return reason;
    }

    public boolean isChecked(){
        return checked;
    }

}