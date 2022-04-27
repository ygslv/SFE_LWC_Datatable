public class SFE_LWCDatatableHelper {

    /* ===========================  Constants =========================== */

    private static final String SPACE = ' ';

    /* ===========================  Public methods =========================== */

    /**
     * @description get Javascript field type to build LWC Data Table column
     * @param apexType (String): apex record type
     * @return String instance
     * @example
     * String jsType = convertApexTypeToJS('string');
     */
    public static String convertApexTypeToJS(String apexType) {

        Map<String, String> apexToJSTypeMap = new Map<String, String>{
                'string' => 'text',
                'id' => 'text',
                'boolean' => 'boolean',
                'picklist' => 'text',
                'textarea' => 'text',
                'double' => 'number',
                'currency' => 'currency',
                'url' => 'url',
                'address' => 'text',
                'reference' => 'text'
        };

        return apexToJSTypeMap.get(apexType);
    }

    /**
     * @description get the total number of queried records
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param apexFieldTypes (List<String>): list of apex types for each field
     * @param objectName (String): object API Name
     * @param searchKey (String): search key using to filter data
     * @param isFiltered (Boolean): using to check if data table is filtered
     * @return Integer instance
     */
    public static Integer getTotalNumberOfRecords(List<String> fieldsToQuery, List<String> apexFieldTypes, String objectName, String searchKey, Boolean isFiltered) {

        Integer totalNumberOfRecords = 0;

        SFE_LWCDatatableQueryGenerator SFE_LWCDatatableQueryGenerator = new SFE_LWCDatatableQueryGenerator();
        String selectQueryString = SFE_LWCDatatableQueryGenerator.generateSelectSOQLCondition(new List<String>{'COUNT()'});
        String fromQueryString = SFE_LWCDatatableQueryGenerator.generateFromSOQLCondition(objectName);
        String whereQueryString = SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(fieldsToQuery, apexFieldTypes, searchKey);

        String queryString =
                isFiltered ?
                        selectQueryString + SPACE +
                                fromQueryString + SPACE +
                                whereQueryString :
                        selectQueryString + SPACE +
                                fromQueryString;

        try {
            totalNumberOfRecords = Database.countQuery(queryString);
            return totalNumberOfRecords;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description get first record displayed in the table
     * @param queryString (String): query string
     * @return SObject instance
     */
    public static SObject getFirstTableRowRecord(String queryString) {

        queryString += ' LIMIT 1';

        SObject firstTableRowRecord;
        List<SObject> firstTableRowRecordList = new List<SObject>();

        try {
            firstTableRowRecordList = Database.query(queryString);
            firstTableRowRecord = !firstTableRowRecordList.isEmpty() ? firstTableRowRecordList[0] : null;
            return firstTableRowRecord;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description get last record displayed in the table
     * @param sortedBy (String): sorted by field name (e.g. 'Name')
     * @param objectName (String): object API Name
     * @param lastTableRowId (Id): last Id displayed in the Data Table
     * @return SObject instance
     */
    public static SObject getLastTableRowRecord(String sortedBy, String objectName, Id lastTableRowId) {

        SObject lastTableRowRecord;
        List<SObject> lastTableRowRecordList = new List<SObject>();

        SFE_LWCDatatableQueryGenerator SFE_LWCDatatableQueryGenerator  = new SFE_LWCDatatableQueryGenerator();
        String selectQueryString = SFE_LWCDatatableQueryGenerator.generateSelectSOQLCondition(new List<String>{sortedBy});
        String fromQueryString = SFE_LWCDatatableQueryGenerator.generateFromSOQLCondition(objectName);
        String limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(1);

        String querySting =
                selectQueryString + SPACE +
                        fromQueryString + SPACE +
                        'WHERE Id =: lastTableRowId' + SPACE +
                        limitQueryString;

        try {
            lastTableRowRecordList = Database.query(querySting);
            lastTableRowRecord = !lastTableRowRecordList.isEmpty() ? lastTableRowRecordList[0] : null;
            return lastTableRowRecord;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description generate map where Key is field and value is apex type
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param apexFieldTypes (List<String>): list of apex types for each field
     * @return Map<String, String>
     */
    public static Map<String, String> generateFieldToTypeMap(List<String> fieldsToQuery, List<String> apexFieldTypes) {

        Map<String, String> fieldToTypeMap = new Map<String, String>();

        for (Integer i = 0, size = fieldsToQuery.size(); i < size; i++) {
            fieldToTypeMap.put(fieldsToQuery[i], apexFieldTypes[i]);
        }

        return fieldToTypeMap;
    }

    /**
     * @description get last modified date
     * @param objectName (String): object API Name
     * @return String instance
     */
    public static String getLastModifiedDatetime(String objectName) {

        String field = 'maxLastModifiedDate';
        List<String> fieldsToQuery = new List<String>{'MAX(LastModifiedDate) ' + field};
        SFE_LWCDatatableQueryGenerator SFE_LWCDatatableQueryGenerator = new SFE_LWCDatatableQueryGenerator();
        String selectQueryString = SFE_LWCDatatableQueryGenerator.generateSelectSOQLCondition(fieldsToQuery);
        String fromQueryString = SFE_LWCDatatableQueryGenerator.generateFromSOQLCondition(objectName);

        String queryString =
                selectQueryString + SPACE +
                        fromQueryString;

        try {

            List<SObject> listOfSObjects = Database.query(queryString);
            return
                    !listOfSObjects.isEmpty() ?
                            String.valueOf(listOfSObjects[0].get(field)) :
                            'Never';
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}