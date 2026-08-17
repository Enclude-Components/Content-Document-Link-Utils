trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert) {
    ContentDocLinkVisibilityHandler.applyVisibility(Trigger.new);
}
