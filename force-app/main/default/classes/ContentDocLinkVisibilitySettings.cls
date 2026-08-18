/**
 * @description Reads Content_Document_Link_Visibility_Setting__mdt records into a map keyed by
 * lowercase SObject API name. An object with no configured record has no entry in the map.
 * @since 17/08/2026
 * @author Brandon DeMatteis, Enclude
 */
public without sharing class ContentDocLinkVisibilitySettings {
    /** @description Test-only override so tests can supply rules without Custom Metadata records */
    @TestVisible
    private static Map<String, Content_Document_Link_Visibility_Setting__mdt> mockSettingsByObject;

    /**
     * @description Returns configured visibility rules keyed by lowercase SObject API name
     * @return Map of lowercase SObject API name to its rule record
     */
    public static Map<String, Content_Document_Link_Visibility_Setting__mdt> getSettingsByObject() {
        if (mockSettingsByObject != null) {
            return mockSettingsByObject;
        }

        Map<String, Content_Document_Link_Visibility_Setting__mdt> settingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>();
        for (Content_Document_Link_Visibility_Setting__mdt setting : [
            SELECT Default_Visibility__c, SObject__r.QualifiedApiName
            FROM Content_Document_Link_Visibility_Setting__mdt
            WITH SYSTEM_MODE
        ]) {
            if (setting.SObject__r == null) {
                continue;
            }
            settingsByObject.put(setting.SObject__r.QualifiedApiName.toLowerCase(), setting);
        }
        return settingsByObject;
    }
}
