public class SFE_ReportFilterHelper {

    private static final Set<String> PICKLISTS = new Set<String>{'Picklist', 'Multipicklist'};

    class ReportFilterData {

        @AuraEnabled
        public String objectName;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String fieldType;
        @AuraEnabled
        public List<String> value;
        @AuraEnabled
        public List<ReportFilterOption> options;
        @AuraEnabled
        public Boolean required;
        @AuraEnabled
        public String section;

        public ReportFilterData(
                String objectName,
                String fieldName,
                String fieldType,
                List<String> value,
                List<ReportFilterOption> options,
                Boolean required,
                String section
        ) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.fieldType = fieldType;
            this.value = value;
            this.options = options;
            this.required = required;
            this.section = section;
        }
    }

    // Wrapper using to create 'option' Object to use it in markup
    class ReportFilterOption {

        public String value;
        public String label;

        public ReportFilterOption(String value) {

            this.label = value;
            this.value = generateOptionValue(value);
        }

        public String generateOptionValue(String value) {

            String generatedValue = '';
            List<String> splitValue = value.split(' ');

            for(String s : splitValue) {
                generatedValue +=
                    splitValue.indexOf(s) == 0 ?
                    s.toLowerCase() :
                    s.toLowerCase().capitalize();
            }

            return generatedValue;
        }
    }

    public static List<ReportFilterData> generateReportFilterDataList(String objectName) {

        List<Report_Filter__c> reportFilterList = getReportFilterList(objectName);
        //Map<String, List<String>> reportSavedFilterValueMap = getReportSavedFilterValueMap(objectName);
        Map<String, List<ReportFilterOption>> reportFilterOptionMap = generateReportFilterOptionMap(reportFilterList);
        List<ReportFilterData> reportFilterDataList = new List<ReportFilterData>();

        for (Report_Filter__c reportFilter : reportFilterList) {
            reportFilterDataList.add(new ReportFilterData(
                    objectName,
                    reportFilter.Field_Name__c,
                    reportFilter.Field_Type__c,
                    new List<String>(),
                    reportFilterOptionMap.get(reportFilter.Field_Name__c),
                    true,
                    'Test section'
            ));
        }

        return reportFilterDataList;
    }

    public static Map<String, List<ReportFilterOption>> generateReportFilterOptionMap(List<Report_Filter__c> reportFilterList) {

        Map<String, List<ReportFilterOption>> reportFilterOptionMap = new Map<String, List<ReportFilterOption>>();

        for (Report_Filter__c reportFilter : reportFilterList) {
            if(PICKLISTS.contains(reportFilter.Field_Type__c)) {
                List<String> picklistValues = getPicklistValues(reportFilter.Object_Name__c, reportFilter.Field_Name__c);
                List<ReportFilterOption> options = new List<ReportFilterOption>();
                for (String value : picklistValues) {
                    options.add(new ReportFilterOption(value));
                }
                reportFilterOptionMap.put(reportFilter.Field_Name__c, options);
            } else if(reportFilter.Field_Type__c.equalsIgnoreCase('Boolean')) {

            }
        }

        return reportFilterOptionMap;
    }

    public static List<Report_Filter__c> getReportFilterList(String objectName) {

        List<Report_Filter__c> reportFilterList = [SELECT Object_Name__c, Field_Name__c, Field_Type__c FROM Report_Filter__c WHERE Object_Name__c =: objectName AND Use_For_Filtering__c = TRUE];
        return reportFilterList;
    }

//    public static Map<String, List<String>> getReportSavedFilterValueMap(String objectName) {
//
//        Id currentUserId = UserInfo.getUserId();
//        List<Report_Saved_Filter__c> reportSavedFilterList = [SELECT Filter_Data__c, Field_Name__c FROM Report_Saved_Filter__c WHERE Object_Name__c =: objectName AND Salesforce_User__c =: currentUserId];
//        Map<String, List<String>> reportSavedFilterNameToValueMap = new Map<String, List<String>>();
//
//        for (Report_Saved_Filter__c reportSavedFilter : reportSavedFilterList) {
//            reportSavedFilterNameToValueMap.put(reportSavedFilter.Field_Name__c, reportSavedFilter.Filter_Data__c);
//        }
//
//        return reportSavedFilterNameToValueMap;
//    }

//    TO FIND REQUIRED FIELDS:
//    Schema.DescribeSObjectResult r = systemObjectType.getDescribe();
//    Map<String,Schema.SObjectField> M = r.fields.getMap();
//    for(String fieldName : M.keySet())
//    {
//    Schema.SObjectField field = M.get(fieldName);
//    Schema.DescribeFieldResult F = field.getDescribe();
//    //A nillable field can have empty content. A isNillable Boolean non-nillable field must have a value for the object to be                       //created or saved.
//    // if F.isNillable() is false then field is mandatory
//    Boolean isFieldreq  = F.isNillable()

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