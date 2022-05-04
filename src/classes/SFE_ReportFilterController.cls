public class SFE_ReportFilterController {

    @AuraEnabled (Cacheable=true)
    public static List<ReportFilterData> getReportFilterData(String objectName) {

        List<Report_Filter__c> reportFilterList = SFE_ReportFilterHelper.getReportFilterList(objectName);
        //Map<String, List<String>> reportSavedFilterValueMap = getReportSavedFilterValueMap(objectName);
        Map<String, List<ReportFilterOption>> reportFilterOptionMap = SFE_ReportFilterHelper.generateReportFilterOptionMap(reportFilterList);
        List<ReportFilterData> reportFilterDataList = new List<ReportFilterData>();
        Metadata.Layout layout = SFE_ReportFilterHelper.getPageLayout(objectName);
        Map<String, String> fieldToSectionMap = SFE_ReportFilterHelper.generateFieldToSectionMap(layout);

        for (Report_Filter__c reportFilter : reportFilterList) {
            reportFilterDataList.add(new ReportFilterData(
                    objectName,
                    reportFilter.Field_Name__c,
                    reportFilter.Field_Label__c,
                    reportFilter.Field_Type__c,
                    new List<String>(),
                    reportFilterOptionMap.get(reportFilter.Field_Name__c),
                    reportFilter.Is_Field_Required__c,
                    fieldToSectionMap.get(reportFilter.Field_Name__c)
            ));
        }

        return reportFilterDataList;
    }

    public class ReportFilterData {

        @AuraEnabled
        public String objectName;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String fieldLabel;
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
                String fieldLabel,
                String fieldType,
                List<String> value,
                List<ReportFilterOption> options,
                Boolean required,
                String section
        ) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.value = value;
            this.options = options;
            this.required = required;
            this.section = section;
        }
    }

    // Wrapper using to create 'option' Object to use it in markup
    public class ReportFilterOption {

        @AuraEnabled
        public String value;
        @AuraEnabled
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
}