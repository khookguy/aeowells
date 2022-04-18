({
    doInit : function(component, event, helper) {        
        helper.getColumnAndAction(component);
        helper.getProgMembers(component, helper);
    },
    
    handleClick : function(component, event, helper) { 
        if(event.getSource().get("v.label") == 'Yes'){
            //startloading code
            helper.updateProgMembers(component, event, helper);
        }else if(event.getSource().get("v.label") == 'Cancel'){
            component.set('v.showModal', false);            
        }else if(event.getSource().get("v.label") == 'Okay'){
            component.set('v.showModal', false);
        }
    },
     
    handleNext : function(component, event, helper) { 
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber+1);
        helper.getProgMembers(component, helper);
    },
     
    handlePrev : function(component, event, helper) {        
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber-1);
        helper.getProgMembers(component, helper);
    },
 
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        switch (action.name) {
            /*case 'edit':
                helper.editRecord(component, event);
                break;
            case 'delete':
                helper.deleteRecord(component, event);
                break;
            case 'view':
                helper.viewRecord(component, event);
                break;*/
            case 'btnClick':
                component.set("v.isDone", false);
                component.set('v.showModal', true);
                component.set('v.modalMessage','Are you sure you want to update status to Coaching Completed?'); 
                component.set('v.recordId',event.getParam('row').Id);
            	//console.log(row.Id);
            break;
        }
    },
})