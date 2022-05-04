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

    public static Metadata.Layout getPageLayout(String objectName) {

        String objectLabel;
        String defaultPageLayout;

        List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{objectName});

        objectLabel = describeSobjectsResult[0].getLabel();
        defaultPageLayout = objectLabel + ' Layout';

        String layoutName = String.format('{0}-{1}', new String[]{objectName, defaultPageLayout});

        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);

        return layoutMd;
    }

    public static void generateSectionToFieldListMap(Metadata.Layout layout) {

        Map<String, List<String>> sectionToFieldListMap = new Map<String, List<String>>();

        for (Metadata.LayoutSection section : layout.layoutSections) {
            List<String> fields = new List<String>();
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        fields.add(String.valueOf(item.field));
                    }
                }
            }
            sectionToFieldListMap.put(String.valueOf(section.label), fields);
        }

    }

    public static Map<String, String> generateFieldToSectionMap(Metadata.Layout layout) {

        Map<String, String> sectionToFieldListMap = new Map<String, String>();

        for (Metadata.LayoutSection section : layout.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        sectionToFieldListMap.put(String.valueOf(item.field), String.valueOf(section.label));
                    }
                }
            }
        }

        return sectionToFieldListMap;
    }
}