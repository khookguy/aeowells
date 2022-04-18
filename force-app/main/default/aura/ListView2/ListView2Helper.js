({
    getColumnAndAction : function(component) {
        var actions = [
            {label: 'Edit', name: 'edit'},
            {label: 'Delete', name: 'delete'},
            {label: 'View', name: 'view'}
        ];
        component.set('v.columns', [
            // {label: 'Program Name', fieldName: 'Program_Name__c', type: 'text'},
            {label: 'Member Name', fieldName: 'Name__c', type: 'text'},
            {label: 'Member Email', fieldName: 'Member_Email__c', type: 'text'},
            {label: 'Member Business Name', fieldName: 'Member_Business_Name__c', type: 'text'},
            {label: 'Status', fieldName: 'Member_Status__c', type: 'text'},
            // {label: 'Cohort Name', fieldName: 'Cohort_Name__c', type: 'text'},
            /* {
                label: 'Action',
                type:  'button',
                typeAttributes: 
                {
                    //iconName: 'utility:edit',
                    label: 'Complete Coaching', 
                    name: 'btnClick', 
                    title: 'btnClick', 
                    disabled: { fieldName: 'btnDisabled__c'},// >>new formula field to be created
                    value: 'test'
                }
            } */
            //{label: 'AccountNumber', fieldName: 'AccountNumber', type: 'text'},
            //{label: 'Industry', fieldName: 'Industry', type: 'text'},
            //{label: 'Phone', fieldName: 'Phone', type: 'phone'},
            //{type: 'action', typeAttributes: { rowActions: actions } } 
        ]);
    },
     
    getProgMembers : function(component, helper) {
        var action = component.get("c.serverGetProgMembers");
        var pageSize = component.get("v.pageSize").toString();
        var pageNumber = component.get("v.pageNumber").toString();
        var programName = component.get("v.programName").toString();
         
        action.setParams({
            'pageSize' : pageSize,
            'pageNumber' : pageNumber,
            'programName' : programName
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                if(resultData.length < component.get("v.pageSize")){
                    component.set("v.isLastPage", true);
                } else{
                    component.set("v.isLastPage", false);
                }
                component.set("v.dataSize", resultData.length);
                component.set("v.data", resultData);
                console.log('Data Size: '+resultData.length);
                console.log('Data: ');
                console.log(resultData);
            }else{
                console.log('Error getProgMembers');
            }
        });
        $A.enqueueAction(action);
    }
            
})