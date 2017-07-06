trigger EMSCartEntitlementInsertTrigger on Cart_Entitlement__c (before insert) {

    for (Cart_Entitlement__c cartent:Trigger.new){
        if (cartent.Parent_App__c == null){
            cartent.Parent_App__c = [SELECT Id from Cart_Application__c where UPR_Number__c=:cartent.RelatedUPR__c LIMIT 1].Id;
        }

    }

}