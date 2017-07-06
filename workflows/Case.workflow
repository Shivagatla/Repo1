<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>EMS_Email_Denied_User</fullName>
        <description>EMS Email Denied User</description>
        <protected>false</protected>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/New_User_Registration_Denied</template>
    </alerts>
    <alerts>
        <fullName>Send_Case_Owner_Email</fullName>
        <ccEmails>dvolk@identigral.com</ccEmails>
        <description>Send Case Owner Email</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/New_EMS_User</template>
    </alerts>
    <alerts>
        <fullName>Send_Email_to_Reviewed_User</fullName>
        <description>Send Email to Reviewed User</description>
        <protected>false</protected>
        <recipients>
            <field>ContactId</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>EMS/EMS_New_Approved_User</template>
    </alerts>
</Workflow>
