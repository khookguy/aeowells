({
    zoomIdPass : function(component, event, helper) {
        var zoomShow = component.get('v.zoom');	
        if(zoomShow == 'True'){
            component.set('v.zoom','False');	
        }
        else{
            component.set('v.zoom','True');	
        }
    },
    
    canIdPass : function(component, event, helper) {
        var calShow = component.get('v.calendly');	
        if(calShow == 'True'){
            component.set('v.calendly','False');	
        }
        else{
            component.set('v.calendly','True');	
        }
    },
    
    handleReferralLink : function(component, event, helper) {
        var action = component.get("c.getReferralLink");
       
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                alert('GENERATED URL: '+resultData);
            }else{
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errors[0].message);
                    }
                }
                console.log('Error handleReferralLink');
            }
        });
        $A.enqueueAction(action);
    },
    
    getUserAndCohort : function(component) {
        var action = component.get("c.serverGetUserAndCohort");
        action.setParams({
            'programName' : component.get("v.programName").toString()
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultDataString = response.getReturnValue()
                var resultData = JSON.parse(resultDataString)
                component.set('v.userId', resultData.userId)
                component.set('v.cohortId', resultData.cohortId)
                var aeoStateUnencoded = "{'aeo_cohort_id':'" + resultData.cohortId + "', 'aeo_program_id':'" + component.get('v.programId') + "'}"
                var aeoStateEncoded = btoa(aeoStateUnencoded)
                component.set('v.aeo_state', aeoStateEncoded)
                console.log('aeoStateEncoded:')
                console.log(aeoStateEncoded)
                console.log('resultData.userId:')
                console.log(resultData.userId)
                console.log('resultData.cohortId:')
                console.log(resultData.cohortId)
                console.log('Data: ');
                console.log(resultData);
            }else{
                console.log('Error getUserAndCohort');
            }
        });
        $A.enqueueAction(action);
    }
})