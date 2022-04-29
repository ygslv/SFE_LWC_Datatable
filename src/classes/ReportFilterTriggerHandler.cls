public class ReportFilterTriggerHandler {

    public static void onBeforeInsert(List<Report_Filter__c> reportFilterList) {

        areObjectAndFieldEnteredCorrectly(reportFilterList);
    }

    public static void onBeforeUpdate(List<Report_Filter__c> reportFilterList) {

        areObjectAndFieldEnteredCorrectly(reportFilterList);
    }

    public static void areObjectAndFieldEnteredCorrectly(List<Report_Filter__c> reportFilterList) {

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<String> objectList = getListOfObjects(globalDescribe);

        for (Report_Filter__c reportFilter : reportFilterList) {
            if(!objectList.contains(reportFilter.Object_Name__c.toLowerCase())) {
                reportFilter.Object_Name__c.addError('Such an object does not exist in the current organization');
                } else {
                    if(!getSetOfObjectFields(globalDescribe, reportFilter.Object_Name__c).contains(reportFilter.Field_Name__c.toLowerCase())) {
                        reportFilter.Field_Name__c.addError('Such a field name does not exist for chosen object');
                }
            }
        }
    }

    public static List<String> getListOfObjects(Map<String, Schema.SObjectType> globalDescribe) {

        List<String> objectList = new List<String>();

        for(Schema.SObjectType objectName : globalDescribe.values()) {
            objectList.add(String.valueOf(objectName).toLowerCase());
        }

        return objectList;
    }

   public static Set<String> getSetOfObjectFields(Map<String, Schema.SObjectType> globalDescribe, String objectName) {
        Map<String, SObjectField> fieldMap = globalDescribe.get(objectName).getDescribe().fields.getMap();
        return fieldMap.keySet();
   }
}