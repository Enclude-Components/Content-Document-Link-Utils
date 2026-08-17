trigger ContentDocumentLink on ContentDocumentLink (before insert) {
    ContentDocLinkVisibilityHandler.applyVisibility(Trigger.new);
}
