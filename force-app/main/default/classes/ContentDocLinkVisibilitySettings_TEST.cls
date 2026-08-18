/**
 * @description Tests ContentDocLinkVisibilitySettings.cls
 * @group Tests
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
public class ContentDocLinkVisibilitySettings_TEST {
    @IsTest
    static void getSettingsByObject_noMockConfigured_queriesRealCustomMetadataWithoutError() {
        // Given
        ContentDocLinkVisibilitySettings.mockSettingsByObject = null;

        // When
        Map<String, Content_Document_Link_Visibility_Setting__mdt> settings = ContentDocLinkVisibilitySettings.getSettingsByObject();

        // Then
        Assert.isNotNull(settings, 'getSettingsByObject should always return a map, even when nothing is configured');
    }

    @IsTest
    static void getSettingsByObject_mockConfigured_returnsMockValues() {
        // Given
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>{
            'case' => new Content_Document_Link_Visibility_Setting__mdt(
                Default_Visibility__c = 'InternalUsers'
            )
        };

        // When
        Map<String, Content_Document_Link_Visibility_Setting__mdt> settings = ContentDocLinkVisibilitySettings.getSettingsByObject();

        // Then
        Assert.areEqual(1, settings.size(), 'Mock seam should fully replace the real settings map');
        Assert.areEqual('InternalUsers', settings.get('case').Default_Visibility__c, 'Mocked rule values should be returned as configured');
    }
}
