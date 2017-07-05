global without sharing class GenericProvCreatePlugin extends UserProvisioning.UserProvisioningPlugin {

    private static String PARAM_USERNAME = 'username';
    private static String PARAM_FAMILY_NAME = 'familyName';
    private static String PARAM_GIVEN_NAME = 'givenName';
    private static String PARAM_NICK_NAME = 'nickName';
    private static String PARAM_EMAIL = 'email';
    private static String PARAM_PROFILEID = 'profileId';
    private static final String PARAM_CONNECTED_APPID = 'ConnectedAppId';

    global override Process.PluginDescribeResult buildDescribeCall() { 
        Process.PluginDescribeResult describeResult = new Process.PluginDescribeResult();
        describeResult.tag = 'Generic Manually Provisioned Users';
        describeResult.Name = 'Create Manually Provisioned User';
        describeResult.inputParameters = new 
            List<Process.PluginDescribeResult.InputParameter>{ 
               new Process.PluginDescribeResult.InputParameter(PARAM_USERNAME, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(PARAM_FAMILY_NAME, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(PARAM_GIVEN_NAME, Process.PluginDescribeResult.ParameterType.STRING, false),
               new Process.PluginDescribeResult.InputParameter(PARAM_NICK_NAME, Process.PluginDescribeResult.ParameterType.STRING, false),
               new Process.PluginDescribeResult.InputParameter(PARAM_EMAIL, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(PARAM_PROFILEID, Process.PluginDescribeResult.ParameterType.STRING, true),
               new Process.PluginDescribeResult.InputParameter(UserProvisioningUtils.PARAM_DEBUG_LOGGING, Process.PluginDescribeResult.ParameterType.BOOLEAN, false),
                new Process.PluginDescribeResult.InputParameter(PARAM_CONNECTED_APPID, Process.PluginDescribeResult.ParameterType.STRING, true)
            }; 
                
           describeResult.outputParameters = new 
            List<Process.PluginDescribeResult.OutputParameter>{ 
               new Process.PluginDescribeResult.OutputParameter('User ID', 
                       Process.PluginDescribeResult.ParameterType.STRING),
               new Process.PluginDescribeResult.OutputParameter('NeedManual', 
                       Process.PluginDescribeResult.ParameterType.BOOLEAN)
            };
        return describeResult;
    }
    
    global override Process.PluginResult invoke(Process.PluginRequest request) {
    
        Map<String,Object> result = new Map<String,Object>();
        result.put('Status', 'Failed'); // set default
        
        // Input parameters
        UserProvisioningUtils.isDebug = (Boolean)request.inputParameters.get(UserProvisioningUtils.PARAM_DEBUG_LOGGING);
        String uprId =  (String) request.inputParameters.get(UserProvisioningUtils.PARAM_UPR_ID);
        UserProvisioningUtils.debug('Inside GenericProvCreatePlugin invoke()');

        String userName =  (String) request.inputParameters.get(PARAM_USERNAME);
        String familyName =  (String) request.inputParameters.get(PARAM_FAMILY_NAME);
        String givenName =  (String) request.inputParameters.get(PARAM_GIVEN_NAME);
        String nickName =  (String) request.inputParameters.get(PARAM_NICK_NAME);
        String email =  (String) request.inputParameters.get(PARAM_EMAIL);
        String profileId =  (String) request.inputParameters.get(PARAM_PROFILEID);
        String ConnectedAppId = (String) request.inputParameters.get(PARAM_CONNECTED_APPID);
              
        User targetUser = [SELECT Id, Ag2Ag_ID__c,External_Fed_Id__c,username,ContactId,email,firstName,lastname FROM User where username=:userName];

            


        try {
            UserProvisioningUtils.init(uprId);
            
            EMSUPRHelper uprInfo = new EMSUPRHelper(uprId,ConnectedAppId);
            UserProvAccount upa = UserProvisioningUtils.getLinkedUserProvAccount(uprInfo.getUPRApplication().Connected_App_Id__c);
            UserProvisioningUtils.debug('Upa Result:'+ upa);
            if (upa==null){
                String nc = UserProvisioningUtils.getNamedCredential();
                // input validation
                Map<String,String> inputParamValues = new Map<String,String>();
                inputParamValues.put(PARAM_USERNAME, userName);
                inputParamValues.put(PARAM_FAMILY_NAME, familyName);
                inputParamValues.put(PARAM_EMAIL, email);
                inputParamValues.put(PARAM_PROFILEID, profileId);
                if(UserProvisioningUtils.areParamsBlank(inputParamValues, result)) {
                    return new Process.PluginResult(result);
                }
                

                Application__c targetApp = uprInfo.getUPRApplication();
                UserProvisioningService ups = new UserProvisioningService();
                boolean needManual = false;
                if(Test.isRunningTest()==false){
                    if (Boolean.valueOf(targetApp.Connected_App__c)){
                        System.debug(targetApp.Name + ' is a connected app.  Calling the web service.');
                        try{
                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getUPRFGEntitlements(),uprInfo.getReason());
                            else
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getReason());
                            UserProvisioningUtils.log('Made Web service call for User:' +targetUser );
                            UserProvisioningUtils.log('For  app:' + targetApp );
                            UserProvisioningUtils.log(' with entitlements: '+ uprInfo.getUPREntitlements());

                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                UserProvisioningUtils.log(' with FG entitlements: '+ uprInfo.getUPRFGEntitlements());
                        }
                        catch(Exception e){
                            UserProvisioningUtils.log('Exception provisioning the user automatically.  Reverting to manual.' + e);
                            needManual=true;
                        }
                    }
                    else{
                      
                        try{
                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getUPRFGEntitlements(),uprInfo.getReason());
                            else
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getReason());
                            UserProvisioningUtils.log('Called web service for app that has no AD groups');
                            UserProvisioningUtils.log('Made Web service call for' +targetUser + ' for app:' + targetApp + ' with entitlements: '+ uprInfo.getUPREntitlements());
                             if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                UserProvisioningUtils.log(' with FG entitlements: '+ uprInfo.getUPRFGEntitlements());
             
                        }
                        catch(Exception e){
                            UserProvisioningUtils.log('Exception provisioning the user automatically.  Reverting to manual.' + e);
                            needManual=true;
                        }
                        
                    }
                }

                             
                result.put('ExternalUserId', targetUser.Ag2Ag_ID__c);
                result.put('ExternalUsername', targetUser.External_Fed_Id__c);
                result.put('ExternalEmail', email);
                result.put('ExternalFirstName', (givenName != null) ? givenName : '' );
                result.put('ExternalLastName', familyName);
                result.put('UserID',targetUser.Id);
                result.put('NeedManual',needManual);
                result.put('Status', 'Completed');  
                if (needManual){

                   //need to send email or start flow or something
                    UserProvisioningUtils.log('Need to manually provisioned the user');
                    String issue = 'User needs to be manually provisioned with ExternalUserId=' +targetUser.Ag2Ag_ID__c+ ', and email=' + email + ' to application:' + targetApp.Name;

                    result.put('Details',issue);           
                    //need to create a case
                    EMSCreateCase.createCase(targetUser.ContactId,'Creating Access Failed','EMS_Provisioning',issue,targetApp.Provisioning_Queue__c,uprId);
                }
                
                else{
                    
                    result.put('Details','User created successfully with ExternalUserId=' + result.get('ExternalUserId') + ', and ExternalUsername=' + result.get('ExternalUsername') + ' to application:' + targetApp.Name);                
                }
                UserProvAccount upaNew = new UserProvAccount();
            
                upaNew.ExternalUserId = targetUser.Ag2Ag_ID__c;
                upaNew.ExternalUsername=targetUser.External_Fed_Id__c;
                upaNew.ExternalEmail=email;
                upaNew.ExternalFirstName = (givenName != null) ? givenName : '' ;
                upaNew.ExternalLastName=familyName;
                upaNew.connectedAppId = ConnectedAppId;
                upaNew.Status='Active';
                upaNew.LinkState ='Linked';
                upaNew.SalesforceUserId = targetUser.Id;
                insert upaNew;

                System.debug('the upaNew id is:' + upaNew.Id);

                UserProvisioningRequest upr = uprInfo.getUPR();
                upr.UserProvAccount = upaNew;
                upr.Overall_Status__c='Completed';
                update upr;
       
                ID jobID = System.enqueueJob(new EMSProvExtendObjectUtils(upaNew,uprInfo.getCartEntitlements(),uprInfo.getUPRApplication().Id));
             
            }
            else{ //we need to update the upe objects..
                System.debug('The user was already provisioned.');
                //we do need to add on additional entitlements
               
             

                Application__c targetApp = uprInfo.getUPRApplication();
                UserProvisioningService ups = new UserProvisioningService();
                boolean needManual = false;
                if(Test.isRunningTest()==false){
                    if (Boolean.valueOf(targetApp.Connected_App__c)){
                        System.debug(targetApp.Name + ' is a connected app.  Calling the web service.');
                         try{
                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getUPRFGEntitlements(),uprInfo.getReason());
                            else
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getReason());
                            UserProvisioningUtils.log('Made Web service call for User:' +targetUser );
                            UserProvisioningUtils.log('For  app:' + targetApp );
                            UserProvisioningUtils.log(' with entitlements: '+ uprInfo.getUPREntitlements());

                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                UserProvisioningUtils.log(' with FG entitlements: '+ uprInfo.getUPRFGEntitlements());
                        }
                        catch(Exception e){
                            UserProvisioningUtils.log('Exception provisioning the user automatically.  Reverting to manual.' + e);
                            needManual=true;
                        }
                    }
                    else{
                      
                        try{
                            if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getUPRFGEntitlements(),uprInfo.getReason());
                            else
                                ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getReason());
                            UserProvisioningUtils.log('Called web service for app that has no AD groups');
                            UserProvisioningUtils.log('Made Web service call for' +targetUser + ' for app:' + targetApp + ' with entitlements: '+ uprInfo.getUPREntitlements());
                             if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c))
                                UserProvisioningUtils.log(' with FG entitlements: '+ uprInfo.getUPRFGEntitlements());
             
                        }
                        catch(Exception e){
                            UserProvisioningUtils.log('Exception provisioning the user automatically.  Reverting to manual.' + e);
                            needManual=true;
                        }
                    }
                }
                 if (needManual){

                   //need to send email or start flow or something
                    UserProvisioningUtils.log('Need to manually provisioned the user');
                    String issue = 'User needs to be manually provisioned with ExternalUserId=' +targetUser.Ag2Ag_ID__c+ ', and email=' + email + ' to application:' + targetApp.Name;

                    result.put('Details',issue);           
                    //need to create a case
                    EMSCreateCase.createCase(targetUser.ContactId,'Creating Access Failed','EMS_Provisioning',issue,targetApp.Provisioning_Queue__c,uprId);
                }
                
                else{
                    
                  result.put('Details','Entitlements: '+ uprInfo.getCartEntitlements() + ' have been added to user ' + targetUser.Ag2Ag_ID__c + ' for app:' + targetApp.Name);  
                }
               

                         
            ID jobID = System.enqueueJob(new EMSProvExtendObjectUtils(upa,uprInfo.getCartEntitlements(),uprInfo.getUPRApplication().Id));
      

            result.put('ExternalEmail', targetUser.Email);
              result.put('NeedManual',needManual);
               result.put('Status','Completed');
                result.put('Details', 'User updated successfully with ' + upa);

                UserProvisioningRequest upr = uprInfo.getUPR();
                upr.UserProvAccount = upa;
                upr.Overall_Status__c='Completed';
                update upr;

             if (upa.Status=='Deactivated'){
                    upa.Status = 'Active';
                    upa.ExternalEmail = targetUser.email;
                    update upa;
                }

                EMSUPRHelper uprInfo2 = new EMSUPRHelper(uprId,ConnectedAppId);
                System.debug('the new userprov account is:' + uprInfo2.getUPR().UserProvAccountId);
            }
            
            
        } catch(Exception e) {
            UserProvisioningUtils.handleException(result, 'Exception found when calling service: ', e);
        } finally {
            UserProvisioningUtils.insertLogs();
        }

        return new Process.PluginResult(result);
    }
}