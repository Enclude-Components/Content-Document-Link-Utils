# Content-Document-Link-Utils

Makes files uploaded to Salesforce records visible to Experience Cloud users. By default, Salesforce sets `ContentDocumentLink.Visibility` to `InternalUsers` when a file is attached to a record, which hides the file from external users even if they have access to the parent record.

Salesforce Help Article:
https://help.salesforce.com/s/articleView?id=005101347&type=1

## How it works

- `ContentDocumentLink` trigger (before insert) calls `ContentDocLinkVisibilityHandler`, which sets `Visibility` on each new `ContentDocumentLink`.
- The trigger has no effect when Experience Cloud is not enabled for the org.
- Configuration lives in the `Content_Document_Link_Visibility_Setting__mdt` Custom Metadata Type. A `Content_Document_Link_Visibility_Setting__mdt` must be created for each SObject type to apply the new default to.
- Each record's `SObject` field (a lookup to the object) is required and unique: one setting per object.
- Each record's `Default Visibility` field is required: `All Users` or `Internal Users`.

Only new `ContentDocumentLink` records are affected. Existing files from before package installation with `Visibility = InternalUsers` are unaffected.

## Creating a Content Document Link Visibility Setting for an Object
- ⚙️ Setup -> Search "Custom Metadata Types" -> Find `Content Document Link Visibility Setting` -> Click `Manage Records` -> Click `New`
- Create and Save a Setting:
    - Label: [Your SObject's Label]
    - Content Document Link Visibility Setting Name: [Allow to auto-fill]
    - Default Visibility: `All Users` (Default)
    - SObject: [Find and select your SObject type]
- Click `Save`

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `cci flow run dev_org --org dev` to deploy this project.
3. Run `cci org browser dev` to open the org in your browser.
