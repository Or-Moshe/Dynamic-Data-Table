({
	createTable : function(component, event, helper) {
        var action = component.get("c.getDataTable");
        action.setParams({
            'fieldsForTable' : component.get('v.fieldsForTable'),
            'thisObjectName' : component.get('v.objectName'),
            'objectNameOfTable' : component.get('v.objectNameForQuery'),
            'fieldsCurrentObject': component.get('v.fieldsForQueryCurrentRecord'),
            'recordId': component.get('v.recordId'),
            'whereClouse' : component.get('v.whereClouse'),
            'columnApi' : '',
            'orderBy' : '',
            'limitStr' : component.get('v.limit'),
            'refferenceFieldsToId': component.get('v.refferenceFieldsToId')
        });
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                var res = response.getReturnValue();
                console.log('res', res);
                if(res.isSuccess == true ){
                    component.set('v.isLoaded', true);
                    let columnToAmountClicks = {};
                    let pageToMapValues = {};
                    let arrayMapKeys = [];
                    let totalRowsInPage = parseInt(component.get('v.totalRowsInPage'));
                    let pageList = [];
                    let rowNum = 0;
                    let pageNum = 1;
                    let fieldNameToSearch = component.get('v.fieldNameToSearch');
                    let totalPages = Math.ceil(res.rowValuesInRows.length / totalRowsInPage);
                    for(let i=1; i<=totalPages; i++){
                        pageList.push(i);
                    }
                    for(var key in res.rowValuesInRows){
                        if(component.get('v.showSearch')){
                            let row = res.rowValuesInRows[key].find(o => o.fieldName === fieldNameToSearch);
                            arrayMapKeys.push({key: key, searchKey: row.value, value: res.rowValuesInRows[key]});
                        }else{
                            arrayMapKeys.push({key: key, value: res.rowValuesInRows[key]});
                        }
                        rowNum ++;
                        if(rowNum == totalRowsInPage){
                            pageToMapValues[pageNum] = arrayMapKeys; 
                            rowNum = 0;
                            pageNum ++;
                            arrayMapKeys = [];
                        }
                    }
                    res.columnsList.forEach(el => {
                        columnToAmountClicks[el.fieldName] = 0;
                    });
                      
                    pageToMapValues[pageNum ++] = arrayMapKeys; 
                    component.set("v.columnToAmountClicks", columnToAmountClicks); 
                    component.set("v.pageToMapValues", pageToMapValues);
                    component.set('v.oldPageToMapValues', component.get('v.pageToMapValues'));
                    component.set("v.pageList", pageList);
                    component.set("v.originPageList", pageList);    
                    component.set("v.totalPages", totalPages); 
                    component.set("v.mapValues", pageToMapValues[component.get('v.currentPageNumber')]); 
                    component.set('v.columns', res.columnsList);
                    component.set('v.rowNumToRow', res.rowValuesInRows);
                    console.log('pageToMapValues ', JSON.parse(JSON.stringify(pageToMapValues)));
                }else{
                    this.showToast(component, event, 'Error!', 'Error', res.message);
            	}
            }else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(component, event, 'Error!', 'Error', errors[0].message);
                    }
                } else {
                    console.error("Unknown error");
                }
            }
        });
        $A.enqueueAction(action); 
	},
                        
    orderTable : function(component, event, helper, fieldName, orderBy){
        var action = component.get("c.getDataTable");
        action.setParams({
            'fieldsForTable' : component.get('v.fieldsForTable'),
            'thisObjectName' : component.get('v.objectName'),
            'objectNameOfTable' : component.get('v.objectNameForQuery'),
            'fieldsCurrentObject': component.get('v.fieldsForQueryCurrentRecord'),
            'recordId': component.get('v.recordId'),
            'whereClouse' : component.get('v.whereClouse'),
            'columnApi' : fieldName,
            'orderBy' : orderBy,
            'limitStr' : component.get('v.limit'),
            'refferenceFieldsToId': component.get('v.refferenceFieldsToId')
        });
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                var res = response.getReturnValue();
                let arrayMapKeys = [];
                let pageToMapValues = {};
                let rowNum = 0;
                let pageNum = 1;
                let totalRowsInPage = parseInt(component.get('v.totalRowsInPage'));
                component.set("v.mapValues", []); 
                if(res.isSuccess == true ){
                    for(var key in res.rowValuesInRows){
                        arrayMapKeys.push({key: key, value: res.rowValuesInRows[key]});
                        rowNum ++;
                        if(rowNum == totalRowsInPage){
                            pageToMapValues[pageNum] = arrayMapKeys; 
                            rowNum = 0;
                            pageNum ++;
                            arrayMapKeys = [];
                        }
                    }  
                    pageToMapValues[pageNum ++] = arrayMapKeys; 
                    component.set("v.pageToMapValues", pageToMapValues);   
                    component.set("v.mapValues", pageToMapValues[component.get('v.currentPageNumber')]); 
                    component.set('v.rowNumToRow', res.rowValuesInRows);
                }else{
                    this.showToast(component, event, 'Error!', 'Error', res.message);
            	}
            }else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(component, event, 'Error!', 'Error', errors[0].message);
                    }
                } else {
                    console.error("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);                    
    },
    
    getDataToCurrentPage : function(component, helper) {
        let pageToMapValues = component.get("v.pageToMapValues");   
        let arrayMapKeys = pageToMapValues[component.get("v.currentPageNumber")];
        component.set("v.mapValues", arrayMapKeys);
    },
                        
    navigateToRecord : function(component, event, helper, idValue){
        var action = component.get("c.checkIfUserCanRedirect");
        action.setParams({
            'recordId' : idValue,
        });
        action.setCallback(this, function(response) {
            var objRes = response.getReturnValue();
            console.log('checked ', objRes);
            if(objRes.isSuccess == true ){
                var sObjectEvent = $A.get("e.force:navigateToSObject");
                sObjectEvent.setParams({                   
                    "recordId": idValue,
                    "slideDevName": "detail"
                });
                sObjectEvent.fire();
                
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : $A.get("$Label.c.Attention_Msg"),
                    message: objRes.message,
                    duration:' 4000',
                    key: 'info_alt',
                    type: 'Error',
                    mode: 'dismissible'
                });
                toastEvent.fire();
                
            }
        });
        $A.enqueueAction(action);
    },
                        
    showToast : function(component, event, title, type, message) {
        if(type == 'Error'){
            console.error('error', message);
        }
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})