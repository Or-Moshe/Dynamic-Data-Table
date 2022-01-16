({
    doInit : function(component, event, helper) {
        component.set('v.showSearch', component.get('v.showSearchStr') == 'true');
		helper.createTable(component, event, helper);
	},
    
    clickColumn : function(component, event, helper){
        let fieldName = event.currentTarget.dataset.value;
        let columnToAmountClicks = component.get('v.columnToAmountClicks');
        let orderBy =  Math.floor(columnToAmountClicks[fieldName] % 2) == 0 ? 'DESC' : 'ASC';
        columnToAmountClicks[fieldName] = columnToAmountClicks[fieldName] + 1;
        component.set('v.columnToAmountClicks', columnToAmountClicks);
        helper.orderTable(component, event, helper, fieldName, orderBy);
    },
    
    clickLink : function(component, event, helper){
        var idValue = event.target.value;
        helper.navigateToRecord(component, event, helper, idValue);
    },
    
    handleSearchClick: function (component, helper, event) {
        //helper.searchKey(component, event, helper);
        let queryTerm = component.find('enter-search').get('v.value').toLowerCase();
        let oldPageToMapValues = component.get('v.oldPageToMapValues');
        let totalRowsInPage = parseInt(component.get('v.totalRowsInPage'));
        let pageNum = 1;
        let pageToMapValues = {};
        let searchKeyArr = [];
        let notSearchKeyArr = [];
        let pageList = [];
        for(var key in oldPageToMapValues){
            let arr = oldPageToMapValues[key];
            arr.forEach(el => {
                let row = el;
                row.key = key.toString();
                key ++;
                if(el.searchKey.toLowerCase().includes(queryTerm)){
                searchKeyArr.push(row);
            }
                        });
        }
        if(searchKeyArr.length > 0){
            let orderDataArr = searchKeyArr.concat(notSearchKeyArr);
            for (let i = 0;  i < orderDataArr.length; i += totalRowsInPage) {
                pageToMapValues[pageNum] = orderDataArr.slice(i, i + totalRowsInPage); 
                if(pageToMapValues[pageNum].length == totalRowsInPage){
                    pageList.push(pageNum);
                }
                pageNum ++;
            }
            /*if(pageToMapValues.length == 1){
                pageList.push(1); 
            }*/
            
            component.set("v.pageToMapValues", pageToMapValues); 
            component.set("v.mapValues", pageToMapValues[1]); 
            //component.set("v.pageList", pageList);   
            component.set('v.showTableMsg', false);
        }else{
            /*if(pageList.length == 0){
                pageList.push(1); 
            }*/
            component.set("v.pageList", pageList);  
            component.set('v.showTableMsg', true);
        }
        if(pageList.length == 0){
            pageList.push(1); 
        } 
        component.set("v.pageList", pageList);   
        component.set("v.currentPageNumber", 1); 
        component.set("v.originTotalPages", component.get('v.totalPages')); 
        component.set("v.totalPages", pageList.length); 
    },
    
   handleKeyUp: function (component, helper, event) {
        /*if(event.keyCode === 13) {
            helper.searchKey(component, event, helper);
        }*/
	},
    
    onChangeSearch: function (component, event) {
		let value = event.getSource().get("v.value");
        if(!value){
           component.set('v.showTableMsg', false);
           component.set('v.showTableMsg', false);
           component.set("v.totalPages", component.get('v.originTotalPages')); 
           component.set('v.pageList', component.get('v.originPageList'));
           let pageToMapValues = component.get("v.oldPageToMapValues");
           component.set('v.pageToMapValues', pageToMapValues);
           component.set('v.mapValues', pageToMapValues[component.get('v.currentPageNumber')]);
        }
    },
    
    processMe : function(component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        helper.getDataToCurrentPage(component, helper);
    },
    
    onNext : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber+1);
        helper.getDataToCurrentPage(component, helper);
    },
    
    onPrev : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber-1);
        helper.getDataToCurrentPage(component, helper);
    },
    
    onFirst : function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.getDataToCurrentPage(component, helper);
    },
    
    onLast : function(component, event, helper) {
		console.log('currentPageNumber', component.get("v.totalPages"));        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.getDataToCurrentPage(component, helper);
    }
})