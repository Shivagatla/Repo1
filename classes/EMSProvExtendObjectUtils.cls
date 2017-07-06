public class EMSProvExtendObjectUtils implements Queueable{

    private static String BASIC_PROFILE = 'EMS External User';
    private UserProvAccount upa;
   List<Cart_Entitlement__c> cartEnts;
   Id targetAppId;
   String operation;
    

    public EMSProvExtendObjectUtils(UserProvAccount upaIn){
        upa = upaIn;
        operation='Create';
        targetAppId = [SELECT Id from Application__c where Connected_App_Id__c = :upaIn.ConnectedAppId LIMIT 1].ID;

    }

   public EMSProvExtendObjectUtils(UserProvAccount upaIn, List<Cart_Entitlement__c> ents,Id targetApp){
      upa = upaIn;
      cartEnts = ents;
      targetAppId = targetApp;
      operation='Create';
   }

 public EMSProvExtendObjectUtils(UserProvAccount upaIn, List<Cart_Entitlement__c> ents,Id targetApp,String operationIn){
      upa = upaIn;
      cartEnts = ents;
      targetAppId = targetApp;
      operation=operationIn;

   }

    public void execute(QueueableContext context){
        
        if (operation.equals('Create')){
    
            if (cartEnts == null){
                List<Cart_Application__c> cartApps = [Select Name, Catalog_App__c, (SELECT Id, Ent_Code__c,ent_code__r.ParentApp__c,RecordType.DeveloperName from Cart_Entitlements__r) from Cart_Application__c where upr_number__c in (select Id from UserProvisioningRequest where UserProvAccountId=:upa.Id)];
                if (cartApps != null && cartApps.size()>0){
                    Cart_Application__c cartApp = cartApps[0];
                    targetAppId = cartApp.Catalog_App__c;
                
            
                    cartEnts = cartApp.Cart_Entitlements__r;
                }
            }

            if (cartEnts != null){
                for (Cart_Entitlement__c cartEnt : cartEnts){
                    if (cartEnt.RecordType.DeveloperName == 'Role'){
                        if (doesUPEExist(upa.Id, cartEnt.ent_code__c)==false){
                            UserProvisionEntitlement__c upe = new UserProvisionEntitlement__c();
                            upe.Entitlement_Code__c = cartEnt.ent_code__c;
                            upe.UPA_Parent__c = upa.Id;
                            upe.ParentApp__c = targetAppId;
                            upe.Related_SF_User__C = upa.SalesforceUserId;
                            System.debug('UPE:'+ upe);
                            insert upe;
                        }
                    }
                    else{
                        if (doesUPFEExist(upa.Id, cartEnt.account__c)==false){
                            UserProvFineEntitlement__c upe = new UserProvFineEntitlement__c();
                            upe.Entitled_Account__c = cartEnt.account__c;
                            upe.UPA_Parent__c = upa.Id;
                            upe.ParentApp__c = targetAppId;
                            upe.Related_SF_User__C = upa.SalesforceUserId;
                            System.debug('UPFE:'+ upe);
                            insert upe;
                        }
                    }
                    
                }
            }

            Application__c targetApp = [SELECT EMS_Application__c, EMS_Application_Object_Name__c, EMS_Application_Type__c from Application__c where Id=:targetappId];
            

            System.debug('EMS App:' + targetApp.EMS_Application__c + ', Type:'+targetApp.EMS_Application_Type__c +'Object Name'+ targetApp.EMS_Application_Object_Name__c);
 
             if (targetApp.EMS_Application__c == true){
                    if (targetApp.EMS_Application_Type__c == 'Profile' && !String.isBlank(targetApp.EMS_Application_Object_Name__c)){
                       
                       Profile prof = [SELECT Id,Name FROM Profile WHERE Name=:targetApp.EMS_Application_Object_Name__c LIMIT 1 ];
                      Id userJobId = System.enqueueJob(new UpdateUserQueueable(upa.SalesforceUserId,'ProfileId',prof.Id));
                    
                        
                    }


                }
        }
        else if (operation.equalsIgnoreCase('Deactivate')){
            UserProvisionEntitlement__c[] upes = [SELECT Id,Entitlement_Code__c from UserProvisionEntitlement__c where UPA_parent__c=:upa.Id];
            for(UserProvisionEntitlement__c upe: upes){
                delete upe;
            }
            UserProvFineEntitlement__c[] upfes = [SELECT Id from UserProvFineEntitlement__c where UPA_parent__c=:upa.Id];
            for(UserProvFineEntitlement__c upfe: upfes){
                delete upfe;
            }

            UserProvAccount upa1 = [SELEcT Id,Status from UserProvAccount where id=:upa.Id limit 1];
            if (upa1.status == 'Active')
            {
                upa1.status = 'Deactivated';
                update upa1;
            }   
            Application__c targetApp = [SELECT EMS_Application__c, EMS_Application_Object_Name__c, EMS_Application_Type__c from Application__c where Id=:targetappId];
    

            if (targetApp.EMS_Application__c == true){
                    if (targetApp.EMS_Application_Type__c == 'Profile' ){
                       
                       Profile prof = [SELECT Id,Name FROM Profile WHERE Name=:BASIC_PROFILE LIMIT 1 ];
                      Id userJobId = System.enqueueJob(new UpdateUserQueueable(upa.SalesforceUserId,'ProfileId',prof.Id));
                        
                    }
                    

                }

        }
        else if (operation.equalsIgnoreCase(EMSConstants.UPDATE_OPERATION)){
            System.debug('need to add in UPEs');
            UserProvisionEntitlement__c[] upes = [SELECT Entitlement_Code__c from UserProvisionEntitlement__c where UPA_parent__c=:upa.Id];
            Set<String> provEnts = new Set<String>();
            Set<String> newEnts = new Set<String>();
            for(UserProvisionEntitlement__c upe: upes){
                provEnts.add(upe.Entitlement_Code__c);
            }

            UserProvFineEntitlement__c[] upfes = [SELECT Entitled_Account__c from UserProvFineEntitlement__c where UPA_parent__c=:upa.Id];
            Set<String> provFEnts = new Set<String>();
            Set<String> newFEnts = new Set<String>();
            for(UserProvFineEntitlement__c upfe: upfes){
                provFEnts.add(upfe.Entitled_Account__c);
            }
 
            if (cartEnts != null){
                for (Cart_Entitlement__c cartEnt : cartEnts){
                    if (cartEnt.RecordType.DeveloperName == 'Role'){
                        newEnts.add(cartEnt.ent_code__c);
                        if (!provEnts.contains(cartEnt.ent_code__c)){
                            UserProvisionEntitlement__c upe = new UserProvisionEntitlement__c();
                            upe.Entitlement_Code__c = cartEnt.ent_code__c;
                            upe.UPA_Parent__c = upa.Id;
                            upe.ParentApp__c = targetAppId;
                            upe.Related_SF_User__C = upa.SalesforceUserId;
                            System.debug('UPE:'+ upe);
                            insert upe;
                            
                        }
                    }
                    else{
                        newFEnts.add(cartEnt.Account__c);
                        
                        if (!provFEnts.contains(cartEnt.account__c)){
                            UserProvFineEntitlement__c upfe = new UserProvFineEntitlement__c();
                            upfe.Entitled_Account__c = cartEnt.Account__c;
                            upfe.UPA_Parent__c = upa.Id;
                            upfe.ParentApp__c = targetAppId;
                            upfe.Related_SF_User__C = upa.SalesforceUserId;
                            System.debug('UPFE:'+ upfe);
                            insert upfe;
                            
                        }
                    }
                    
                }

            }
            //now we need to delete what we shouldn't keep.
            for(UserProvisionEntitlement__c upe: upes){
                if (!newEnts.contains(upe.Entitlement_Code__c)){
                    delete upe;
                }
            }
            //now we need to delete what we shouldn't keep.
            for(UserProvFineEntitlement__c upfe: upfes){
                if (!newFEnts.contains(upfe.Entitled_Account__c)){
                    delete upfe;
                }
            }


        }


    }

    public boolean doesUPEExist(Id upaId, Id ent_code){


        UserProvisionEntitlement__c[] upes = [SELECT Entitlement_Code__c from UserProvisionEntitlement__c where UPA_parent__c=:upaId and Entitlement_Code__c=:ent_code];
        if (upes.size() > 0) return true;
        else return false;


    }
    public boolean doesUPFEExist(Id upaId, Id accountId){


        UserProvFineEntitlement__c[] upes = [SELECT Entitled_Account__c from UserProvFineEntitlement__c where UPA_Parent__c=:upaId and Entitled_Account__c=:accountId];
        if (upes.size() > 0) return true;
        else return false;


    }
}