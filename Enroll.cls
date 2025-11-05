ID OppId = '006Pr00000KAI9qIAH'; 
String signedDate = '10/03/2025';
String oppCameInQueue = '10/03/2025';
Boolean tipsContract = false;

Date consideredToday = Date.parse(oppCameInQueue);
Date contractSignatureDate = Date.parse(signedDate);

Opportunity creditingOpp = [SELECT ID, StageName, LOA_Contract__c, Contract_Signature_Date__c, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c, Owner.Name, List_of_Product_Families__c, SBQQ__PrimaryQuote__r.Opt_Out_Penalty_Amount__c, SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c
FROM Opportunity
WHERE ID = :OppId LIMIT 1]; 
  
Boolean identifiedAsRenewal = false;
Boolean isOppRenewalUpsell = false;
Boolean identifiedAsAmendment = false;
Boolean identifiedNBB = false;
Boolean isDiscountProductUsed = false;
Boolean isOppSendToFinance = creditingOpp.StageName == 'Contract Received - Send to Finance';  
Boolean isInitiatingOpp =  creditingOpp.Type2__c == 'Initiating';  
Boolean isContinuingOpp =  creditingOpp.Type2__c == 'Continuing';  
Boolean isAmendmentOpp =  creditingOpp.Type2__c == 'Amendment';  
Boolean isRenewalOpp =  creditingOpp.Type2__c == 'Renewal' || creditingOpp.SBQQ__RenewedContract__c != null;  
Boolean isLegacyAcquisitionOpp =  creditingOpp.Type2__c == 'Legacy Acquisition';
Boolean isThisARenewalForecasting = creditingOpp.IsFcstRenewal__c == 'Yes';  
Boolean isParentOppBlank = creditingOpp.Parent_Opportunity__c == null;  
Boolean isParentOppContracted = creditingOpp.Parent_Opportunity__c != null ? (creditingOpp.Parent_Opportunity__r.SBQQ__Ordered__c || creditingOpp.Parent_Opportunity__r.SBQQ__Contracted__c) : false;  
Boolean contractExist = false; 

String oppOwner = creditingOpp.Owner.Name;
String RYAUPde;

Map<String,Date> mapOfProgramStartDate = new Map<String,Date>();  
Map<String,Date> mapOfProgramEndDate = new Map<String,Date>();  
Map<String,Decimal> mapOfProgramAndTotalCost = new Map<String,Decimal>();  
Map<String, Decimal> mapOfProgramAndNBBAmount = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndImplementationFee = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndAdminTravelFee = new Map<String, Decimal>();  
Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();
Map<String,Decimal> mapOfProgramAndFirstYearTotal = new Map<String,Decimal>();
Map<String, Map<Decimal, Decimal>> mapGrpAndTotal = new Map<String, Map<Decimal, Decimal>>();
Map<String, Decimal> mapOfQuarterAndProration = new Map<String, Decimal>();
Map<String, Decimal> mmapOfMembershipAndTotal = new Map<String, Decimal>();

Set<String> setOfRenewablePrograms_RYAU = new Set<String>{'RYAU - Royall Admissions - Undergraduate'};
Set<String> setOfProgramsAcronyms = new Set<String>();  
Set<String> setOfProductCode = new Set<String>();
Set<String> setOfRenewalbleProgramsSoldInPast = new Set<String>();

List<SBQQ__QuoteLine__c> listOfQLs = new List<SBQQ__QuoteLine__c>();
List<SBQQ__QuoteLineGroup__c> listOfGroups = new List<SBQQ__QuoteLineGroup__c>();

List<Team_Membership__c> listOfUgPDE = [SELECT Staff_member__r.Name FROM Team_Membership__c 
                      WHERE Institution__c =: creditingOpp.AccountId
                      AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' 
                      AND Program_Perspectives__c = 'Undergrad Enrollment'
                      LIMIT 1];

if(listofUgPDE.size()>0)
{
    RYAUPde = listofUgPDE[0].Staff_member__r.Name;
    //System.debug('RYAU PDE: ' + RYAUPDE);
}

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

for(SBQQ__QuoteLine__c qle :listofQLs)
{
   String programAcronym = null;
   
   if(qle.Calculated_Product_Family__c == 'Enroll 360')
   {
     mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
     programAcronym = qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c);  
   }
   //System.debug('Program: '+ programAcronym);
    if((programAcronym == null  || programAcronym == 'ESAM' || programAcronym == 'ESYRS') && qle.Calculated_Product_Family__c == 'Enroll 360' && qle.SBQQ__Product__r.Family != 'Pass Through Cost'){
            programAcronym = 'RYAU';
            // System.debug('Program: '+ programAcronym);
              
        }
   if(qle.SBQQ__Product__r.Family == 'Fee' || qle.SBQQ__Product__r.Family == 'Pass Through Cost')
   {
            programAcronym = null;
            //System.debug('Program: '+ programAcronym);
   }
   if(qle.SBQQ__ProductCode__c == 'DISC-EAB_Invstmnt')
   {
        isDiscountProductUsed = true;     
   }
   if(qle.Calculated_Product_Family__c == 'Enroll 360' || qle.SBQQ__Product__r.Family == 'Pass Through Cost' )
   {
     mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, programAcronym);
   }
   //System.debug('Product and Program: ' + mapOfProgramAndParentProductName);

    if(programAcronym != null && (programAcronym == 'ESAM'|| programAcronym == 'RYAU'))
    { 

            setOfProgramsAcronyms.add(programAcronym); 
            //System.debug('setOfProgramsAcronyms: '+ setOfProgramsAcronyms);

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

            if(mapOfProgramAndTotalCost.containsKey(programAcronym)) 
            { 
                    mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + qle.SBQQ__CustomerTotal__c);  
                    //System.debug(' mapOfProgramAndTotalCost: ' +  mapOfProgramAndTotalCost);
            } 
            else
            { 
                    mapOfProgramAndTotalCost.put(programAcronym, qle.SBQQ__CustomerTotal__c);      
                    //System.debug(' mapOfProgramAndTotalCost: ' +  mapOfProgramAndTotalCost);
            }  

        } 
        if(qle.SBQQ__Product__r.Family != 'Fee' && qle.SBQQ__Product__r.Family != 'Pass Through Cost')
        {  
          setOfProductCode.add(qle.SBQQ__ProductCode__c);  
        } 
        
        if(isRenewalOpp && qle.Previous_Year_Quantity__c == 0)
        { 
            isOppRenewalUpsell = true; 
        } 

        if(!mapOfProgramAndFirstYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 1){
            mapOfProgramAndFirstYearTotal.put(programAcronym, qle.SBQQ__CustomerTotal__c);
        } else if (mapOfProgramAndFirstYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 1){
            mapOfProgramAndFirstYearTotal.put(programAcronym, mapOfProgramAndFirstYearTotal.get(programAcronym) + qle.SBQQ__CustomerTotal__c);
        }
    
        if(mapGrpAndTotal.containsKey(programAcronym))
        {
            if(mapGrpAndTotal.get(programAcronym).containsKey(qle.SBQQ__Group__r.SBQQ__Number__c)){
                mapGrpAndTotal.get(programAcronym).put(qle.SBQQ__Group__r.SBQQ__Number__c, mapGrpAndTotal.get(programAcronym).get(qle.SBQQ__Group__r.SBQQ__Number__c) + qle.SBQQ__CustomerTotal__c);
            }else{
                mapGrpAndTotal.get(programAcronym).put(qle.SBQQ__Group__r.SBQQ__Number__c, qle.SBQQ__CustomerTotal__c);
            }
 
        }     
        else
        {
            Map<Decimal, Decimal> m = new Map<Decimal, Decimal>();
            m.put(qle.SBQQ__Group__r.SBQQ__Number__c, qle.SBQQ__CustomerTotal__c);
            mapGrpAndTotal.put(programAcronym, m);
        }
        //System.debug('mapGrpAndTotal: ' +  mapGrpAndTotal);
        //System.debug(' mapOfProgramAndFirstYearTotal: ' +   mapOfProgramAndFirstYearTotal);

        if(mapOfProgramAndTotalCost.get(programAcronym) == 0){
            setOfProgramsAcronyms.remove(programAcronym);
        }

        //System.debug('program => ' + programAcronym);
        //System.debug('First Year Total => ' + mapGrpAndTotal.get(programAcronym).get(qle.SBQQ__Group__r.SBQQ__Number__c));
}

List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND EndDate > :Date.today().addYears(-1) AND ID != :creditingOpp.LOA_Contract__c]; 

List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name, SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__r.ContractNumber   
FROM SBQQ__QuoteLine__c  
WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true ) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c = :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c = :listOfContractOnAccount)   
AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :setOfProgramsAcronyms)];  

contractExist = listOfQLsAssociatedToContracts.size() > 0;  
 
if(!listOfQLsAssociatedToContracts.isEmpty() && contractExist){
    for(SBQQ__QuoteLine__c qle :listOfQLsAssociatedToContracts){
        setOfRenewalbleProgramsSoldInPast.add(qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
        //System.debug('Contract: '+ qle.SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__r.ContractNumber);
    }
}
if( isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank || !isParentOppContracted) ) || isThisARenewalForecasting)  &&  !contractExist && !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')  ){ 

    System.debug('====================================================== New Sale ======================================================'); 

} 
else{ 
    identifiedAsRenewal = true;
    System.debug('----------------------------------Renewal----------------------------------------------'); 

}
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

Date nextFYStart = Date.newInstance(today.year(), 7, 1);
Date dateATL = today;

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

mapOfQuarterAndProration.put('Q1', 1);
mapOfQuarterAndProration.put('Q2', 0.75);
mapOfQuarterAndProration.put('Q3', 0.50);
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

Decimal prorateMultiplier;
Decimal securedYearValue;
Decimal baseFeeAmount;
Decimal futureRevenue;
Decimal futureYearRecNBB;
Decimal shadowNBB;
Decimal adamShadowNBB;

Boolean fixedRateContract = false;

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

for(String program : setOfProgramsAcronyms){

    Decimal totalProgramCost = mapOfProgramAndTotalCost.get(program);

    Decimal nbbAmount;

    baseFeeAmount = 0;
    futureRevenue = 0;
    futureYearRecNBB = 0;

    if(securedYearValue != 0){
        nbbAmount = totalProgramCost/securedYearValue;
        System.debug('nbbAmount = ' + nbbAmount);
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
        System.debug('nbbAmount = ' + nbbAmount);
    }

    if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null && creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c.contains('With Stated Penalty Fee')){
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
            //System.debug('futureYearRecNBB' + futureYearRecNBB);
            //System.debug('nbbAmount = ' + nbbAmount);
            //System.debug('baseFeeAmount = ' + baseFeeAmount);
            
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

    if(fixedRateContract){
        System.debug('------------------------------------ FIXED RATE CONTRACT ------------------------------------');
    }
    if(program == 'ESAM')
    {
         System.debug('------------------------------------ Program: ' + 'RYAU' + ' Summary ------------------------------------');
    }
    else
    {
        System.debug('------------------------------------ Program: ' + program + ' Summary ------------------------------------');
    }
    System.debug(' Yearly Program Totals: '+ tempList);
    System.debug(' Highest Year total: ' + tempList[tempList.size()-1]);
    System.debug(' Total Program Cost: '+totalProgramCost);
    System.debug(' Secured Year Value: ' + securedYearValue);
    System.debug(' Total NBB: '+ nbbAmount.setScale(2));
    System.debug(' Base Fee Amount: ' + baseFeeAmount);
    System.debug(' Future Revenue Amount: ' + futureRevenue);
    System.debug(' Future Year Rec. NBB Amount: ' + futureYearRecNBB);
    //System.debug(' Shadow Credits: '+ shadowCreditUser);
    System.debug('------------------------------------------ Crediting Record Details -----------------------------------------');
    if(futureYearRecNBB > 0){

        System.debug('------------------------------------ NBB ('+ dealType +') Record Details ------------------------------------');
        if(program == 'ESAM')
        {
           System.debug(' Program: ' + 'RYAU - Royall Admissions - Undergraduate');
        }
        else
        {
           System.debug(' Program: ' + program);
        }
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
        if(program == 'ESAM')
        {
           System.debug(' Program: ' + 'RYAU - Royall Admissions - Undergraduate');
        }
        else
        {
           System.debug(' Program: ' + program);
        }
        System.debug(' Credited User: '+ oppOwner);
        System.debug(' NBB Amount: ' + futureYearRecNBB);
        System.debug(' NBB Type: '+ dealTypeFutureYearRecNBB);
        System.debug(' ATL Date: '+ dateATL);
        System.debug(' Binder Date: '+ dateATL);
        System.debug(' Deal Type: '+ 'New Sale');

    } else{

        System.debug('------------------------------------ NBB ('+ dealType +') Record Details ------------------------------------');
        if(program == 'ESAM')
        {
           System.debug(' Program: ' + 'RYAU - Royall Admissions - Undergraduate');
        }
        else
        {
           System.debug(' Program: ' + program);
        }
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
}

totalNbbs = totalFutureRecNbbREcords + totalShadowRecords + totalBaseOrFutureRev;
System.debug('\n');
System.debug('---------------------------------------- Total NBB Records Summary ----------------------------------------');
System.debug(' Total '+ dealType + ' records: ' +  totalBaseOrFutureRev);
System.debug(' Total Future Year Rec NBB records: ' + totalFutureRecNbbREcords);
System.debug(' Total Shadow Records: '+ totalShadowRecords);
System.debug(' Total Records to be created: '+ totalNbbs);
System.debug('-----------------------------------------------------------------------------------------------------------');   