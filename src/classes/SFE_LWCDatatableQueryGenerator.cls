public class SFE_LWCDatatableQueryGenerator {

    /* ===========================  Constants =========================== */

    private static final String SPACE = ' ';
    private static final String COMMA = ',';

    /* ===========================  Public methods =========================== */

    /**
     * @description generate SELECT part of SOQL
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @return String instance
     */
    public String generateSelectSOQLCondition(List<String> fieldsToQuery) {
        return 'SELECT ' + String.join(fieldsToQuery, COMMA);
    }

    /**
     * @description generate FROM part of SOQL
     * @param objectName (String): object API Name
     * @return String instance
     */
    public String generateFromSOQLCondition(String objectName) {
        return 'FROM ' + objectName;
    }

    /**
     * @description generate WHERE part of SOQL to filter data
     * @param fieldsToQuery (List<String>): list of fields to use in query
     * @param apexFieldTypes (List<String>): list of apex types for each field
     * @param searchKey (String): search key using to filter data
     * @return String instance
     */
    public String generateWhereSOQLCondition(List<String> fieldsToQuery, List<String> apexFieldTypes, String searchKey) {

        Map<String, String> fieldToTypeMap = SFE_LWCDatatableHelper.generateFieldToTypeMap(fieldsToQuery, apexFieldTypes);

        String whereSOQLCondition = 'WHERE (';

        for (String fieldName : fieldToTypeMap.keySet()) {

            String fieldType = fieldToTypeMap.get(fieldName);

            if (fieldType.equalsIgnoreCase('STRING')) {
                whereSOQLCondition += fieldName + ' LIKE ' + '\'%' + searchKey + '%\'' + ' OR ';
            } else if (fieldType.equalsIgnoreCase('INTEGER') && fieldType.equalsIgnoreCase('DOUBLE') && searchKey.isNumeric()) {
                whereSOQLCondition += fieldName + ' = ' + searchKey + ' OR ';
            }
        }

        whereSOQLCondition = whereSOQLCondition.removeEnd(' OR ') + ') ';

        return whereSOQLCondition;
    }

    /**
     * @description generate WHERE part of SOQL to sort data
     * @param sortedBy (String): sorted by field name (e.g. 'Name')
     * @param directionOperator (String): direction operator (e.g. < or >)
     * @param isFirstWhereCondition (Boolean): used to start condition with WHERE or AND
     * @return String instance
     */
    public String generateWhereSOQLCondition(String sortedBy, String directionOperator, Boolean isFirstWhereCondition) {

        return (isFirstWhereCondition ? 'WHERE (' : 'AND (') +
                sortedBy + SPACE + directionOperator + ' :lastTableRowValue ' +
                'OR (' + sortedBy + ' = :lastTableRowValue AND Id > :lastTableRowId))';
    }

    /**
     * @description generate WHERE part of SOQL to simple sort data
     * @param lastTableRowId (Id): last Id displayed in the Data Table
     * @param isFirstWhereCondition (Boolean): used to start condition with WHERE or AND
     * @return String instance
     */
    public String generateWhereSOQLCondition(Id lastTableRowId, Boolean isFirstWhereCondition) {
        return (isFirstWhereCondition ? 'WHERE ' : 'AND ') + 'Id > \'' + lastTableRowId + '\'';
    }

    /**
     * @description generate ORDER BY part of SOQL
     * @param sortedBy (String): sorted by field name (e.g. 'Name')
     * @param sortedDirection (String): sorted direction (asc or desc)
     * @return String instance
     */
    public String generateOrderBySOQLCondition(String sortedBy, String sortedDirection) {
        return 'ORDER BY ' + sortedBy + SPACE + sortedDirection + ', Id';
    }

    /**
     * @description generate ORDER BY part of SOQL
     * @param limitSize (Integer): limit number of records to return using query
     * @return String instance
     */
    public String generateLimitSOQLCondition(Integer limitSize) {
        return 'LIMIT ' + limitSize;
    }
}