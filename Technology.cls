ID OppId = '006Pr00000IAvAjIAL'; 
Boolean tipsContract = false;

Opportunity creditingOpp = [SELECT ID, StageName, LOA_Contract__c, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c
FROM Opportunity
WHERE ID = :OppId LIMIT 1];  

String sendToFinance = 'Contract Received - Send to Finance';  
String initiatingOpp = 'Initiating';  
String continuingOpp = 'Continuing'; 
String amendmentOpp = 'Amendment';  
String renewalOpp = 'Renewal';  
String legacyAcquisitionOpp = 'Legacy Acquisition';  

Boolean isOppRenewalUpsell = false;  
Boolean identifiedAsRenewal = false;

Map<String,Date> mapOfProgramStartDate = new Map<String,Date>();  
Map<String,Date> mapOfProgramEndDate = new Map<String,Date>();  
Map<String,Decimal> mapOfProgramAndTotalCost = new Map<String,Decimal>();  
Map<String, Decimal> mapOfProgramAndNBBAmount = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndImplementationFee = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndAdminTravelFee = new Map<String, Decimal>();  
Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();  
Map<String, String> mapOfEdifyPrograms = new Map<String, String>{
    'EDBEL' => 'EDBE',
    'EDBEP' => 'EDBE',
    'EDFY' => 'BHDH',
    'BHDHB' => 'BHDH',
    'BHDHC' => 'BHDH',
    'BHDHE' => 'BHDH',
    'BHDHP' => 'BHDH',
    'HECDHB' => 'HECDH',
    'HECDHG' => 'HECDH',
    'HECDHI' => 'HECDH',
    'HECDHP' => 'HECDH',
    'HECDHS' => 'HECDH'
};

Boolean isOppSendToFinance = creditingOpp.StageName == sendToFinance;  
Boolean isInitiatingOpp =  creditingOpp.Type2__c == initiatingOpp;  
Boolean isContinuingOpp =  creditingOpp.Type2__c == continuingOpp;  
Boolean isAmendmentOpp =  creditingOpp.Type2__c == amendmentOpp;  
Boolean isRenewalOpp =  creditingOpp.Type2__c == renewalOpp || creditingOpp.SBQQ__RenewedContract__c != null;  
Boolean isDiscountProductUsed = false;
Boolean isLegacyAcquisitionOpp =  creditingOpp.Type2__c == legacyAcquisitionOpp;  

Set<String> setOfProgramsAcronyms = new Set<String>();  
Set<String> setOfProductCode = new Set<String>();  

List<SBQQ__QuoteLine__c> listOfQLs = new List<SBQQ__QuoteLine__c>();
if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == null || creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == 'Funds Appropriation Opt Out'){
    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c
    ORDER BY Related_Product__c ASC ];  
} else {
    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c
    ORDER BY Related_Product__c ASC ];  
}

 for(SBQQ__QuoteLine__c qle :listOfQLs){  
        String programAcronym = null;
     
     //System.debug('---------------------------------------------------------');
       // System.debug('qle.SBQQ__ProductCode__c = ' + qle.SBQQ__ProductCode__c);
        //System.debug('qle.SBQQ__ProductName__c = ' + qle.SBQQ__ProductName__c);
        //System.debug('qle.SBQQ__Product__r.Program__r.Program_Acronym__c = ' + qle.SBQQ__Product__r.Program__r.Program_Acronym__c);

        //System.debug('qle.SBQQ__CustomerTotal__c = ' + qle.SBQQ__CustomerTotal__c);

        if(qle.SBQQ__ProductCode__c == 'DISC-EAB_Invstmnt'){
            isDiscountProductUsed = true;
        }
     	//System.debug('Program_Acronym__c = ' + qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
        mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c);  
        programAcronym = qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c);
		programAcronym = mapOfEdifyPrograms.containsKey(programAcronym) ? mapOfEdifyPrograms.get(programAcronym) : programAcronym;
     	//System.debug('programAcronym used = ' + programAcronym);
     
        if(programAcronym != null){  
            setOfProgramsAcronyms.add(programAcronym); 
            Date startDate = qle.SBQQ__StartDate__c; 
            Date endDate = qle.SBQQ__EndDate__c; 
            if(mapOfProgramStartDate != null && mapOfProgramStartDate.containsKey(programAcronym)){ 
                if(startDate > mapOfProgramStartDate.get(programAcronym)){ 
                    startDate = mapOfProgramStartDate.get(programAcronym); 

                } 
            } 
            if(mapOfProgramEndDate != null && mapOfProgramEndDate.containsKey(programAcronym)){ 
                if(endDate < mapOfProgramEndDate.get(programAcronym)){ 
                    endDate = mapOfProgramEndDate.get(programAcronym); 

                } 

            } 
            mapOfProgramStartDate.put(programAcronym, startDate);  
            mapOfProgramEndDate.put(programAcronym, endDate);  
            //System.debug('mapOfProgramAndTotalCost.containsKey(programAcronym) = ' + mapOfProgramAndTotalCost.containsKey(programAcronym));
            if(mapOfProgramAndTotalCost.containsKey(programAcronym) && qle.SBQQ__ProductName__c != 'Administrative & Travel Fee' && qle.SBQQ__ProductName__c != 'Implementation Fee') {                  
                mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + qle.SBQQ__CustomerTotal__c);  

            } else if (qle.SBQQ__ProductName__c != 'Administrative & Travel Fee' && qle.SBQQ__ProductName__c != 'Implementation Fee') {  
                mapOfProgramAndTotalCost.put(programAcronym, qle.SBQQ__CustomerTotal__c);  

            }  

        }  
        if(qle.SBQQ__Product__r.Family != 'Fee' && qle.SBQQ__Product__r.Family != 'Pass Through Cost'){  
            setOfProductCode.add(qle.SBQQ__ProductCode__c);  
        } 
        if(isRenewalOpp && qle.Previous_Year_Quantity__c == 0){ 
            isOppRenewalUpsell = true; 
        } 
     //System.debug('mapOfProgramAndTotalCost = ' + mapOfProgramAndTotalCost);
    } 
    for(SBQQ__QuoteLine__c qle :listOfQLs){ 
    if(qle.SBQQ__ProductName__c == 'Administrative & Travel Fee'){            
            if(mapOfProgramAndAdminTravelFee.containsKey(mapOfProgramAndParentProductName.get(qle.Related_Product__c))){
                Decimal sumOfFee = mapOfProgramAndAdminTravelFee.get(mapOfProgramAndParentProductName.get(qle.Related_Product__c))  + qle.SBQQ__CustomerTotal__c;
                mapOfProgramAndAdminTravelFee.put( mapOfProgramAndParentProductName.get(qle.Related_Product__c) ,sumOfFee); 
            } else {
                mapOfProgramAndAdminTravelFee.put( mapOfProgramAndParentProductName.get(qle.Related_Product__c) ,qle.SBQQ__CustomerTotal__c); 

            }

    } 
        if(qle.SBQQ__ProductName__c == 'Implementation Fee'){ 
            mapOfProgramAndImplementationFee.put( mapOfProgramAndParentProductName.get(qle.Related_Product__c) ,qle.SBQQ__CustomerTotal__c); 
        } 

    } 
for(String program : setOfProgramsAcronyms){ 

Integer totalDays = mapOfProgramStartDate.get(program).daysBetween(mapOfProgramEndDate.get(program)) + 1;  
Decimal adminAndTravelFee = mapOfProgramAndAdminTravelFee.containsKey(program) ? mapOfProgramAndAdminTravelFee.get(program) : 0;  
Decimal implementationFee = mapOfProgramAndImplementationFee.containsKey(program) ? mapOfProgramAndImplementationFee.get(program) : 0;  
Decimal totalProgramCost = mapOfProgramAndTotalCost.get(program) + adminAndTravelFee; 
Decimal nbbAmount = ( (totalProgramCost/totalDays)*365 ) + implementationFee;  

if(tipsContract){
    nbbAmount = nbbAmount * 0.99;
}

mapOfProgramAndNBBAmount.put(program, nbbAmount.setScale(2));  

if(program == 'BHAI'){
 System.debug('Program => ' + program);
 System.debug('totalDays = ' + totalDays);
 System.debug('adminAndTravelFee = ' + adminAndTravelFee);
 System.debug('implementationFee = ' + implementationFee);
 System.debug('cost of program without a&t = ' + mapOfProgramAndTotalCost.get(program));
 System.debug('nbbAmount = ' + nbbAmount);

}

} 

Boolean isThisARenewalForecasting = creditingOpp.IsFcstRenewal__c == 'Yes';  
Boolean isParentOppBlank = creditingOpp.Parent_Opportunity__c == null;  
Boolean isParentOppContracted = creditingOpp.Parent_Opportunity__c != null ? (creditingOpp.Parent_Opportunity__r.SBQQ__Ordered__c || creditingOpp.Parent_Opportunity__r.SBQQ__Contracted__c) : false;  
Boolean contractExist = false; 
List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND EndDate > :Date.today().addYears(-1) AND ID != :creditingOpp.LOA_Contract__c]; 
List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name   
FROM SBQQ__QuoteLine__c  
WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true ) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c = :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c = :listOfContractOnAccount)   
AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :setOfProgramsAcronyms)];  
contractExist = listOfQLsAssociatedToContracts.size() > 0;  

//System.debug('listOfQLsAssociatedToContracts = ' + listOfQLsAssociatedToContracts);
//System.debug('isInitiatingOpp = ' + isInitiatingOpp);
//System.debug('isThisARenewalForecasting = ' + isThisARenewalForecasting);
//System.debug('isParentOppBlank = ' + isParentOppBlank );
//System.debug('isParentOppContracted = ' + isParentOppContracted);
//System.debug('contractExist = ' + contractExist);
//System.debug('creditingOpp.SBQQ__AmendedContract__c = ' + creditingOpp.SBQQ__AmendedContract__c);
//System.debug('creditingOpp.Is_this_an_amend_and_restate_contract__c = ' + creditingOpp.Is_this_an_amend_and_restate_contract__c);

if( isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank ||  !isParentOppContracted) ) || isThisARenewalForecasting)  &&  !contractExist && !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')  ){ 

    System.debug('------------------------------------New Sale-------------------------------------------'); 
} 
else if(creditingOpp.SBQQ__AmendedContract__c != null  || creditingOpp.Is_this_an_amend_and_restate_contract__c  == 'Yes' || isOppRenewalUpsell){  
    System.debug('----------------------------------Upsell RBB------------------------------------------'); 
} 
else{ 
    identifiedAsRenewal = true;
    System.debug('----------------------------------Renewal----------------------------------------------'); 
} 


for(String program : setOfProgramsAcronyms){
    if(!identifiedAsRenewal){
        System.debug('------------------------------------NBB Details: Program to Credit-------------------------------------------'); 
        System.debug(' mapOf Program And Parent Product Name (For A&T and Imp) = ' + mapOfProgramAndParentProductName); 
        System.debug(' Propsal Start Date = ' + mapOfProgramStartDate.get(program)); 
        System.debug(' Proposal End Date = ' + mapOfProgramEndDate.get(program)); 
        System.debug(' Total Program Cost =>' + mapOfProgramAndTotalCost.get(program));
        System.debug(' Admin and Travel Fee =>' + mapOfProgramAndAdminTravelFee.get(program));
        System.debug(' Implementation Fee =>' + mapOfProgramAndImplementationFee.get(program));
        System.debug(' NBB Amount =>' + mapOfProgramAndNBBAmount.get(program).setScale(2)); 
        System.debug('Program ==> Program Cost');
        Date atlBinderDate = Date.today() > mapOfProgramStartDate.get(program) ? Date.today() : mapOfProgramStartDate.get(program);
        System.debug('Binder Date: '  + atlBinderDate);
        System.debug('ATL Date: ' + atlBinderDate);
        System.debug('Opp Owner: ' + creditingOpp.Owner.Name);
    }
}
if(isDiscountProductUsed){
    System.debug('---------------------------------------------ALERT - Discount Product Used - NBB amount may differ ------------------------------------------'); 
}
System.debug('---------------------------------------------------------------------------------------------'); 
if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null){
    System.debug('------------------------------------------------ALERT - Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c + ' ---------------------------------------------'); 
}
if(creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null){
    System.debug('------------------------------------------------ALERT - Secondary Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c + ' ---------------------------------------------'); 
}
