trigger ReportFilterTrigger on Report_Filter__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ReportFilterTriggerHandler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ReportFilterTriggerHandler.onBeforeUpdate(Trigger.new);
        }
    }
}