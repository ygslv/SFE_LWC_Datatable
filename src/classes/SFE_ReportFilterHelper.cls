public class SFE_ReportFilterHelper {

    private static final Set<String> PICKLISTS = new Set<String>{'Picklist', 'Multipicklist'};

    public static Map<String, List<SFE_ReportFilterController.ReportFilterOption>> generateReportFilterOptionMap(List<Report_Filter__c> reportFilterList) {

        Map<String, List<SFE_ReportFilterController.ReportFilterOption>> reportFilterOptionMap = new Map<String, List<SFE_ReportFilterController.ReportFilterOption>>();

        for (Report_Filter__c reportFilter : reportFilterList) {
            List<SFE_ReportFilterController.ReportFilterOption> options = new List<SFE_ReportFilterController.ReportFilterOption>();
            if(PICKLISTS.contains(reportFilter.Field_Type__c)) {
                List<String> picklistValues = getPicklistValues(reportFilter.Object_Name__c, reportFilter.Field_Name__c);
                for (String value : picklistValues) {
                    options.add(new SFE_ReportFilterController.ReportFilterOption(value));
                }
            } else {
                options.add(new SFE_ReportFilterController.ReportFilterOption(reportFilter.Field_Label__c));
            }
            reportFilterOptionMap.put(reportFilter.Field_Name__c, options);
        }

        return reportFilterOptionMap;
    }

    public static List<Report_Filter__c> getReportFilterList(String objectName) {

        List<Report_Filter__c> reportFilterList = [
                SELECT
                        Object_Name__c,
                        Field_Name__c,
                        Field_Type__c,
                        Field_Label__c,
                        Field_Section__c,
                        Is_Field_Required__c
                FROM
                        Report_Filter__c
                WHERE
                        Object_Name__c =: objectName AND
                        Use_For_Filtering__c = TRUE
        ];
        return reportFilterList;
    }

    /**
     * @description return values from picklist
     * @param objectName (String): object API Name
     * @param fieldName (String): field API Name
     * @return String instances
     */
    public static List<String> getPicklistValues(String objectName, String fieldName) {

        List<String> pickListValues = new List<String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> pickListObjectsList = mapFields.get(fieldName).getDescribe().getPicklistValues();

        for (Schema.PicklistEntry pickListObj : pickListObjectsList) {
            pickListValues.add(pickListObj.getValue());
        }

        return pickListValues;
    }
}