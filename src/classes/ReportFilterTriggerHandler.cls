public class ReportFilterTriggerHandler {

    /* ===========================  Constants =========================== */

    private static final Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();

    /* ===========================  Trigger handlers =========================== */

    /**
     * @description Handle Before Insert trigger event
     * @param reportFilterList (List<Report_Filter__c>): Report_Filter__c instances
     */
    public static void onBeforeInsert(List<Report_Filter__c> reportFilterList) {
        onUpdateOrInsert(reportFilterList);
    }

    /**
     * @description Handle Before Update trigger event
     * @param reportFilterList (List<Report_Filter__c>): Report_Filter__c instances
     */
    public static void onBeforeUpdate(List<Report_Filter__c> reportFilterList) {
        onUpdateOrInsert(reportFilterList);
    }

    /**
     * @description Handle Before Update and Before Insert trigger events
     * @param reportFilterList (List<Report_Filter__c>): Report_Filter__c instances
     */
    public static void onUpdateOrInsert (List<Report_Filter__c> reportFilterList) {
        for (Report_Filter__c reportFilter : reportFilterList) {
            if (!isObjectNameCorrect(reportFilter)) {
                reportFilter.Object_Name__c.addError('Such an object does not exist in the current organization');
            } else if (!isFieldNameCorrect(reportFilter)){
                reportFilter.Field_Name__c.addError('Such a field name does not exist for chosen object');
            } else {
                DescribeFieldResult describeFieldResult = GLOBAL_DESCRIBE.get(reportFilter.Object_Name__c).getDescribe().fields.getMap().get(reportFilter.Field_Name__c).getDescribe();
                reportFilter.Field_Type__c = getFieldType(describeFieldResult);
                reportFilter.Field_Label__c = getFieldLabel(describeFieldResult);
                reportFilter.Is_Field_Required__c = isFieldRequired(describeFieldResult);
                reportFilter.Name = generateReportFilterName(reportFilter.Object_Name__c, reportFilter.Field_Name__c);
            }
        }
    }

    /* ===========================  Public methods =========================== */

    /**
     * @description Checking if entered Object Name is exist in current organization
     * @param reportFilter (Report_Filter__c): Report_Filter__c instance
     * @return Boolean instance
     */
    public static Boolean isObjectNameCorrect(Report_Filter__c reportFilter) {
        return getSetOfObjects().contains(reportFilter.Object_Name__c.toLowerCase());
    }

    /**
     * @description Checking if entered Field Name is exist in current organization
     * @param reportFilter (Report_Filter__c): Report_Filter__c instance
     * @return Boolean instance
     */
    public static Boolean isFieldNameCorrect(Report_Filter__c reportFilter) {
        return getSetOfFields(reportFilter.Object_Name__c).contains(reportFilter.Field_Name__c.toLowerCase());
    }

    /**
     * @description Checking if entered field is set as required
     * @param describeFieldResult (DescribeFieldResult): describe field based on Object Name and Field Name
     * @return Boolean instance
     */
    public static Boolean isFieldRequired(DescribeFieldResult describeFieldResult) {
        return !describeFieldResult.isNillable();
    }

    /**
     * @description Get field type for current Report_Filter__c instance (Based on Object and Field names)
     * @param describeFieldResult (DescribeFieldResult): describe field based on Object Name and Field Name
     * @return String instance
     */
    public static String getFieldType(DescribeFieldResult describeFieldResult) {
        return String.valueOf(describeFieldResult.getType()).toLowerCase().capitalize();
    }

    /**
     * @description Get field label for current Report_Filter__c instance (Based on Object and Field names)
     * @param describeFieldResult (DescribeFieldResult): describe field based on Object Name and Field Name
     * @return String instance
     */
    public static String getFieldLabel(DescribeFieldResult describeFieldResult) {
        return describeFieldResult.getLabel();
    }

    /**
     * @description Get set of all object's API names for current organization
     * @return String instances
     */
    public static Set<String> getSetOfObjects() {
        return GLOBAL_DESCRIBE.keySet();
    }

    /**
     * @description Get set of all field's API names for chosen object
     * @param objectName (String): Object API Name
     * @return String instances
     */
    public static Set<String> getSetOfFields(String objectName) {
        return GLOBAL_DESCRIBE.get(objectName).getDescribe().fields.getMap().keySet();
    }

    /**
     * @description Generate dynamic name for Report Filter instance
     * @param objectName (String): Object API Name
     * @param fieldName (String): Field API Name
     * @return String instances
     */
    public static String generateReportFilterName(String objectName, String fieldName) {
        return 'Report filter on ' + objectName + ' for ' + fieldName;
    }
}