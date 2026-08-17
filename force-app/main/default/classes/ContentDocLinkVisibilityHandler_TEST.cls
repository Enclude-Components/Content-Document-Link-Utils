/**
 * @description Tests ContentDocLinkVisibilityHandler.cls
 * @group Tests
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
public class ContentDocLinkVisibilityHandler_TEST {
    @TestSetup
    static void setup() {
        insert new Account(Name = 'Test Account');
        insert new Contact(LastName = 'Test Contact');
    }

    @IsTest
    static void applyVisibility_ruleConfiguredAllUsers_endToEndInsertPersistsAllUsers() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = true;
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>{
            'account' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'AllUsers'
            )
        };
        Account acct = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = buildLink(acct.Id);

        // When
        Test.startTest();
        insert cdl;
        Test.stopTest();

        // Then
        ContentDocumentLink inserted = [SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id];
        Assert.areEqual('AllUsers', inserted.Visibility, 'Trigger should persist Visibility as AllUsers when the matching rule is configured for it');
    }

    @IsTest
    static void applyVisibility_ruleConfiguredInternalUsers_setsVisibilityToInternalUsers() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = true;
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>{
            'account' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'InternalUsers'
            )
        };
        Account acct = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = acct.Id);

        // When
        ContentDocLinkVisibilityHandler.applyVisibility(new List<ContentDocumentLink>{ cdl });

        // Then
        Assert.areEqual('InternalUsers', cdl.Visibility, 'A rule configured for InternalUsers should actively assert that value');
    }

    @IsTest
    static void applyVisibility_unrecognizedVisibilityValue_defensivelyResolvesToInternalUsers() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = true;
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>{
            'account' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'SomethingUnexpected'
            )
        };
        Account acct = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = acct.Id);

        // When
        ContentDocLinkVisibilityHandler.applyVisibility(new List<ContentDocumentLink>{ cdl });

        // Then
        Assert.areEqual('InternalUsers', cdl.Visibility, 'An unrecognized configured value should defensively resolve to InternalUsers');
    }

    @IsTest
    static void applyVisibility_noRuleConfiguredForThisObject_leavesVisibilityUntouched() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = true;
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>{
            'contact' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'AllUsers'
            )
        };
        Account acct = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = acct.Id);

        // When
        ContentDocLinkVisibilityHandler.applyVisibility(new List<ContentDocumentLink>{ cdl });

        // Then
        Assert.isNull(cdl.Visibility, 'An object with no configured rule of its own should be left untouched, with no org-wide fallback to fall back to');
    }

    @IsTest
    static void applyVisibility_noRulesConfiguredAtAll_leavesVisibilityUntouched() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = true;
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>();
        Account acct = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = acct.Id);

        // When
        ContentDocLinkVisibilityHandler.applyVisibility(new List<ContentDocumentLink>{ cdl });

        // Then
        Assert.isNull(cdl.Visibility, 'With no rules configured at all, Visibility should be left as Salesforce sets it by default');
    }

    @IsTest
    static void applyVisibility_experienceCloudNotEnabled_leavesVisibilityUntouchedRegardlessOfRule() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = false;
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>{
            'account' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'AllUsers'
            )
        };
        Account acct = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = acct.Id);

        // When
        ContentDocLinkVisibilityHandler.applyVisibility(new List<ContentDocumentLink>{ cdl });

        // Then
        Assert.isNull(cdl.Visibility, 'The whole feature should no-op when Experience Cloud is not enabled, even with a matching rule configured');
    }

    @IsTest
    static void applyVisibility_perObjectRules_appliedIndependentlyPerObject() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = true;
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>{
            'account' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'InternalUsers'
            ),
            'contact' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'AllUsers'
            )
        };
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        ContentDocumentLink accountLink = new ContentDocumentLink(LinkedEntityId = acct.Id);
        ContentDocumentLink contactLink = new ContentDocumentLink(LinkedEntityId = con.Id);

        // When
        ContentDocLinkVisibilityHandler.applyVisibility(new List<ContentDocumentLink>{ accountLink, contactLink });

        // Then
        Assert.areEqual('InternalUsers', accountLink.Visibility, 'Account links should get the Account-specific rule');
        Assert.areEqual('AllUsers', contactLink.Visibility, 'Contact links should get the Contact-specific rule, independent of the Account rule');
    }

    @IsTest
    static void isEligibleForOverride_userLinkedEntity_returnsFalse() {
        // Given
        Id linkedEntityId = UserInfo.getUserId();

        // When
        Boolean isEligible = ContentDocLinkVisibilityHandler.isEligibleForOverride(linkedEntityId);

        // Then
        Assert.isFalse(isEligible, 'Files linked to a User (personal library) should not be eligible for override');
    }

    @IsTest
    static void isEligibleForOverride_nullLinkedEntityId_returnsFalse() {
        // Given
        Id linkedEntityId = null;

        // When
        Boolean isEligible = ContentDocLinkVisibilityHandler.isEligibleForOverride(linkedEntityId);

        // Then
        Assert.isFalse(isEligible, 'A null LinkedEntityId should not be eligible for override');
    }

    @IsTest
    static void isEligibleForOverride_standardRecordLinkedEntity_returnsTrue() {
        // Given
        Id linkedEntityId = UserInfo.getOrganizationId();

        // When
        Boolean isEligible = ContentDocLinkVisibilityHandler.isEligibleForOverride(linkedEntityId);

        // Then
        Assert.isTrue(isEligible, 'Files linked to a standard record (non-User, non-Group) should be eligible for override');
    }

    @IsTest
    static void isExperienceCloudEnabled_noMockConfigured_resolvesRealOrgFeatureStateWithoutError() {
        // Given
        ContentDocLinkVisibilityHandler.mockIsExperienceCloudEnabled = null;

        // When
        Boolean result = ContentDocLinkVisibilityHandler.isExperienceCloudEnabled();

        // Then
        Assert.isNotNull(result, 'isExperienceCloudEnabled should always resolve to a real Boolean based on org state when unmocked');
    }

    private static ContentDocumentLink buildLink(Id linkedEntityId) {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        return new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = linkedEntityId,
            ShareType = 'V'
        );
    }
}
