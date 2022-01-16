public without sharing class DynamicDataTableCompCtrl {
    
    private static Map<String,String> valueToLabelMap = new Map<String,String>();

/**
* @Author		: 	Or Moshe
* @Desciption 	: 	create data table
* @param 		: 	String fields, String objectName, String fieldsForFirstQuery, String recordId, String whereClouse, String refferenceFieldsToId
* @since		: 	03/08/2020
*/
    @AuraEnabled
    public static AuraResponse getDataTable(String fieldsForTable, String thisObjectName, String objectNameOfTable, String fieldsCurrentObject, String recordId, String whereClouse, 
                                            String whereClouseFieldsEncapsulation, String whereClouseValuesEncapsulation, String orderBy, String limitStr, String refferenceFieldsToId, Boolean getColumns){
       AuraResponse response = new AuraResponse();
        try{       
            Map<String, Schema.SObjectField> fieldMap = getFieldsMap(objectNameOfTable);
            List<String> fieldsList = fieldsForTable.split(',');
            
            Map<String, String> clickableFieldToRecordIdMap = createClickableFieldToRecordIdMap(refferenceFieldsToId);
            String referrenceFieldsStr = !clickableFieldToRecordIdMap.isEmpty() ? ', ' + String.join(clickableFieldToRecordIdMap.values(),',') : '';
            
            SObject currentRecord = getCurrentRecord(recordId, thisObjectName, fieldsCurrentObject); 
            List<String> paramsList = createQueryParamsList(fieldsCurrentObject, currentRecord);
           
            String query = createQuery(fieldsForTable, referrenceFieldsStr, objectNameOfTable, whereClouse, whereClouseFieldsEncapsulation, whereClouseValuesEncapsulation,/*columnApi,*/ orderBy, limitStr, paramsList);
        	List<SObject> sobjList = Database.query(query);
            
           	response.rowValuesInRows = createRows(sobjList, fieldsList, fieldMap, clickableFieldToRecordIdMap, objectNameOfTable, refferenceFieldsToId);
            if(getColumns){ // it mean that getDataTable called in the first time
                response.columnsList = createColumns(fieldsList, fieldMap, objectNameOfTable);
            }
        }catch(Exception e){
            response.isSuccess = false;
            response.errorTrace = e.getStackTraceString();
            response.message = e.getMessage();
            system.debug('ERROR MSG ' + e.getMessage());
        }
        return response;
    }
    
    /**
    * @Author		: 	Or Moshe
    * @Desciption 	: 	check I fUser Can Redirect
    * @since		: 	03/08/2020
    * @param 		: 	String recordId
    * @return		:	AuraResponse res
    */
    @AuraEnabled
    public static AuraResponse checkIfUserCanRedirect(Id recordId){
        AuraResponse res = new AuraResponse();
        UserRecordAccess access = [SELECT HasReadAccess, recordid
                                   FROM UserRecordAccess
                                   WHERE UserId =: UserInfo.getUserId() 
                                   AND RecordId =: recordId];
        if(!access.HasReadAccess) {
            res.isSuccess = false;
            res.message = Label.No_Permission1;
        }
        return res;
    }
    
    private static String createQuery(String fieldsForTable, String referrenceFieldsStr, String objectNameOfTable, String whereClouse, String whereClouseFieldsEncapsulation, String whereClouseValuesEncapsulation,
                                      String orderBy, String limitStr, List<String> paramsList){
        String query = 'SELECT ' +  fieldsForTable + referrenceFieldsStr + ' FROM ' + objectNameOfTable + ' ';
        if(String.isNotBlank(whereClouse)){
            query += ' WHERE ' + String.format(whereClouse, paramsList);
        }
        if(String.isNotBlank(whereClouseFieldsEncapsulation)){
            query += query.contains('WHERE') ? ' AND ' : ' WHERE ';
            query += createWhereClouseEnc(whereClouseFieldsEncapsulation, whereClouseValuesEncapsulation);
        }
        if(String.isNotBlank(orderBy)){
            query += ' ORDER BY ' + orderBy;
        } 
        if(String.isNotBlank(limitStr)){
            query += ' limit ' + limitStr;
        } 
        query = query.replaceAll('null', ' ');
        system.debug('###query' + query); 
        return query;
    }
    
    private static String createWhereClouseEnc(String whereClouseFieldsEncapsulation, String whereClouseValuesEncapsulation){
        if(String.isBlank(whereClouseValuesEncapsulation)){
            throw new CustomException('if you filled whereClouseFieldsEncapsulation, you need to fil lwhereClouseValuesEncapsulatio in format of *,*,...');
        }
        List<String> valuesList = whereClouseValuesEncapsulation.split(',');
        List<String> fieldsWithQuotesList = new List<String>();
        system.debug('valuesList ' + valuesList);
        for(String value : valuesList){
            fieldsWithQuotesList.add('\'' + value + '\'');
        }
        String whereClouseEnc = String.format(whereClouseFieldsEncapsulation, fieldsWithQuotesList);
        system.debug('whereClouseEnc ' + whereClouseEnc);
        return whereClouseEnc.replaceAll(',', ' AND ');
    }
    
    /**
* @Author		: 	Or Moshe
* @Desciption 	: 	query current record for getting values to query param for main query
* @since		: 	03/08/2020
* @param 		: 	String recordId, String objectName, String fieldsForFirstQuery
* @return		:	SObject Database.query(query)[0]
*/
    private static SObject getCurrentRecord(String recordId, String thisObjectName, String fieldsCurrentObject){
        if(String.isNotBlank(fieldsCurrentObject)){
            String query = 'SELECT ' +  fieldsCurrentObject + ' FROM ' + thisObjectName +  ' WHERE Id = ' + '\'' + String.escapeSingleQuotes(recordId) + '\'' ;
            system.debug('query1' + query);
            return Database.query(query)[0]; 
        }else{
            return null;
        }
    }
    
    private static List<String> createQueryParamsList(String params, SObject currentRecord){
        List<String> paramsValuesList = new List<String>();
        if(currentRecord != null){
            List<String> paramsList = params.split(',');
            String valueParam = '', valueOfFieldInLookup = '', fieldInLookup, lookupField;
            for(String param : paramsList){
                param = param.trim();
                if(param.contains('.')){
                    fieldInLookup = param.substringAfter('.');
                    lookupField = param.substringBefore('.');
                    if(currentRecord.getSObject(lookupField).get(fieldInLookup) != null){
                        valueOfFieldInLookup = String.valueOf(currentRecord.getSObject(lookupField).get(fieldInLookup));
                    }
                }
                valueParam = valueOfFieldInLookup == '' ? String.valueOf(currentRecord.get(param)) : valueOfFieldInLookup;
                if(valueParam == null){
                    String errorMsg = 'please make sure that there is value in: ';
                    errorMsg += valueOfFieldInLookup != '' ?  + fieldInLookup + 'in ' + lookupField : param;
                    throw new CustomException(errorMsg);
                }
                paramsValuesList.add('\'' + String.escapeSingleQuotes(valueParam) + '\'');
                valueOfFieldInLookup = '';
            }
        }
        return paramsValuesList;
    }
    
    /**
* @Author		: 	Or Moshe
* @Desciption 	: 	create map of fields that not refference to id due to be clickable
* @since		: 	03/08/2020
* @param 		: 	String recordId, String objectName, String fieldsForFirstQuery
* @return		:	Map<String, String> clickableFieldToRecordIdMap
*/
    private static Map<String, String> createClickableFieldToRecordIdMap(String refferenceFieldsToId){
        Map<String, String> clickableFieldToRecordIdMap = new Map<String, String>();
        system.debug('refferenceFieldsToId ' + refferenceFieldsToId);
        if(String.isNotBlank(refferenceFieldsToId)){
            List<String> clickFieldAndIdsList = refferenceFieldsToId.split(',');
            if(math.mod(clickFieldAndIdsList.size(), 2) != 0){
                throw new CustomException('You need to feel refference fields input in format of *,*,...');
            }
            Integer i=0;
            while(i <= clickFieldAndIdsList.size()-2){
                String key = clickFieldAndIdsList[i].trim();
                String value = clickFieldAndIdsList[i+1].trim();
                clickableFieldToRecordIdMap.put(key, value);
                i += 2;
            }
        }        
        system.debug('clickableFieldToRecordIdMap' + clickableFieldToRecordIdMap);
        return clickableFieldToRecordIdMap;
    }
   
    private static String removeToLabel(String fieldName){
        if(fieldName.contains('toLabel')){
            fieldName = fieldName.replace('toLabel', '');
            fieldName = fieldName.replace('(', '');
            fieldName = fieldName.replace(')', '');
        }
        return fieldName.trim();
    }
    
    /**
* @Author		: 	Or Moshe
* @Desciption 	: 	create rows for data table dynamicaly
* @since		: 	03/08/2020
* @param 		: 	List<SObject> sobjList, List<String> fieldsList, Map<String, String> clickableFieldToRecordIdMap, String objectName, String refferenceFieldsToId
* @return		:	List<List<Row>> rowValuesInRows
*/
    private static List<List<Row>> createRows(List<SObject> sobjList, List<String> fieldsList, Map<String, Schema.SObjectField> fieldMap, Map<String, String> clickableFieldToRecordIdMap, String objectNameForQuery, String refferenceFieldsToId){
        List<List<Row>> rowValuesInRows = new List<List<Row>>();
        List<Row> rowsList;
        for(SObject sobjItem : sobjList){
            rowsList = new List<Row>();
            Row r;
            Boolean isRefference;
            String idForLink, fieldType;
            for(String fieldName : fieldsList){
                fieldName = removeToLabel(fieldName);
                Schema.SObjectField scf = fieldMap.get(fieldName);
                Object valueOfFieldInLookup;
                if(scf == null){
                    if(fieldName.contains('.')){
                        String lookupField = fieldName.substringBefore('.');
                        String fieldInLookup = fieldName.substringAfter('.');
                        valueOfFieldInLookup = sobjItem.getSObject(lookupField).get(fieldInLookup);
                        scf = fieldMap.get(lookupField);
                        if(scf == null){
                            fieldName = lookupField.contains('__r') ? lookupField.replace('__r', '__c') : lookupField + 'Id';
                        }
                    }
                }
                Object value;               
                if(valueOfFieldInLookup != null){
                    value = valueOfFieldInLookup;
                    idForLink = (String)sobjItem.get(fieldName);
                    isRefference = true;
                }else if(clickableFieldToRecordIdMap.containsKey(fieldName)){
                    value = sobjItem.get(fieldName);
                    idForLink = (String)sobjItem.get(clickableFieldToRecordIdMap.get(fieldName));
                    isRefference = true;
                }else{
                    value = sobjItem.get(fieldName);
                    idForLink = '';
                    isRefference = false;
                }
                fieldType = String.valueOf(fieldMap.get(fieldName).getDescribe().getType());
                if(fieldType == 'DATETIME' || fieldType == 'DATE'){
                    Datetime dt = (Datetime) value;
                    value = dt.day() + '/' + dt.month() + '/' + dt.year();
                }else if(fieldType == 'PICKLIST'){
                    system.debug('fieldName ' + fieldName);
                    system.debug('value ' + value);
                }   
                r = new Row(fieldName, value, isRefference, idForLink);
                rowsList.add(r);
            }
            rowValuesInRows.add(rowsList);
        }
        return rowValuesInRows;
    } 
    
    /**
* @Author		: 	Or Moshe
* @Desciption 	: 	create columns for data table dynamicaly
* @since		: 	03/08/2020
* @param 		: 	List<String> fieldsList, String objectName
* @return		:	List<List<Row>> rowValuesInRows
*/
   private static List<Column> createColumns(List<String> fieldsList, Map<String, Schema.SObjectField> fieldMap, String objectNameForQuery){
       List<Column> columnsList = new List<Column>();
        for (String fieldName : fieldsList) {
			fieldName = removeToLabel(fieldName);
            Schema.SObjectField scf = fieldMap.get(fieldName);
            String fieldLabel, fieldType;
            if(scf == null){
                if(fieldName.contains('.')){
                 	fieldName = fieldName.substringBefore('.'); 
                    if(fieldName.contains('__r')){
                        fieldName = fieldName.replace('__r', '__c');
                    }
                    scf = fieldMap.get(fieldName);
                    if(scf == null){
                        fieldName = fieldName + 'Id';
                    }
                }
                scf = fieldMap.get(fieldName);
                if(scf == null){
                  throw new CustomException('You filled wrong fields');  
                }
                fieldLabel = scf.getDescribe().getLabel();
            }else{
               fieldLabel = scf.getDescribe().getLabel();
            }

            columnsList.add(new Column(fieldName, fieldLabel, String.valueOf(scf.getDescribe().getType())));
        }
        return columnsList;
    }
    
    private static Map<String, Schema.SObjectField> getFieldsMap(String objectName){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType sobSchema = schemaMap.get(objectName);
        if(sobSchema == null){
            throw new CustomException('Please Correct object Name For Query' + objectName);
        }
        return sobSchema.getDescribe().fields.getMap();
    }
    
	public class AuraResponse{
		@AuraEnabled public List<Column> columnsList					{get;set;}
        @AuraEnabled public List<List<Row>> rowValuesInRows				{get;set;}
        @AuraEnabled public Boolean isSuccess 							{get;set;}
		@AuraEnabled public String message 								{get;set;}
		@AuraEnabled public String errorTrace 							{get;set;}
        
        public AuraResponse(){
            this.isSuccess = true;
        }
	}
    
    public class Column{
        @AuraEnabled public String fieldName 							{get;set;}
        @AuraEnabled public String label								{get;set;}
        @AuraEnabled public String fieldType							{get;set;}
        
        public Column(String fieldName, String label, String fieldType){
            this.fieldName = fieldName;
            this.label = label;
            this.fieldType = fieldType;
        }
    }

    public class Row{
        @AuraEnabled public String fieldName 							{get;set;}
        @AuraEnabled public Object value	 							{get;set;}
        @AuraEnabled public Boolean isRefference						{get;set;}
        @AuraEnabled public String idForLink							{get;set;}

        public Row(String fieldName, Object value, Boolean isRefference, String idForLink){
            this.fieldName = fieldName;
            this.value = value;
            this.isRefference = isRefference;
            this.idForLink = idForLink;
        }
    }
    
    private class CustomException extends Exception{}
}