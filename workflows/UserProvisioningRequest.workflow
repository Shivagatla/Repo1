<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Access_deactivation_is_complete</fullName>
        <description>Access deactivation is complete</description>
        <protected>false</protected>
        <recipients>
            <field>Requestor__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>EMS/Access_Has_been_deactivated</template>
    </alerts>
    <alerts>
        <fullName>Access_modification_is_complete</fullName>
        <description>Access modification is complete</description>
        <protected>false</protected>
        <recipients>
            <field>Requestor__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>EMS/Access_Has_been_Modified</template>
    </alerts>
    <alerts>
        <fullName>New_Manual</fullName>
        <ccEmails>dvolk+role@identigral.com</ccEmails>
        <description>New Manual</description>
        <protected>false</protected>
        <recipients>
            <recipient>Customer_Support</recipient>
            <type>role</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/EMS_Manual_Provisioning</template>
    </alerts>
    <alerts>
        <fullName>New_Provisioned_Access</fullName>
        <description>New Provisioned Access</description>
        <protected>false</protected>
        <recipients>
            <field>SalesforceUserId</field>
            <type>userLookup</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/New_Access_Has_been_Gra</template>
    </alerts>
    <alerts>
        <fullName>UPR_Has_been_denied</fullName>
        <description>Access request has been denied</description>
        <protected>false</protected>
        <recipients>
            <field>SalesforceUserId</field>
            <type>userLookup</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/EMS_Access_Modify_Request_Denied</template>
    </alerts>
    <fieldUpdates>
        <fullName>Make_URP_Complete</fullName>
        <field>State</field>
        <literalValue>Completed</literalValue>
        <name>Make URP Complete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Overall_Status</fullName>
        <field>Overall_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Set Overall Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Overall_Status_u</fullName>
        <field>Overall_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Set Overall Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Request_To_Approved</fullName>
        <field>ApprovalStatus</field>
        <literalValue>Approved</literalValue>
        <name>Set Request To Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_State_to_Completed</fullName>
        <field>State</field>
        <literalValue>Completed</literalValue>
        <name>Set State to Completed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_overall_Status_d</fullName>
        <field>Overall_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Set overall Status Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_status_to_approved</fullName>
        <field>ApprovalStatus</field>
        <literalValue>Approved</literalValue>
        <name>Set status to approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_status_to_rejected</fullName>
        <field>ApprovalStatus</field>
        <literalValue>Denied</literalValue>
        <name>Set status to rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
</Workflow>
