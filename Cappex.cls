ID OppId = '';
Boolean tipsContract = false;
Opportunity creditingOpp = [SELECT ID,Owner.Name, Commercial_Team__c, StageName, LOA_Contract__c, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c
FROM Opportunity
WHERE ID = :OppId LIMIT 1];
String sendToFinance = 'Contract Received - Send to Finance';
String initiatingOpp = 'Initiating';
String continuingOpp = 'Continuing';
String amendmentOpp = 'Amendment';
String renewalOpp = 'Renewal';
String legacyAcquisitionOpp = 'Legacy Acquisition';
Boolean isOppRenewalUpsell = false;
Map<String,Date> mapOfProgramStartDate = new Map<String,Date>();
Map<String,Date> mapOfProgramEndDate = new Map<String,Date>();
Map<String,Decimal> mapOfProgramAndTotalCost = new Map<String,Decimal>();
Map<String, Decimal> mapOfProgramAndNBBAmount = new Map<String, Decimal>();
Map<String, Decimal> mapOfProgramAndAdminTravelFee = new Map<String, Decimal>();
Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();
Set<String> setOfRenewablePrograms_Cappex = new Set<String>{'CXCN'};
Set<String> setOfOneTimePrograms_Cappex = new Set<String>{'CXNN', 'CXTC'};
// Set<String> setOfEvents_Seramount = new Set<String>{
Set<String> setOfOneTimeProducts_Cappex = new Set<String>();
// Map<String, String> mapOfSeperateEvents = new Map<String, String>{
Map<String, String> mapOfCappexOneTimeProducts = new Map<String, String>{
    'SMT-EmERGe' => 'EDEV - EmERGe'
    // 'SMT-Glb_Emerge' => 'EDEV - Global Emerge',
    // 'SMT-Mltcltrl_WmnsNt_Cnf' => 'EDEV - Lead with Ambition',
    // 'SMT-Wrk_Gala_Awd' => 'EDEV - Work Beyond Summit and Gala Awards',
    // 'SMT-Events_Sampler' => 'EDEV - All Paid Events Ticket Package'
};
Map<String, Map<String, Decimal>> mapOfCappexProgramsWithYearlyAmount = new Map<String, Map<String, Decimal>>();
Map<String, Decimal> mapOfYearlyAmount = new Map<String, Decimal>();

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
    listOfQLs = [SELECT ID, Group_Name__c, Product_Code_Combination__c, Related_Product_with_Parent_Product__c, Related_Product_with_Parent_Product_Name__c, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c
    ORDER BY SBQQ__CustomerTotal__c ASC ];
} else {
    listOfQLs = [SELECT ID, Group_Name__c, Product_Code_Combination__c, Related_Product_with_Parent_Product__c, Related_Product_with_Parent_Product_Name__c, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c
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
    for(String eventProduct : mapOfCappexOneTimeProducts.keySet()){
        //System.debug('eventProduct =  ' + eventProduct);
        //System.debug('qle.Product_Code_Combination__c =  ' + qle.Product_Code_Combination__c);
        //System.debug('qle.Related_Product_with_Parent_Product__c =  ' + qle.Related_Product_with_Parent_Product__c);
        if((qle.Product_Code_Combination__c != null &&  qle.Product_Code_Combination__c.contains(eventProduct)) || (qle.Related_Product_with_Parent_Product__c != null && qle.Related_Product_with_Parent_Product__c.contains(eventProduct))){
            programAcronym = mapOfCappexOneTimeProducts.get(eventProduct);
        }
    }
    if(programAcronym != null){
            setOfProgramsAcronyms.add(programAcronym);
            if(setOfRenewablePrograms_Cappex.contains(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
                renewableProgramPresent_Seramount = true;
            }
            if(setOfOneTimePrograms_Cappex.contains(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
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

            Decimal amount = 0;
            if(mapOfCappexProgramsWithYearlyAmount.containsKey(programAcronym) && qle.SBQQ__ProductName__c != 'Administrative & Travel Fee' && qle.SBQQ__ProductName__c != 'Implementation Fee'){
                mapOfYearlyAmount = mapOfCappexProgramsWithYearlyAmount.get(programAcronym);
                
                if(mapOfYearlyAmount.containsKey(qle.Group_Name__c)){
                    amount = mapOfYearlyAmount.get(qle.Group_Name__c);
                }
                amount = amount + qle.SBQQ__CustomerTotal__c;
                mapOfYearlyAmount.put(qle.Group_Name__c, amount);
                mapOfCappexProgramsWithYearlyAmount.put(programAcronym, mapOfYearlyAmount);
            } else if (qle.SBQQ__ProductName__c != 'Administrative & Travel Fee' && qle.SBQQ__ProductName__c != 'Implementation Fee') {
                mapOfYearlyAmount.put(qle.Group_Name__c, amount);
                mapOfCappexProgramsWithYearlyAmount.put(programAcronym, mapOfYearlyAmount);
                // mapOfCappexProgramsWithYearlyAmount.put(programAcronym, new Map<String,String>(mapOfYearlyAmount) );
            }
        }
        if(qle.SBQQ__Product__r.Family != 'Fee' && qle.SBQQ__Product__r.Family != 'Pass Through Cost'){
            setOfProductCode.add(qle.SBQQ__ProductCode__c);
        }
        if(isRenewalOpp && qle.Previous_Year_Quantity__c == 0){
            isOppRenewalUpsell = true;
        }
    }
    System.debug('mapOfCappexProgramsWithYearlyAmount = ' + mapOfCappexProgramsWithYearlyAmount);
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
Date endDateOfContractToConsider = Date.today() < creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c ? Date.today().addYears(-1) : creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c.addYears(-1);
List<Contract> listOfContractOnAccount = [SELECT ID, ContractNumber FROM Contract WHERE AccountId = :creditingOpp.AccountId AND EndDate > :endDateOfContractToConsider AND ID != :creditingOpp.LOA_Contract__c];
List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name
FROM SBQQ__QuoteLine__c
WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true ) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c = :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c = :listOfContractOnAccount)
AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :setOfProgramsAcronyms)];
contractExist = listOfQLsAssociatedToContracts.size() > 0;
if(!listOfQLsAssociatedToContracts.isEmpty() && listOfQLsAssociatedToContracts.size() > 0){
    for(SBQQ__QuoteLine__c qle:listOfQLsAssociatedToContracts){
        if(setOfRenewablePrograms_Cappex.contains(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
            setOfRenewalbleProgramsSoldInPast.add(qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
        }
    }
}

System.debug('setOfRenewalbleProgramsSoldInPast = '  + setOfRenewalbleProgramsSoldInPast);


Boolean activeCxcnMembership = false;
Boolean activeRyauMembership = false;

Membership__c cxcnMembership = [SELECT ID, Program__r.Name, Membership_Status__c, Last_End_Date_2__c  FROM Membership__c WHERE Program__c = 'a0M2K000014r4dmUAA' and Account_Name__c = :creditingOpp.AccountId LIMIT 1];
Membership__c ryauMembership = [SELECT ID, Program__r.Name, Membership_Status__c FROM Membership__c WHERE Program__c = 'a0MC0000006jBbhMAE' and Account_Name__c = :creditingOpp.AccountId LIMIT 1];


if (cxcnMembership != null && cxcnMembership.Membership_Status__c == System.Label.ELIGIBLE_MEMBERSHIP_STATUS || cxcnMembership.Last_End_Date_2__c > endDateOfContractToConsider){
    activeCxcnMembership = true;
    System.debug('CXCN Membership considered');
    System.debug('cxcnMembership.Membership_Status__c = ' + cxcnMembership.Membership_Status__c);
} else if (ryauMembership != null && ryauMembership.Membership_Status__c == System.Label.ELIGIBLE_MEMBERSHIP_STATUS || ryauMembership.Last_End_Date_2__c > endDateOfContractToConsider){
    activeRyauMembership = true;
    System.debug('RYAU Membership considered');
    System.debug('ryauMembership.Membership_Status__c = ' + ryauMembership.Membership_Status__c);
}


if(isDiscountProductUsed){
    System.debug('------------------------------------------------ALERT - Discount Product Used - NBB amount may differ ---------------------------------------------');
}

if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null){
    System.debug('------------------------------------------------ALERT - Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c + ' --------------------  Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c + ' ---------------------------------------------');
}

if(creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null){
    System.debug('------------------------------------------------ALERT - Secondary Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c + '--------------------   Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c + ' ---------------------------------------------');
}

if(oneTimeProgramPresentOf_Seramount){
    System.debug('One Time Program Present');
    System.debug('New Sale for One Time Program');
}


Integer counter = 0;
for(String program : setOfProgramsAcronyms){
      Integer totalDays = mapOfProgramStartDate.get(program).daysBetween(mapOfProgramEndDate.get(program)) + 1;
      Decimal adminAndTravelFee = mapOfProgramAndAdminTravelFee.containsKey(program) ? mapOfProgramAndAdminTravelFee.get(program) : 0;
      Decimal totalProgramCost = mapOfProgramAndTotalCost.get(program) + adminAndTravelFee;

      if(counter == 0){
      System.debug('\n');
      System.debug('=====================================================DEAL INFORMATION======================================================');
      System.debug(' Total Programs to credit : ' + setOfProgramsAcronyms.size());
      System.debug(' Set Of Programs to credit : ' + setOfProgramsAcronyms);
      System.debug(' Propsal Start Date : ' + mapOfProgramStartDate);
      System.debug(' Propsal End Date : ' + mapOfProgramEndDate);
      System.debug(' Cost of Program Without A&T : ' + mapOfProgramAndTotalCost);
      System.debug(' Admin And Travel Fee : ' + mapOfProgramAndAdminTravelFee);
      System.debug('===========================================================================================================================');
    }
    if( ( !setOfRenewalbleProgramsSoldInPast.isEmpty() && !setOfRenewalbleProgramsSoldInPast.contains(program) ) || ( setOfOneTimePrograms_Cappex.contains(program) || (isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank ||  !isParentOppContracted) ) || isThisARenewalForecasting)  && !contractExist && !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')) ) ){
        System.debug('--------------------------------------------------------New Sale--------------------------------------------------------');     
        
    }
    else if(creditingOpp.SBQQ__AmendedContract__c != null  || creditingOpp.Is_this_an_amend_and_restate_contract__c  == 'Yes' || isOppRenewalUpsell){
        System.debug('----------------------------------Upsell RBB------------------------------------------');
    }
    else{
        System.debug('----------------------------------Renewal----------------------------------------------');
    }
    Decimal nbbAmount = 0;
    if(setOfRenewablePrograms_Cappex.contains(program)){
        nbbAmount = ( (totalProgramCost/totalDays)*365 );
    } else if(setOfOneTimePrograms_Cappex.contains(program)){
        System.debug('One time Program: 100% of Total Program Cost');
        nbbAmount = totalProgramCost;
    } else if(mapOfCappexOneTimeProducts.containsKey(program)){
        System.debug('Event Products');
        nbbAmount = totalProgramCost;
    }
    if(tipsContract){
        nbbAmount = nbbAmount * 0.99;
    }
    mapOfProgramAndNBBAmount.put(program, nbbAmount.setScale(2));
    if(nbbAmount == 0){
        continue;
    }

    if(setOfOneTimePrograms_Cappex.contains(program)){
        System.debug('------------------------------------------Program to Credit :'+program +' -----------------------------------------');
        System.debug(' Credited User : ' + creditingOpp.Owner.Name);
        System.debug(' Program Name : ' + program);
        System.debug(' NBB Amount : ' + nbbAmount.setScale(2) );
        System.debug(' NBB Type : Un-Posted Risk');
        System.debug(' Binder Date : Date of the Event');
        System.debug(' ATL Date : Date of the Event');
    } else{
        System.debug('-----------------------------------------------Program to Credit :'+program +' ----------------------------------------------');
        System.debug(' Credited User : ' + creditingOpp.Owner.Name);
        System.debug(' Program Name : ' + program);
        System.debug(' NBB Amount : ' + nbbAmount.setScale(2) );
        System.debug(' NBB Type : Base Fee');        
        Date atlBinderDate = Date.today() > mapOfProgramStartDate.get(program) ? Date.today() : mapOfProgramStartDate.get(program);
        System.debug(' Binder Date : '  + atlBinderDate);
        System.debug(' ATL Date : ' + atlBinderDate);
    }
    if(creditingOpp.Commercial_Team__c == 'Seramount RET'){
        System.debug(' Deal Type: Cross Sell');
    } else {
        System.debug(' Deal Type: New Sale');
    }
    counter =+1; 
    System.debug('-----------------------------------------------------------------------------------------------------------------------');
}
