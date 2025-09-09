ID OppId = ''; 

String signedDate = '';

String oppCameInQueue = '';

Date consideredToday = Date.parse(oppCameInQueue);

Date contractSignatureDate = Date.parse(signedDate);

Boolean tipsContract = false;


Opportunity creditingOpp = [SELECT ID, StageName, LOA_Contract__c, Contract_Signature_Date__c, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c, Owner.Name, List_of_Product_Families__c, SBQQ__PrimaryQuote__r.Opt_Out_Penalty_Amount__c, SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c
FROM Opportunity
WHERE ID = :OppId LIMIT 1]; 
 

Boolean isOppRenewalUpsell = false;  

Boolean identifiedAsRenewal = false;

String oppOwner = creditingOpp.Owner.Name;

String cappexMembership = 'CPX-CX_Adv_Membership';

String membershipAddedToProg;

Map<String,Date> mapOfProgramStartDate = new Map<String,Date>();  

Map<String,Date> mapOfProgramEndDate = new Map<String,Date>();  

Map<String,Decimal> mapOfProgramAndTotalCost = new Map<String,Decimal>();  

Map<String,Decimal> mapOfProgramAndFirstYearTotal = new Map<String,Decimal>();

Map<String, Decimal> mapOfProgramAndNBBAmount = new Map<String, Decimal>();  

Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();

Map<String, Map<Decimal, Decimal>> mapGrpAndTotal = new Map<String, Map<Decimal, Decimal>>();

Map<String, Decimal> mapOfQuarterAndProration = new Map<String, Decimal>();

Map<String, Decimal> mmapOfMembershipAndTotal = new Map<String, Decimal>();


Boolean isOppSendToFinance = creditingOpp.StageName == 'Contract Received - Send to Finance';  

Boolean isInitiatingOpp =  creditingOpp.Type2__c == 'Initiating';  

Boolean isContinuingOpp =  creditingOpp.Type2__c == 'Continuing';  

Boolean isAmendmentOpp =  creditingOpp.Type2__c == 'Amendment';  

Boolean isRenewalOpp =  creditingOpp.Type2__c == 'Renewal' || creditingOpp.SBQQ__RenewedContract__c != null;  

Boolean isDiscountProductUsed = false;

Boolean isLegacyAcquisitionOpp =  creditingOpp.Type2__c == 'Legacy Acquisition'; 



Set<String> setOfProgramsAcronyms = new Set<String>();  

Set<String> setOfProductCode = new Set<String>();  

List<Team_Membership__c> listOfAlrPDE = [SELECT Staff_member__r.Name FROM Team_Membership__c 
                      WHERE Institution__c =: creditingOpp.AccountId
                      AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' 
                      AND Program_Perspectives__c = 'ALR'
                      LIMIT 1];


List<Team_Membership__c> listOfAppilyAdvPDE= [SELECT Staff_member__r.Name FROM Team_Membership__c 
                      WHERE Institution__c =: creditingOpp.AccountId
                      AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' 
                      AND Program_Perspectives__c = 'ALR Cappex'
                      LIMIT 1];

String alrPDE;
String appilyAdvPDE;

if(listOfAlrPDE.size()>0){
    alrPDE = listOfAlrPDE[0].Staff_member__r.Name;
    System.debug('ALR PDE: ' + alrPDE);
}

if(listOfAppilyAdvPDE.size()>0){
    appilyAdvPDE = listOfAppilyAdvPDE[0].Staff_member__r.Name;
}

String shadowCreditUser;

if(creditingOpp.List_of_Product_Families__c.contains('Appily Advance - ALR') && listOfAlrPDE.size()>0 && !creditingOpp.List_of_Product_Families__c.contains('ALR,')){
    shadowCreditUser = alrPDE;
}else if(listOfAppilyAdvPDE.size()>0){
    shadowCreditUser = appilyAdvPDE;
}

List<SBQQ__QuoteLine__c> listOfQLs = new List<SBQQ__QuoteLine__c>();
List<SBQQ__QuoteLineGroup__c> listOfGroups = new List<SBQQ__QuoteLineGroup__c>();

if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == null || creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == 'Funds Appropriation Opt Out'){

    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name, SBQQ__Group__r.SBQQ__StartDate__c, SBQQ__Group__r.SBQQ__EndDate__c, SBQQ__Group__r.SBQQ__Number__c, Calculated_Product_Family__c  FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c
    ORDER BY SBQQ__Group__r.SBQQ__Number__c ASC ];  

    listOfGroups = [SELECT SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Number__c FROM SBQQ__QuoteLineGroup__c
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c];

} else {

    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name, SBQQ__Group__r.SBQQ__StartDate__c, SBQQ__Group__r.SBQQ__EndDate__c, SBQQ__Group__r.SBQQ__Number__c, Calculated_Product_Family__c FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c
    ORDER BY SBQQ__Group__r.SBQQ__Number__c ASC];  

    listOfGroups = [SELECT SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Number__c FROM SBQQ__QuoteLineGroup__c
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c];
}

for(SBQQ__QuoteLine__c qle :listOfQLs){  
        String programAcronym = null;

        mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c);  

        if(qle.SBQQ__ProductCode__c == cappexMembership && qle.Related_Product__c == 'Appily Advance - ALR'){
            // do nothing;
        }else{

            programAcronym = qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c);

        }

        if(programAcronym == null && qle.Calculated_Product_Family__c == 'ALR' && qle.SBQQ__ProductCode__c != cappexMembership){
            programAcronym = 'RYAG';
            // System.debug('Program: '+ programAcronym);
              
        }/*else if(programAcronym == null && qle.Calculated_Product_Family__c == 'ALR' && qle.SBQQ__ProductCode__c == cappexMembership){
            List<Product2> progName = [SELECT Program__r.Program_Acronym__c FROM Product2 WHERE Name =: qle.Related_Product__c LIMIT 1];
            programAcronym = progName[0].Program__r.Program_Acronym__c;
        }*/

        if(qle.SBQQ__Product__r.Family == 'Fee' || qle.SBQQ__Product__r.Family == 'Pass Through Cost'){
            programAcronym = null;
            // System.debug('Program: '+ programAcronym);
        }
        System.debug('Program: '+ programAcronym);
        mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, programAcronym);

        // System.debug('Product and Program: ' + mapOfProgramAndParentProductName);

        if(programAcronym != null){ 

            if(qle.SBQQ__ProductName__c != 'Appily Advance - ALR'){
               setOfProgramsAcronyms.add(programAcronym);  
            }
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

            if(mapOfProgramAndTotalCost.containsKey(programAcronym)) { 

                if(qle.SBQQ__ProductName__c == 'Cappex Advance Membership' && qle.SBQQ__CustomerTotal__c < 0){
                   mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + (0 - qle.SBQQ__CustomerTotal__c)); 
                }else{
                    mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + qle.SBQQ__CustomerTotal__c);  
                }

            } else{ 

                if(qle.SBQQ__ProductName__c == 'Cappex Advance Membership' && qle.SBQQ__CustomerTotal__c < 0){
                    mapOfProgramAndTotalCost.put(programAcronym, (0 - qle.SBQQ__CustomerTotal__c));
                }else{
                    mapOfProgramAndTotalCost.put(programAcronym, qle.SBQQ__CustomerTotal__c);
                }        

            }  

        }  


        if(isRenewalOpp && qle.Previous_Year_Quantity__c == 0){ 

            isOppRenewalUpsell = true; 

        } 

        if(!mapOfProgramAndFirstYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 1){
            mapOfProgramAndFirstYearTotal.put(programAcronym, qle.SBQQ__CustomerTotal__c);
        } else if (mapOfProgramAndFirstYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 1){
            mapOfProgramAndFirstYearTotal.put(programAcronym, mapOfProgramAndFirstYearTotal.get(programAcronym) + qle.SBQQ__CustomerTotal__c);
        }
    
        if(mapGrpAndTotal.containsKey(programAcronym)){
            if(mapGrpAndTotal.get(programAcronym).containsKey(qle.SBQQ__Group__r.SBQQ__Number__c)){
                mapGrpAndTotal.get(programAcronym).put(qle.SBQQ__Group__r.SBQQ__Number__c, mapGrpAndTotal.get(programAcronym).get(qle.SBQQ__Group__r.SBQQ__Number__c) + qle.SBQQ__CustomerTotal__c);
            }else{
                mapGrpAndTotal.get(programAcronym).put(qle.SBQQ__Group__r.SBQQ__Number__c, qle.SBQQ__CustomerTotal__c);
            }
            
        }else{
            Map<Decimal, Decimal> m = new Map<Decimal, Decimal>();
            m.put(qle.SBQQ__Group__r.SBQQ__Number__c, qle.SBQQ__CustomerTotal__c);
            mapGrpAndTotal.put(programAcronym, m);
        }

        if(mapOfProgramAndTotalCost.get(programAcronym) == 0){
            setOfProgramsAcronyms.remove(programAcronym);
        }

        // System.debug('program => ' + programAcronym);
        // System.debug('First Year Total => ' + mapGrpAndTotal.get(programAcronym).get(qle.SBQQ__Group__r.SBQQ__Number__c));
}

Set<String> setOfAppilyAdvanceProAccronyms = new Set<String>(setOfProgramsAcronyms);

if(setOfProgramsAcronyms.contains('EDCPQ')){
    setOfAppilyAdvanceProAccronyms.remove('EDCPQ');
} 
if(setOfProgramsAcronyms.contains('RYAG')){
    setOfAppilyAdvanceProAccronyms.remove('RYAG');
}
if(setOfProgramsAcronyms.contains('EDCP')){
    setOfAppilyAdvanceProAccronyms.remove('EDCP');
}

System.debug('Set of all Acronyms: '+setOfProgramsAcronyms);
System.debug('Set of Appily Adv Acronyms: '+setOfAppilyAdvanceProAccronyms);

for(SBQQ__QuoteLine__c qle :listOfQLs){

    if(qle.SBQQ__ProductCode__c == cappexMembership && (qle.Related_Product__c == 'Appily Advance - ALR' || qle.Related_Product__c == 'Grad Wide')){
        List<String> listOfStrings = new List<String>(setOfAppilyAdvanceProAccronyms);
        if(listOfStrings.size() > 0){
            String pro = listOfStrings[0];
            // System.debug('program to which membership will be added: ' + pro);
            membershipAddedToProg = listOfStrings[0];
            mapGrpAndTotal.get(pro).put(qle.SBQQ__Group__r.SBQQ__Number__c, 
                                                    mapGrpAndTotal.get(pro).get(qle.SBQQ__Group__r.SBQQ__Number__c) + qle.SBQQ__CustomerTotal__c);

            mapOfProgramAndTotalCost.put(pro, mapOfProgramAndTotalCost.get(pro) + qle.SBQQ__CustomerTotal__c);
        }     
    }
}



Boolean isThisARenewalForecasting = creditingOpp.IsFcstRenewal__c == 'Yes';  

Boolean isParentOppBlank = creditingOpp.Parent_Opportunity__c == null;  

Boolean isParentOppContracted = creditingOpp.Parent_Opportunity__c != null ? (creditingOpp.Parent_Opportunity__r.SBQQ__Ordered__c || creditingOpp.Parent_Opportunity__r.SBQQ__Contracted__c) : false;  

Boolean contractExist = false; 

List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND EndDate > :Date.today().addYears(-1) AND ID != :creditingOpp.LOA_Contract__c]; 

List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name, SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__r.ContractNumber   

FROM SBQQ__QuoteLine__c  

WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true ) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c = :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c = :listOfContractOnAccount)   

AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :setOfProgramsAcronyms)];  


contractExist = listOfQLsAssociatedToContracts.size() > 0;  

Set<String> setOfRenewalProg = new Set<String>();

if(contractExist){
    for(SBQQ__QuoteLine__c qLine : listOfQLsAssociatedToContracts){
        System.debug('Esxisting Contract: '+ qLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__r.ContractNumber);
        if(qLine.SBQQ__Product__r.Program__r.Program_Acronym__c != null){
            setOfRenewalProg.add(qLine.SBQQ__Product__r.Program__r.Program_Acronym__c);
            
        }    
    }
}

System.debug('Programs getting renewed: '+ setOfRenewalProg);

Date effectiveStartDate;

if(creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c >= contractSignatureDate){

        effectiveStartDate = creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c;
}else{
    effectiveStartDate = contractSignatureDate;
}

System.debug('--------------------------------------------- Deal Information ---------------------------------------------');
System.debug(' Effective Start Date: ' + effectiveStartDate);

Date currentFYStart;

Date today = consideredToday;/* Date.today(); */

Date Q2Start;

Date Q3Start;

Date Q4Start;

Date nextFyStart = Date.newInstance(today.year(), 7, 1);

Date dateATL;

if(today < nextFYStart){
    currentFYStart = Date.newInstance(today.year() - 1, 7, 1);
}else{
    nextFYStart = Date.newInstance(today.year() + 1, 7, 1);
    currentFYStart = Date.newInstance(today.year(), 7, 1);
}

Q2Start = Date.newInstance(currentFYStart.year(), 10, 1);
Q3Start = Date.newInstance(currentFYStart.year() + 1, 1, 1);
Q4Start = Date.newInstance(currentFYStart.year() + 1, 4, 1);

System.debug(' Current FY Start: '+ currentFYStart);
System.debug(' Q1 Start: ' + currentFYStart);
System.debug(' Q2 Start: '+ Q2Start);
System.debug(' Q3 Start: '+ Q3Start);
System.debug(' Q4 Start: '+ Q4Start);
System.debug(' Next FY Start: '+ nextFYStart);

mapOfQuarterAndProration.put('Q1', 0.75);
mapOfQuarterAndProration.put('Q2', 0.50);
mapOfQuarterAndProration.put('Q3', 0.25);
mapOfQuarterAndProration.put('Q4', 0);
mapOfQuarterAndProration.put('Future', 1);

Boolean isCurrentFYDeal = effectiveStartDate < nextFyStart;

Boolean isFutureDeal = effectiveStartDate >= nextFyStart;

Boolean containsALR = false;

Integer totalGroups = listOfGroups.size();

Integer totalNbbs;

Integer totalBaseOrFutureRev = setOfProgramsAcronyms.size();

Integer totalFutureRecNbbREcords = 0;

Integer totalShadowRecords = 0; 

if(shadowCreditUser != null){

    totalShadowRecords = (setOfAppilyAdvanceProAccronyms.size())*2;
}

Decimal prorateMultiplier;

Decimal securedYearValue;

Decimal baseFeeAmount;

Decimal futureRevenue;

Decimal futureYearRecNBB;

Decimal shadowNBB;

Decimal adamShadowNBB;

Boolean fixedRateContract = false;

Boolean penaltyFeeApplied = false;

String qtr;

String dealType;

String dealTypeBaseFee = 'Base Fee';

String dealTypeFutureRevenue = 'Future Revenue';

String dealTypeFutureYearRecNBB = 'Future Year Rec. NBB';

if(effectiveStartDate < Q2Start){
    qtr = 'Q1';
}else if(effectiveStartDate < Q3Start && effectiveStartDate >= Q2Start){
    qtr = 'Q2';
}else if(effectiveStartDate < Q4Start && effectiveStartDate >= Q3Start){
    qtr = 'Q3';
}else if(effectiveStartDate < nextFYStart && effectiveStartDate >= Q4Start){
    qtr = 'Q4';
}else{
    qtr = 'Future';
}

System.debug(' Deal falls in: '+ qtr);

if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null){
    System.debug('-----------------ALERT - Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c + ' ---------------  Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c + ' --------------'); 
}
if(creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null){
    System.debug('-----------------ALERT - Secondary Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c + '-------------   Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c + ' ---------------');
}

securedYearValue = mapOfQuarterAndProration.get(qtr) + totalGroups -1;

// System.debug('Total NBBs to be created: ' + totalNbbs);

if(setOfAppilyAdvanceProAccronyms.size() != setOfProgramsAcronyms.size()){
    containsALR = true;
}

for(String program : setOfProgramsAcronyms){

    if(((setOfRenewalProg !=null && !setOfRenewalProg.contains(program)) || setOfRenewalProg == null) && isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank || !isParentOppContracted) ) || isThisARenewalForecasting) && !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')  ){ 

    System.debug('====================================================== New Sale ======================================================'); 
    } 

    else if(creditingOpp.SBQQ__AmendedContract__c != null  || creditingOpp.Is_this_an_amend_and_restate_contract__c  == 'Yes' || isOppRenewalUpsell){  

        System.debug('----------------------------------Upsell RBB------------------------------------------'); 

    } 

    else{ 
        identifiedAsRenewal = true;
        System.debug('----------------------------------Renewal----------------------------------------------'); 

    }

    Decimal totalProgramCost = mapOfProgramAndTotalCost.get(program);

    Decimal nbbAmount;

    baseFeeAmount = 0;
    futureRevenue = 0;
    futureYearRecNBB = 0;

    if(securedYearValue != 0){
        nbbAmount = totalProgramCost/securedYearValue;
    }else{
        nbbAmount = totalProgramCost;
    }

    
    List<Decimal> tempList = mapGrpAndTotal.get(program).values();
    List<Decimal> listOfYearlyTotals = mapGrpAndTotal.get(program).values();

    tempList.sort();

    Set<Decimal> setOfYearlyTotals = new Set<Decimal>(tempList);

    if(setOfYearlyTotals.size() == 1){
        fixedRateContract = true;
    }

    if(nbbAmount > tempList[tempList.size()-1] || tempList.size() == 1){
        nbbAmount = tempList[tempList.size()-1];
    }

    if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null && creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c.contains('With Stated Penalty Fee')){
        penaltyFeeApplied = true;
        nbbAmount += creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out_Penalty_Amount__c*0.25;
    }

    if(tipsContract){
        nbbAmount = nbbAmount * 0.99;
        System.debug('--------------------------- TIPS CONTRACT ---------------------------');
        System.debug('\n');
    }

    if(isCurrentFYDeal){

        if((mapGrpAndTotal.get(program).get(1)).setScale(2) == 0 || tempList.size() == 1){
            baseFeeAmount = nbbAmount.setScale(2);
        } else{
            baseFeeAmount = (mapGrpAndTotal.get(program).get(1)).setScale(2);
            futureYearRecNBB = (nbbAmount - baseFeeAmount).setScale(2);
            
        }
        dealType = dealTypeBaseFee;
    } else{

        if((mapGrpAndTotal.get(program).get(1)).setScale(2) == 0 || tempList.size() == 1){
            futureRevenue = nbbAmount.setScale(2);
        } else{
            futureRevenue = (mapGrpAndTotal.get(program).get(1)).setScale(2);
            futureYearRecNBB = (nbbAmount - futureRevenue).setScale(2);
            
        }
        dealType = dealTypeFutureRevenue;
    }

    if(futureYearRecNBB > 0){
        totalFutureRecNbbREcords += 1;
    }
    
    shadowNBB = (nbbAmount).setScale(2);

    adamShadowNBB = 0 - shadowNBB;

    // if(!program.contains('CX')){
    //     containsALR = true;
    // }

    if(!containsALR){
        if(/*date.today()*/today.month() == mapOfProgramStartDate.get(program).month()){
        dateATL = today; //date.today();
        }else{
            dateATL = Date.newInstance(mapOfProgramStartDate.get(program).year(), mapOfProgramStartDate.get(program).month(), 1);
        }
    }else{
        dateATL = today;
    }


    if(fixedRateContract){
        System.debug('------------------------------------ FIXED RATE CONTRACT ------------------------------------');
    }

    System.debug('------------------------------------ Program: ' + program + ' Summary ------------------------------------');
    System.debug(' Yearly Program Totals: '+ tempList);
    System.debug(' Highest Year total: ' + tempList[tempList.size()-1]);
    System.debug(' Total Program Cost: '+totalProgramCost);
    System.debug(' Secured Year Value: ' + securedYearValue);
    if(penaltyFeeApplied == true){
    System.debug(' Total NBB: '+ nbbAmount.setScale(2) + '(25% of penalty fee is applied)');    
    }else{
        System.debug(' Total NBB: '+ nbbAmount.setScale(2));
    }
    System.debug(' Base Fee Amount: ' + baseFeeAmount);
    System.debug(' Future Revenue Amount: ' + futureRevenue);
    System.debug(' Future Year Rec. NBB Amount: ' + futureYearRecNBB);
    System.debug(' Shadow Credits: '+ shadowCreditUser);
    if(program == membershipAddedToProg){
       System.debug('\n'); 
       System.debug('////////// Please Note that Cappex Membership Amounts are added to this program ///////////////////'); 
    }
    

    System.debug('\n');
    System.debug('------------------------------------------ Crediting Record Details -----------------------------------------');

    if(futureYearRecNBB > 0){

        System.debug('------------------------------------ NBB ('+ dealType +') Record Details ------------------------------------');
        System.debug(' Program: ' + program);
        System.debug(' Credited User: '+ oppOwner);
        if(dealType == 'Future Revenue'){
            System.debug(' NBB Amount: ' + futureRevenue);  
        }else{
            System.debug(' NBB Amount:' + baseFeeAmount);
        }
        System.debug(' NBB Type: '+ dealType);
        System.debug(' ATL Date: '+ dateATL);
        System.debug(' Binder Date: '+ dateATL);
        System.debug(' Deal Type: '+ 'New Sale');

        System.debug('------------------------------------ NBB (Future Year Rec. NBB) Record Details ------------------------------------');
        System.debug(' Program: ' + program);
        System.debug(' Credited User: '+ oppOwner);
        System.debug(' NBB Amount: ' + futureYearRecNBB);
        System.debug(' NBB Type: '+ dealTypeFutureYearRecNBB);
        System.debug(' ATL Date: '+ dateATL);
        System.debug(' Binder Date: '+ dateATL);
        System.debug(' Deal Type: '+ 'New Sale');

    } else{

        System.debug('------------------------------------ NBB ('+ dealType +') Record Details ------------------------------------');
        System.debug(' Program => ' + program);
        System.debug(' Credited User => '+ oppOwner);
        if(dealType == 'Future Revenue'){
            System.debug(' NBB Amount: ' + futureRevenue);  
        }else{
            System.debug(' NBB Amount:' + baseFeeAmount);
        }
        System.debug(' NBB Type => '+ dealType);
        System.debug(' ATL Date => '+ dateATL);
        System.debug(' Binder Date => '+ dateATL);
        System.debug(' Deal Type => '+ 'New Sale');

    }

    if(shadowCreditUser != null && !containsALR){
        System.debug('------------------------------------ 1st Shadow Record Details ------------------------------------');
        System.debug(' Program => ' + program);
        System.debug(' Credited User => '+ shadowCreditUser);
        System.debug(' NBB Amount => ' + shadowNBB);
        System.debug(' NBB Type => '+ 'Shadow Credit');
        System.debug(' ATL Date => '+ dateATL);
        System.debug(' Binder Date => '+ dateATL);
        System.debug(' Deal Type => '+ 'New Sale');

        System.debug('------------------------------------ 2nd Shadow Record Details ------------------------------------');
        System.debug(' Program => ' + program);
        System.debug(' Credited User => '+ 'Adam Sutton');
        System.debug(' NBB Amount => ' + adamShadowNBB);
        System.debug(' NBB Type => '+ 'Shadow Credit');
        System.debug(' ATL Date => '+ dateATL);
        System.debug(' Binder Date => '+ dateATL);
        System.debug(' Deal Type => '+ 'New Sale');
    }
    
}

totalNbbs = totalFutureRecNbbREcords + totalShadowRecords + totalBaseOrFutureRev;
System.debug('\n');
System.debug('---------------------------------------- Total NBB Records Summary ----------------------------------------');
System.debug(' Total '+ dealType + ' records: ' +  totalBaseOrFutureRev);
System.debug(' Total Future Year Rec NBB records: ' + totalFutureRecNbbREcords);
System.debug(' Total Shadow Records: '+ totalShadowRecords);
System.debug(' Total Records to be created: '+ totalNbbs);
System.debug('-----------------------------------------------------------------------------------------------------------');


