global class GenericProvModifyPlugin extends UserProvisioning.UserProvisioningPlugin {

    private static String PARAM_USERNAME = 'username';
    private static String PARAM_FAMILY_NAME = 'familyName';
    private static String PARAM_GIVEN_NAME = 'givenName';
    private static String PARAM_NICK_NAME = 'nickName';
    private static String PARAM_EMAIL = 'email';
    private static String PARAM_PROFILEID = 'profileId';
    private static final String PARAM_CONNECTED_APPID = 'ConnectedAppId';

    global override Process.PluginDescribeResult buildDescribeCall() { 
        Process.PluginDescribeResult describeResult = new Process.PluginDescribeResult();
        describeResult.tag = 'Generic Modify Provisioned Users';
        describeResult.Name = 'Modify Provisioned User';
        describeResult.inputParameters = new 
            List<Process.PluginDescribeResult.InputParameter>{ 
               new Process.PluginDescribeResult.InputParameter(PARAM_USERNAME, Process.PluginDescribeResult.ParameterType.STRING, true),
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
        UserProvisioningUtils.debug('Inside GenericProvModifyPlugin invoke()');

        String userName =  (String) request.inputParameters.get(PARAM_USERNAME);

        String ConnectedAppId = (String) request.inputParameters.get(PARAM_CONNECTED_APPID);
              
        User targetUser = [SELECT Id, Ag2Ag_ID__c,External_Fed_Id__c,username,email,firstName,lastname FROM User where username=:userName];

            


        try {
            UserProvisioningUtils.init(uprId);
            
            EMSUPRHelper uprInfo = new EMSUPRHelper(uprId,ConnectedAppId);
            UserProvAccount upa = UserProvisioningUtils.getLinkedUserProvAccount(uprInfo.getUPRApplication().Connected_App_Id__c);
            if (upa==null){
                //return success
                UserProvisioningUtils.log('No active UserProvAccount was found to modify.  Need to review access.');
                result.put('Status','Failed');
                result.put('NeedManual',true);
            }
            else{ //we need to update the upe objects..
                //System.debug('The user was already provisioned.');
                //we do need to add on additional entitlements

                Application__c targetApp = uprInfo.getUPRApplication();
                ApplicationHelper ah = new ApplicationHelper(targetApp); 
                UserProvisioningService ups = new UserProvisioningService();
                boolean needManual = false;
                Set<Entitlements__c> provEnts = new Set<Entitlements__c>(ah.getProvisionedEnts(targetUser.Id, targetApp.Id));
                Set<Account> provAccts = new Set<Account>(ah.getProvisionedFEnts(targetUser.Id));
                if(Test.isRunningTest()==false){
                   
                    try{
                        //ups.entitleUser(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getReason());
                        //first we need to delete all the entitlements a user has
                        System.debug('Deleting current accounts.');
                        if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c)){
                            System.debug('Using equinox path.');
                            if (provEnts.size() > 0 || provAccts.size() > 0)
                                ups.modifyUserEntitlementsByAction(targetUser, targetApp, provEnts, provAccts, uprInfo.getReason(), 'D');
                        }
                        else {
                            if (provEnts.size()>0)
                                ups.modifyUserEntitlementsByAction(targetUser, targetApp, provEnts, uprInfo.getReason(), 'D');
                        }
                         UserProvisioningUtils.log('Made Web service call to delete ents/accounts for User:' +targetUser +' for app:' + targetApp);
                         String entNames = '';
                         integer count = 0;
                         for (Entitlements__c ent:provEnts){

                            entNames = (count==0)?entNames +ent.Name:entNames + ', ' + ent.Name;
                            count++;
                         }
                         String accountNames = '';
                         integer countA = 0;
                         for (Account acct:provAccts){

                            accountNames = (countA==0)?accountNames +acct.Name + '('+acct.GUID__C+')':accountNames + ', ' + acct.Name+ '('+acct.GUID__C+')';
                            countA++;
                         }
                        UserProvisioningUtils.log('-     with entitlements: '+ entNames +' and accounts:' + accountNames);
                        UserProvisioningUtils.log('-     the formal entitlements are: ' + provEnts);
                        System.debug('adding in accounts.');
                         if (Boolean.valueOf(targetApp.FG_Web_Service__c) && Boolean.valueOf(targetApp.FG_mgmt__c)){
                            System.debug('User equinox path to add accounts:' + uprInfo.getUPRFGEntitlements());
                            ups.modifyUserEntitlementsByAction(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getUPRFGEntitlements(),uprInfo.getReason(),'A');
                        }
                        else {
                            ups.modifyUserEntitlementsByAction(targetUser,targetApp,uprInfo.getUPREntitlements(),uprInfo.getReason(),'A');
                        }
                        
                         UserProvisioningUtils.log('Made Web service call to add ents for User:' +targetUser +' for app:' + targetApp);
                        count = 0;
                        entNames = '';
                         for (Entitlements__c ent: uprInfo.getUPREntitlements()){

                            entNames = (count==0)?entNames +ent.Name:entNames + ', ' + ent.Name;
                            count++;
                         }
                         accountNames = '';
                         countA = 0;
                         for (Account acct:uprInfo.getUPRFGEntitlements()){

                            accountNames = (countA==0)?accountNames +acct.Name + '('+acct.GUID__C+')':accountNames + ', ' + acct.Name+ '('+acct.GUID__C+')';
                            countA++;
                         }
                        UserProvisioningUtils.log('-     with entitlements: '+ entNames +' and accounts:' + accountNames);
                        
                        UserProvisioningUtils.log('-    the formal entitlements: '+ uprInfo.getUPREntitlements());
                    }
                    catch(Exception e){
                        UserProvisioningUtils.log('Exception modifying the user automatically.  Reverting to manual.' + e);
                        needManual=true;
                    }
                }
                if (needManual){
                   //need to send email or start flow or something
                   UserProvisioningUtils.log('Need to manually provisioned the user');

                    result.put('Details','User needs to be manually modified in application: ' + targetApp + ', and the account entitlements: ' + uprInfo.getCartEntitlements() );   
                    ID jobID = System.enqueueJob(new EMSProvExtendObjectUtils(upa,uprInfo.getCartEntitlements(),uprInfo.getUPRApplication().Id,EMSConstants.UPDATE_OPERATION));         
                }
                else{
                     result.put('Status', 'Completed');
                    result.put('Details','User successfully modified in: ' + targetApp + ', and the account entitlements: ' + uprInfo.getCartEntitlements() );            
                    UserProvisioningUtils.log('User successfully modified in: ' + targetApp);
                    UserProvisioningUtils.log('And the account entitlements: ' + uprInfo.getCartEntitlements() );            
 
                    UserProvisioningUtils.log('User modified successfully with ' + upa);
                    ID jobID = System.enqueueJob(new EMSProvExtendObjectUtils(upa,uprInfo.getCartEntitlements(),uprInfo.getUPRApplication().Id,EMSConstants.UPDATE_OPERATION));
                }

                 result.put('Status','Completed');
                result.put('ExternalUserId', targetUser.Ag2Ag_ID__c);
                result.put('ExternalUsername', targetUser.External_Fed_Id__c);
            result.put('NeedManual',needManual);
            UserProvisioningRequest upr = uprInfo.getUPR();
                //upr.UserProvAccount = upaNew;
                upr.Overall_Status__c='Completed';
                update upr;
               
                //result.put('Details', 'User updated successfully with ' + upa);
            }
           
        } catch(Exception e) {
            UserProvisioningUtils.handleException(result, 'Exception found when calling service: ', e);
        } finally {
            UserProvisioningUtils.insertLogs();
        }

        return new Process.PluginResult(result);
    }




}