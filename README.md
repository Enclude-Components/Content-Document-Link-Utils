# Content-Document-Link-Utils

Makes files uploaded to Salesforce records visible to Experience Cloud users. By default, Salesforce sets `ContentDocumentLink.Visibility` to `InternalUsers` when a file is attached to a record, which hides the file from external users even if they have access to the parent record. There is no admin setting for this; it requires custom logic.

## How it works

- `ContentDocumentLinkTrigger` (before insert) calls `ContentDocLinkVisibilityHandler`, which sets `Visibility` on each new `ContentDocumentLink`.
- The trigger has no effect when Experience Cloud is not enabled for the org, detected via `Type.forName('Schema.Network') != null`.
- Configuration lives in the `Content_Document_Link_Visibility_Setting__mdt` Custom Metadata Type. The package ships no records; nothing is managed until a record is created for an object.
- Each record's `SObject` field (a lookup to the object) is required and unique: one rule per object, no org-wide rule. An object with no record is left untouched.
- Each record's `Default Visibility` field is required: `All Users` or `Internal Users`. A blank or unrecognized value is treated as `Internal Users`.
- Files linked to a `User` (personal library) or `CollaborationGroup` (Chatter group) are left untouched.

Only new `ContentDocumentLink` records are affected. Existing files with `Visibility = InternalUsers` are unaffected; update them separately via Batch Apex or Data Loader.

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `cci flow run dev_org --org dev` to deploy this project.
3. Run `cci org browser dev` to open the org in your browser.
