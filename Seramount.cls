ID OppId = '006Pr00000Ebm5dIAB'; 
Boolean tipsContract = false;
Opportunity creditingOpp = [SELECT ID,Owner.Name, Commercial_Team__c, StageName, LOA_Contract__c, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c
FROM Opportunity
WHERE ID = :OppId LIMIT 1];
String seramountEvents = 'https://seramount.com/wp-content/uploads/2024/09/Seramount-2025-Event-Calendar-1.pdf';
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
Map<String, Decimal> mapOfProgramAndAdminTravelFee = new Map<String, Decimal>();
Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();
Set<String> setOfRenewablePrograms_Seramount = new Set<String>{'EDBP','EDLC', 'EDATS', 'EDSPO','EDSLS', 'EDLRS', 'EDHR'};
Set<String> setOfOneTimePrograms_Seramount = new Set<String>{'EDEV','EDCON', 'EDLRN', 'EDRS'};
Set<String> setOfEvents_Seramount = new Set<String>{
    'SMT-EmERGe',
    'SMT-Glb_Emerge',
    'SMT-Mltcltrl_WmnsNt_Cnf',
    'SMT-Wrk_Gala_Awd',
    'SMT-Events_Sampler'
};
Map<String, String> mapOfSeperateEvents = new Map<String, String>{
    'SMT-EmERGe' => 'EDEV - EmERGe',
    'SMT-Glb_Emerge' => 'EDEV - Global Emerge',
    'SMT-Mltcltrl_WmnsNt_Cnf' => 'EDEV - Lead with Ambition',
    'SMT-Wrk_Gala_Awd' => 'EDEV - Work Beyond Summit and Gala Awards',
    'SMT-Events_Sampler' => 'EDEV - All Paid Events Ticket Package'
};


Boolean oneTimeProgramPresentOf_Seramount = false;
Boolean renewableProgramPresent_Seramount = false;
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
    listOfQLs = [SELECT ID, Product_Code_Combination__c, Related_Product_with_Parent_Product__c, Related_Product_with_Parent_Product_Name__c, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c
    ORDER BY SBQQ__CustomerTotal__c ASC ];
} else {
    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c
    ORDER BY SBQQ__CustomerTotal__c ASC ];
}
for(SBQQ__QuoteLine__c qle :listOfQLs){
    String programAcronym = null;
    if(qle.SBQQ__ProductCode__c == 'DISC-EAB_Invstmnt'){
        isDiscountProductUsed = true;
    }
 	mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
    programAcronym = qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c);

    for(String eventProduct : mapOfSeperateEvents.keySet()){
        System.debug('eventProduct =  ' + eventProduct);
        System.debug('qle.Product_Code_Combination__c =  ' + qle.Product_Code_Combination__c);
        System.debug('qle.Related_Product_with_Parent_Product__c =  ' + qle.Related_Product_with_Parent_Product__c);
        if((qle.Product_Code_Combination__c != null &&  qle.Product_Code_Combination__c.contains(eventProduct)) || (qle.Related_Product_with_Parent_Product__c != null && qle.Related_Product_with_Parent_Product__c.contains(eventProduct))){
            programAcronym = mapOfSeperateEvents.get(eventProduct);
        }
    }
    if(programAcronym != null){
            setOfProgramsAcronyms.add(programAcronym);
            if(setOfRenewablePrograms_Seramount.contains(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
                renewableProgramPresent_Seramount = true;
            }
            if(setOfOneTimePrograms_Seramount.contains(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
                oneTimeProgramPresentOf_Seramount = true;
            }
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
}
Boolean isThisARenewalForecasting = creditingOpp.IsFcstRenewal__c == 'Yes';
Boolean isParentOppBlank = creditingOpp.Parent_Opportunity__c == null;
Boolean isParentOppContracted = creditingOpp.Parent_Opportunity__c != null ? (creditingOpp.Parent_Opportunity__r.SBQQ__Ordered__c || creditingOpp.Parent_Opportunity__r.SBQQ__Contracted__c) : false;
Boolean contractExist = false;
Set<String> setOfRenewalbleProgramsSoldInPast = new Set<String>();
List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND EndDate > :Date.today().addYears(-1) AND ID != :creditingOpp.LOA_Contract__c];
List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name
FROM SBQQ__QuoteLine__c
WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true ) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c = :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c = :listOfContractOnAccount)
AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :setOfProgramsAcronyms)];
contractExist = listOfQLsAssociatedToContracts.size() > 0;
if(!listOfQLsAssociatedToContracts.isEmpty() && listOfQLsAssociatedToContracts.size() > 0){
    for(SBQQ__QuoteLine__c qle:listOfQLsAssociatedToContracts){
        if(setOfRenewablePrograms_Seramount.contains(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
            setOfRenewalbleProgramsSoldInPast.add(qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
        }
    }
}

if(isDiscountProductUsed){
    System.debug('------------------------------------------------ALERT - Discount Product Used - NBB amount may differ ---------------------------------------------');
}
System.debug('---------------------------------------------------------------------------------------------');
if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null){
    System.debug('------------------------------------------------ALERT - Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c + ' --------------------  Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c + ' ---------------------------------------------');
}
if(creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null){
    System.debug('------------------------------------------------ALERT - Secondary Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c + '--------------------   Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c + ' ---------------------------------------------');
}
if(oneTimeProgramPresentOf_Seramount){
    System.debug('One Time Program Present');
    System.debug('New Sale for One Time Program');
    identifiedAsRenewal = false;
}
System.debug('setOfProgramsAcronyms =  ' + setOfProgramsAcronyms);
System.debug('Total Programs to credit = ' + setOfProgramsAcronyms.size());
for(String program : setOfProgramsAcronyms){
    System.debug('------------------------------------NBB Details: Program to Credit-------------------------------------------'); 
    if(identifiedAsRenewal || ( setOfOneTimePrograms_Seramount.contains(program) || (isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank ||  !isParentOppContracted) ) || isThisARenewalForecasting)  && !contractExist && !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')) ) ){
        System.debug('------------------------------------New Sale-------------------------------------------');
    }
    else if(creditingOpp.SBQQ__AmendedContract__c != null  || creditingOpp.Is_this_an_amend_and_restate_contract__c  == 'Yes' || isOppRenewalUpsell){
        System.debug('----------------------------------Upsell RBB------------------------------------------');
    } 
    else{ 
        identifiedAsRenewal = true;
        System.debug('----------------------------------Renewal----------------------------------------------'); 
    }
    Integer totalDays = mapOfProgramStartDate.get(program).daysBetween(mapOfProgramEndDate.get(program)) + 1;
    Decimal adminAndTravelFee = mapOfProgramAndAdminTravelFee.containsKey(program) ? mapOfProgramAndAdminTravelFee.get(program) : 0;
    Decimal totalProgramCost = mapOfProgramAndTotalCost.get(program) + adminAndTravelFee;
    System.debug('totalProgramCost = ' + totalProgramCost);
    System.debug('mapOfSeperateEvents = ' + mapOfSeperateEvents);
    System.debug('mapOfSeperateEvents = ' + mapOfSeperateEvents.keySet());
    Decimal nbbAmount = 0;
    if(setOfRenewablePrograms_Seramount.contains(program)){
        nbbAmount = ( (totalProgramCost/totalDays)*365 );
    } else if(setOfOneTimePrograms_Seramount.contains(program)){
        System.debug('One time Progeam: 100% of Total Program Cost');
        nbbAmount = totalProgramCost;
    } else if(mapOfSeperateEvents.containsKey(program)){
        System.debug('Event Products');
        nbbAmount = totalProgramCost;
    }
    if(tipsContract){
        nbbAmount = nbbAmount * 0.99;
    }
    
    mapOfProgramAndNBBAmount.put(program, nbbAmount.setScale(2));
    if(nbbAmount == 0){
        // continue;
    }
    System.debug('Program => ' + program);
    System.debug('Start Date = ' + mapOfProgramStartDate.get(program));
    System.debug('End Date = ' + mapOfProgramEndDate.get(program));
    System.debug('Total Days = ' + totalDays);
    System.debug('Cost of Program Without A&T = ' + mapOfProgramAndTotalCost.get(program));
    System.debug('Admin And Travel Fee = ' + adminAndTravelFee);
    System.debug('Cost of Program Including A&T = ' + totalProgramCost);
    System.debug('NBB Amount = ' + nbbAmount.setScale(2));
    if(setOfOneTimePrograms_Seramount.contains(program)){
        if(program == 'EDEV' ){
            System.debug('Binder Date: Date of the Event');
            System.debug('ATL Date: Date of the Event');
            System.debug('Get the date of the event from -> ' + seramountEvents);
        
        }
        System.debug('NBB Type: Un-Posted Risk');
        Date atlBinderDate = Date.today() > mapOfProgramStartDate.get(program) ? Date.today() : mapOfProgramStartDate.get(program);
        System.debug('Binder Date: '  + atlBinderDate);
        System.debug('ATL Date: ' + atlBinderDate);
        
    } else{
        System.debug('NBB Type: Base Fee');
        
        Date atlBinderDate = Date.today() > mapOfProgramStartDate.get(program) ? Date.today() : mapOfProgramStartDate.get(program);
        System.debug('Binder Date: '  + atlBinderDate);
        System.debug('ATL Date: ' + atlBinderDate);

    }
    if(creditingOpp.Commercial_Team__c == 'Seramount RET'){
        System.debug('Deal Type: Cross Sell');
    } else {
        System.debug('Deal Type: New Sale');
    }
    System.debug('Opp Owner: ' + creditingOpp.Owner.Name);
}
