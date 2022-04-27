public class SFE_LWCDatatableController {

    /* ===========================  Constants =========================== */

    private static final String SPACE = ' ';
    private static final String CUSTOM_SUBSTRING = '__c';
    private static final List<String> SORTABLE_APEX_TYPES = new List<String>{
            'ID',
            'STRING',
            'TEXTAREA',
            'DOUBLE',
            'INTEGER',
            'CURRENCY',
            'DATE',
            'TIME',
            'DATETIME'
    };
//    private static final Set<String> PICKLISTS = new Set<String>{'PICKLIST', 'MULTIPICKLIST'};
//    this set will be needed for further filtering

    /* ===========================  Public methods (@AuraEnabled) =========================== */

    /**
     * @description get object Label
     * @param objectName (String): object API Name
     * @return String instance
     * @example
     * String label = getObjectLabel('Account');
     */
    @AuraEnabled(Cacheable=true)
    public static String getObjectLabel(String objectName) {
        try {
            List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{objectName});
            return !describeSobjectsResult.isEmpty() ? describeSobjectsResult[0].getLabel() : null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description generate columns to build LWC Data Table
     * @param objectName (String): object API Name
     * @return List of Column instances
     * @example
     * List<Column> columns = getColumns('Account');
     */
    @AuraEnabled(Cacheable=true)
    public static List<Column> getColumns(String objectName) {
        System.debug('object name (columns): ' + objectName);
        List<Column> columns = new List<Column>();
        DescribeSObjectResult getDescribeObj;

        try {
            getDescribeObj = Schema.getGlobalDescribe().get(objectName).getDescribe();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        Map<String, FieldSet> mapOfFieldSets = new Map<String, FieldSet>();
        mapOfFieldSets = getDescribeObj.fieldSets.getMap(); // get map of Field Sets for provided obj

        Map<String, Schema.SObjectField> mapOfFields = new Map<String, SObjectField>();
        mapOfFields = getDescribeObj.fields.getMap(); // get map of Fields for provided obj

        // if no field sets - return only standard object's fields
        // else return fields from Field Set with the name 'obj + List'
        if (mapOfFieldSets.isEmpty()){

            for (Schema.SObjectField sObjField : mapOfFields.values()) {

                DescribeFieldResult getDescribeField = sObjField.getDescribe();

                String label;
                String fieldName = String.valueOf(sObjField);
                String jsType;
                String apexType = String.valueOf(getDescribeField.type);
                Boolean sortable = false;
                Boolean isId =
                        apexType.equalsIgnoreCase('ID') ||
                                fieldName.containsIgnoreCase('ID') ||
                                getDescribeField.isExternalId();

                if (!fieldName.containsIgnoreCase(CUSTOM_SUBSTRING)) {

                    label = getDescribeField.label;
                    jsType = SFE_LWCDatatableHelper.convertApexTypeToJS(apexType.toLowerCase());
                    sortable = SORTABLE_APEX_TYPES.contains(apexType);

                    Column column = new Column(label, fieldName, jsType, apexType, sortable, isId);
                    columns.add(column);
                }
            }
        } else {

            String fieldSetListName = objectName.substringBefore(CUSTOM_SUBSTRING) + 'List';
            Schema.FieldSet fieldSet = mapOfFieldSets.get(fieldSetListName); // get Field Set with the name 'obj + List' (AccountList)

            String label;
            String fieldName;
            String jsType;
            String apexType;
            Boolean sortable = false;
            Boolean isId = false;

            for (Schema.FieldSetMember field : fieldSet.getFields()){

                label = field.getLabel();
                fieldName = field.getFieldPath();
                apexType = String.valueOf(field.getType());
                jsType = SFE_LWCDatatableHelper.convertApexTypeToJS(apexType.toLowerCase());
                sortable = SORTABLE_APEX_TYPES.contains(apexType);
                isId =
                        apexType.equalsIgnoreCase('ID') ||
                                fieldName.containsIgnoreCase('ID');

                Column column = new Column(label, fieldName, jsType, apexType, sortable, isId);
                columns.add(column);
            }
        }

        return columns;
    }

    /**
     * @description generate columns to build LWC Data Table
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param apexFieldTypes (List<String>): list of apex types for each field
     * @param objectName (String): object API Name
     * @param chunkSize (Integer): limit number of records to return using query
     * @param lastTableRowId (Id): last Id displayed in the Data Table
     * @param sortedBy (String): sorted by field name (e.g. 'Name')
     * @param sortedDirection (String): sorted direction (asc or desc)
     * @param searchKey (String): search key using to filter data
     * @param isSorted (Boolean): using to check if data table is sorted
     * @param isFiltered (Boolean): using to check if data table is filtered
     * @return TableDataWrapper instance
     */
    @AuraEnabled
    public static TableDataWrapper handleDataLoad(
            List<String> fieldsToQuery,
            List<String> apexFieldTypes,
            String objectName,
            Integer chunkSize,
            Id lastTableRowId,
            String sortedBy,
            String sortedDirection,
            String searchKey,
            Boolean isSorted,
            Boolean isFiltered
    ) {

        TableDataWrapper dataWrapper = new TableDataWrapper();

        if (isSorted && isFiltered) {
            dataWrapper = sortFilteredData(fieldsToQuery, apexFieldTypes, objectName, chunkSize, lastTableRowId, searchKey, sortedBy, sortedDirection);
        } else if(isFiltered) {
            dataWrapper = filterData(fieldsToQuery, apexFieldTypes, objectName, chunkSize, lastTableRowId, searchKey);
        } else if(isSorted) {
            dataWrapper = sortData(fieldsToQuery, objectName, chunkSize, lastTableRowId, sortedBy, sortedDirection);
        } else {
            dataWrapper = loadData(fieldsToQuery, objectName, chunkSize, lastTableRowId);
        }

        dataWrapper.totalNumberOfRecords = SFE_LWCDatatableHelper.getTotalNumberOfRecords(fieldsToQuery, apexFieldTypes, objectName, searchKey, isFiltered);
        dataWrapper.lastModifiedDatetime = SFE_LWCDatatableHelper.getLastModifiedDatetime(objectName);

        return dataWrapper;
    }

    /**
     * @description load data for the first and subsequent times
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param objectName (String): object API Name
     * @param chunkSize (Integer): limit number of records to return using query
     * @param lastTableRowId (Id): last Id displayed in the Data Table
     * @return TableDataWrapper instance
     */
    @AuraEnabled
    public static TableDataWrapper loadData(List<String> fieldsToQuery, String objectName, Integer chunkSize, Id lastTableRowId) {

        TableDataWrapper wrappedData = new TableDataWrapper();
        List<SObject> data = new List<SObject>();
        List<SObject> chunkedData = new List<SObject>();

        Boolean isFirstLoad = String.isEmpty(lastTableRowId);

        SFE_LWCDatatableQueryGenerator SFE_LWCDatatableQueryGenerator = new SFE_LWCDatatableQueryGenerator();
        String selectQueryString = SFE_LWCDatatableQueryGenerator.generateSelectSOQLCondition(fieldsToQuery);
        String fromQueryString = SFE_LWCDatatableQueryGenerator.generateFromSOQLCondition(objectName);
        String whereQueryString = SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(lastTableRowId, true);
        String orderByQueryString = SFE_LWCDatatableQueryGenerator.generateOrderBySOQLCondition('Id', 'ASC');
        String limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize);

        if (isFirstLoad) {
            String queryString =
                    selectQueryString + ' '+
                            fromQueryString + ' ' +
                            orderByQueryString;
            SObject firstTableRowRecord = SFE_LWCDatatableHelper.getFirstTableRowRecord(queryString);
            lastTableRowId = firstTableRowRecord.Id;
            data.add(firstTableRowRecord);
            whereQueryString = SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(lastTableRowId, true);
            limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize-1);
        }

        String queryString =
                selectQueryString + SPACE +
                        fromQueryString + SPACE +
                        whereQueryString + SPACE +
                        orderByQueryString + SPACE +
                        limitQueryString;

        try {
            chunkedData = Database.query(queryString);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        data.addAll(chunkedData);
        wrappedData.data = data;

        lastTableRowId =
                !data.isEmpty() ?
                        data[data.size()-1].Id :
                        lastTableRowId;
        wrappedData.lastId = lastTableRowId;

        return wrappedData;
    }

    /**
     * @description sort data for the first and subsequent times
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param objectName (String): object API Name
     * @param chunkSize (Integer): limit number of records to return using query
     * @param lastTableRowId (Id): last Id displayed in the Data Table
     * @param sortedBy (String): sorted by field name (e.g. 'Name')
     * @param sortedDirection (String): sorted direction (asc or desc)
     * @return TableDataWrapper instance
     */
    @AuraEnabled
    public static TableDataWrapper sortData(List<String> fieldsToQuery, String objectName, Integer chunkSize, Id lastTableRowId, String sortedBy, String sortedDirection) {

        TableDataWrapper dataWrapper = new TableDataWrapper();
        List<SObject> data = new List<SObject>();
        List<SObject> chunkedData = new List<SObject>();

        Boolean isFirstLoad = String.isEmpty(lastTableRowId);
        String directionOperator = sortedDirection == 'asc' ? '>' : '<';
        Object lastTableRowValue = lastTableRowId;
        SObject lastTableRowRecord;

        SFE_LWCDatatableQueryGenerator SFE_LWCDatatableQueryGenerator = new SFE_LWCDatatableQueryGenerator();
        String selectQueryString = SFE_LWCDatatableQueryGenerator.generateSelectSOQLCondition(fieldsToQuery);
        String fromQueryString = SFE_LWCDatatableQueryGenerator.generateFromSOQLCondition(objectName);
        String whereQueryString = SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(sortedBy, directionOperator, true);
        String orderByQueryString = SFE_LWCDatatableQueryGenerator.generateOrderBySOQLCondition(sortedBy, sortedDirection);
        String limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize);

        if(isFirstLoad){
            String queryString =
                    selectQueryString + SPACE+
                            fromQueryString + SPACE +
                            orderByQueryString;
            SObject firstTableRowRecord = SFE_LWCDatatableHelper.getFirstTableRowRecord(queryString);
            data.add(firstTableRowRecord);
            lastTableRowId = firstTableRowRecord.Id;
            limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize-1);
        }

        lastTableRowRecord = SFE_LWCDatatableHelper.getLastTableRowRecord(sortedBy, objectName, lastTableRowId);
        lastTableRowValue = lastTableRowRecord.get(sortedBy);

        String queryString =
                selectQueryString + SPACE +
                        fromQueryString + SPACE +
                        whereQueryString + SPACE +
                        orderByQueryString + SPACE +
                        limitQueryString;

        try {
            chunkedData = Database.query(queryString);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        data.addAll(chunkedData);
        dataWrapper.data = data;

        lastTableRowId =
                !data.isEmpty() ?
                        data[data.size()-1].Id :
                        lastTableRowId;
        dataWrapper.lastId = lastTableRowId;

        return dataWrapper;
    }

    /**
     * @description filter data for the first and subsequent times
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param apexFieldTypes (List<String>): list of fields to use in query
     * @param objectName (String): object API Name
     * @param chunkSize (Integer): limit number of records to return using query
     * @param lastTableRowId (Id): last Id displayed in the Data Table
     * @param searchKey (String): search key using to filter data
     * @return TableDataWrapper instance
     */
    @AuraEnabled
    public static TableDataWrapper filterData(List<String> fieldsToQuery, List<String> apexFieldTypes, String objectName, Integer chunkSize, Id lastTableRowId,  String searchKey) {

        TableDataWrapper dataWrapper = new TableDataWrapper();
        List<SObject> data = new List<SObject>();
        List<SObject> chunkedData = new List<SObject>();

        Boolean isFirstLoad = String.isEmpty(lastTableRowId);

        SFE_LWCDatatableQueryGenerator SFE_LWCDatatableQueryGenerator = new SFE_LWCDatatableQueryGenerator();
        String selectQueryString = SFE_LWCDatatableQueryGenerator.generateSelectSOQLCondition(fieldsToQuery);
        String fromQueryString = SFE_LWCDatatableQueryGenerator.generateFromSOQLCondition(objectName);
        String whereQueryString = SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(fieldsToQuery, apexFieldTypes, searchKey);
        String orderByQueryString = SFE_LWCDatatableQueryGenerator.generateOrderBySOQLCondition('Id', 'ASC');
        String limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize);

        if(isFirstLoad) {
            String queryString =
                    selectQueryString + SPACE +
                            fromQueryString + SPACE +
                            whereQueryString + SPACE +
                            orderByQueryString;
            SObject firstTableRowRecord = SFE_LWCDatatableHelper.getFirstTableRowRecord(queryString);
            if (firstTableRowRecord == null) {
                dataWrapper.data = data;
                dataWrapper.lastId = null;
                return dataWrapper;
            }
            data.add(firstTableRowRecord);
            lastTableRowId = firstTableRowRecord.Id;
            limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize-1);
        }

        whereQueryString += SPACE + SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(lastTableRowId, false);

        String queryString =
                selectQueryString + SPACE +
                        fromQueryString + SPACE +
                        whereQueryString + SPACE +
                        orderByQueryString + SPACE +
                        limitQueryString;

        try {
            chunkedData = Database.query(queryString);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        data.addAll(chunkedData);
        dataWrapper.data = data;

        lastTableRowId =
                !data.isEmpty() ?
                        data[data.size()-1].Id :
                        lastTableRowId;
        dataWrapper.lastId = lastTableRowId;

        return dataWrapper;
    }

    /**
     * @description sort filtered data for the first and subsequent times
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param apexFieldTypes (List<String>): list of apex types for each field
     * @param objectName (String): object API Name
     * @param chunkSize (Integer): limit number of records to return using query
     * @param lastTableRowId (Id): last Id displayed in the Data Table
     * @param searchKey (String): search key using to filter data
     * @param sortedBy (String): sorted by field name (e.g. 'Name')
     * @param sortedDirection (String): sorted direction (asc or desc)
     * @return TableDataWrapper instance
     */
    @AuraEnabled
    public static TableDataWrapper sortFilteredData(List<String> fieldsToQuery, List<String> apexFieldTypes, String objectName, Integer chunkSize, Id lastTableRowId,  String searchKey, String sortedBy, String sortedDirection) {

        TableDataWrapper wrappedData = new TableDataWrapper();
        List<SObject> data = new List<SObject>();
        List<SObject> chunkedData = new List<SObject>();

        Boolean isFirstLoad = String.isEmpty(lastTableRowId);
        String directionOperator = sortedDirection == 'asc' ? '>' : '<';
        Object lastTableRowValue = lastTableRowId;
        SObject lastTableRowRecord;

        SFE_LWCDatatableQueryGenerator SFE_LWCDatatableQueryGenerator = new SFE_LWCDatatableQueryGenerator();
        String selectQueryString = SFE_LWCDatatableQueryGenerator.generateSelectSOQLCondition(fieldsToQuery);
        String fromQueryString = SFE_LWCDatatableQueryGenerator.generateFromSOQLCondition(objectName);
        String whereQueryString = SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(fieldsToQuery, apexFieldTypes, searchKey);
        String orderByQueryString = SFE_LWCDatatableQueryGenerator.generateOrderBySOQLCondition(sortedBy, sortedDirection);
        String limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize);

        if(isFirstLoad){
            String queryString =
                    selectQueryString + SPACE+
                            fromQueryString + SPACE +
                            whereQueryString + SPACE +
                            orderByQueryString;
            SObject firstTableRowRecord = SFE_LWCDatatableHelper.getFirstTableRowRecord(queryString);
            data.add(firstTableRowRecord);
            lastTableRowId = firstTableRowRecord.Id;
            limitQueryString = SFE_LWCDatatableQueryGenerator.generateLimitSOQLCondition(chunkSize-1);
        }

        lastTableRowRecord = SFE_LWCDatatableHelper.getLastTableRowRecord(sortedBy, objectName, lastTableRowId);
        lastTableRowValue = lastTableRowRecord.get(sortedBy);

        whereQueryString += SPACE + SFE_LWCDatatableQueryGenerator.generateWhereSOQLCondition(sortedBy, directionOperator, false);

        String queryString =
                selectQueryString + SPACE +
                        fromQueryString + SPACE +
                        whereQueryString + SPACE +
                        orderByQueryString + SPACE +
                        limitQueryString;

        try {
            chunkedData = Database.query(queryString);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        data.addAll(chunkedData);
        wrappedData.data = data;

        lastTableRowId =
                !data.isEmpty() ?
                        data[data.size()-1].Id :
                        lastTableRowId;
        wrappedData.lastId = lastTableRowId;

        return wrappedData;
    }

    /**
     * @description delete row record by Id
     * @param recordId (Id): Id of the record to delete
     */
    @AuraEnabled
    public static void deleteRowRecord(Id recordId){
        try {
            SObject sobjectToDelete = recordId.getSobjectType().newSObject(recordId);
            delete sobjectToDelete;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /* ===========================  Wrappers =========================== */

    // Wrapper using to send data (rows) to datatable
    public class TableDataWrapper {

        @AuraEnabled
        public List<SObject> data;
        @AuraEnabled
        public Id lastId;
        @AuraEnabled
        public Integer totalNumberOfRecords;
        @AuraEnabled
        public String lastModifiedDatetime;

        public TableDataWrapper(List<SObject> data, Id lastId, String lastModifiedDatetime) {

            this.data = data;
            this.lastId = lastId;
            this.lastModifiedDatetime = lastModifiedDatetime;
        }

        public TableDataWrapper() {
            this(new List<SObject>(), null, 'NULL');
        }
    }

    // Wrapper using to build columns in datatable
    public class Column {

        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Boolean sortable;
        @AuraEnabled
        public Boolean isId;
        @AuraEnabled
        public String apexType;

        public Column(
                String label,
                String fieldName,
                String type,
                String apexType,
                Boolean sortable,
                Boolean isId
        ) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
            this.apexType = apexType;
            this.sortable = sortable;
            this.isId = isId;
        }
    }
}