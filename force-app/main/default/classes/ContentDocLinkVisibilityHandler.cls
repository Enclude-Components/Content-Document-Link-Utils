/**
 * @description Sets ContentDocumentLink.Visibility on newly inserted links based on per-SObject rules
 * in Content_Document_Link_Visibility_Setting__mdt. Has no effect when Experience Cloud is disabled,
 * the linked entity is a User or CollaborationGroup, or no rule exists for the linked object.
 * @since 08/17/2026
 * @author Brandon DeMatteis, Enclude
 */
public with sharing class ContentDocLinkVisibilityHandler {
    /** @description Visibility value that grants access to Experience Cloud users */
    @TestVisible
    private static final String ALL_USERS_VISIBILITY = 'AllUsers';

    /** @description Visibility value that restricts access to internal users only */
    @TestVisible
    private static final String INTERNAL_USERS_VISIBILITY = 'InternalUsers';

    /** @description SObject types excluded from Visibility overrides */
    @TestVisible
    private static final Set<Schema.SObjectType> INELIGIBLE_LINKED_ENTITY_TYPES = new Set<Schema.SObjectType>{
        User.SObjectType,
        CollaborationGroup.SObjectType
    };

    /** @description Test-only override for isExperienceCloudEnabled() */
    @TestVisible
    private static Boolean mockIsExperienceCloudEnabled;

    /**
     * @description Sets Visibility on each new ContentDocumentLink whose linked object has a configured rule
     * @param newLinks The ContentDocumentLink records being inserted
     */
    public static void applyVisibility(List<ContentDocumentLink> newLinks) {
        if (!isExperienceCloudEnabled()) {
            return;
        }

        Map<String, Content_Document_Link_Visibility_Setting__mdt> settingsByObject = ContentDocLinkVisibilitySettings.getSettingsByObject();
        if (settingsByObject.isEmpty()) {
            return;
        }

        Map<Schema.SObjectType, String> apiNameByLinkedType = new Map<Schema.SObjectType, String>();

        for (ContentDocumentLink cdl : newLinks) {
            if (!isEligibleForOverride(cdl.LinkedEntityId)) {
                continue;
            }

            Schema.SObjectType linkedType = cdl.LinkedEntityId.getSObjectType();
            String objectApiName = apiNameByLinkedType.get(linkedType);
            if (objectApiName == null) {
                objectApiName = linkedType.getDescribe().getName().toLowerCase();
                apiNameByLinkedType.put(linkedType, objectApiName);
            }

            Content_Document_Link_Visibility_Setting__mdt rule = settingsByObject.get(objectApiName);
            if (rule == null) {
                continue;
            }

            cdl.Visibility = resolveVisibility(rule.Default_Visibility__c);
        }
    }

    /**
     * @description Returns whether a linked entity is eligible for a Visibility override
     * @param linkedEntityId The ContentDocumentLink.LinkedEntityId value to check
     * @return True if eligible, false otherwise
     */
    @TestVisible
    private static Boolean isEligibleForOverride(Id linkedEntityId) {
        if (linkedEntityId == null) {
            return false;
        }
        return !INELIGIBLE_LINKED_ENTITY_TYPES.contains(linkedEntityId.getSObjectType());
    }

    /**
     * @description Resolves a configured value to a Visibility value, defaulting to InternalUsers
     * @param configuredVisibility The rule's Default_Visibility__c value
     * @return AllUsers if configured as such, InternalUsers otherwise
     */
    @TestVisible
    private static String resolveVisibility(String configuredVisibility) {
        return ALL_USERS_VISIBILITY.equalsIgnoreCase(configuredVisibility) ? ALL_USERS_VISIBILITY : INTERNAL_USERS_VISIBILITY;
    }

    /**
     * @description Returns whether Experience Cloud is enabled for the org. Uses Type.forName since a
     * direct reference to Schema.Network fails to compile in orgs without the feature.
     * @return True if enabled (or mocked as such), false otherwise
     */
    @TestVisible
    private static Boolean isExperienceCloudEnabled() {
        if (mockIsExperienceCloudEnabled != null) {
            return mockIsExperienceCloudEnabled;
        }
        return Type.forName('Schema.Network') != null;
    }
}
