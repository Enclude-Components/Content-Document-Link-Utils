/**
 * @description Standalone diagnostic (not part of the package's real test coverage): checks whether
 * the platform allows explicitly assigning ContentDocumentLink.Visibility = 'InternalUsers' via DML.
 * ContentDocLinkVisibilityHandler is bypassed entirely (via the mock settings seam) so this isolates
 * pure platform behavior from anything this package's code does. Delete once the question is settled.
 * @group Tests
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
public class VisibilityDiagnostic_TEST {
    @IsTest
    static void explicitlySettingVisibilityToInternalUsersOnInsert() {
        // Given
        Account acct = new Account(Name = 'Diagnostic Account');
        insert acct;

        ContentVersion cv = new ContentVersion(
            Title = 'Diagnostic File',
            PathOnClient = 'diagnostic.txt',
            VersionData = Blob.valueOf('Diagnostic content')
        );
        insert cv;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Bypass ContentDocLinkVisibilityHandler entirely so only the platform's own behavior is under test.
        ContentDocLinkVisibilitySettings.mockSettingsByObject = new Map<String, Content_Document_Link_Visibility_Setting__mdt>();

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = acct.Id,
            ShareType = 'V',
            Visibility = 'InternalUsers'
        );

        // When / Then: no try-catch on purpose - if the platform rejects this, this test fails with
        // the exact DmlException message, which answers the question unambiguously either way.
        Test.startTest();
        insert cdl;
        Test.stopTest();

        ContentDocumentLink inserted = [SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id];
        Assert.areEqual('InternalUsers', inserted.Visibility, 'Explicit InternalUsers assignment was accepted and persisted');
    }
}
