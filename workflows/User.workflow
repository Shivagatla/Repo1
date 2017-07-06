<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Needs_Email_Verification</fullName>
        <description>Needs Email Verification</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/EMS_Email_Verification_for_New_Users</template>
    </alerts>
    <alerts>
        <fullName>Send_Email_to_Reviewed_and_Registered_User</fullName>
        <description>Send Email to Reviewed and Registered User</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/New_EMS_User_Is_Provisioned</template>
    </alerts>
    <alerts>
        <fullName>Send_Email_to_Reviewed_and_Registered_User_BYOID</fullName>
        <description>Send Email to Reviewed and Registered User BYOID Login</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/New_EMS_User_Is_Provisioned_BYOID</template>
    </alerts>
    <fieldUpdates>
        <fullName>Update_Inactive_Field</fullName>
        <field>InactiveDate__c</field>
        <formula>NOW()</formula>
        <name>Update Inactive Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Inactive Date</fullName>
        <actions>
            <name>Update_Inactive_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(IsActive) &amp;&amp; NOT(IsActive)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
