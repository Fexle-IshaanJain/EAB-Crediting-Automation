ID OppId = '006Pr00000Jl5HRIAZ';
String signedDate = '2/27/2025';
String oppCameInQueue = '3/3/2025';
Date consideredToday = Date.parse(oppCameInQueue);
Date contractSignatureDate = Date.parse(signedDate);
Boolean tipsContract = false;

Opportunity creditingOpp = [SELECT ID,Owner.Name, Owner.Division, OwnerId, Account.Cappex_Partner_Success_Manager__c, List_of_Product_Families__c, Commercial_Team__c, StageName, LOA_Contract__c, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c
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
Set<String> setOfRenewalbleProgramsSoldInPast = new Set<String>();

String oppOwner = creditingOpp.Owner.Name;

Map<String,Date> mapOfProgramStartDate = new Map<String,Date>();
Map<String,Date> mapOfProgramEndDate = new Map<String,Date>();
Map<String,Decimal> mapOfProgramAndTotalCost = new Map<String,Decimal>();
Map<String, Decimal> mapOfProgramAndNBBAmount = new Map<String, Decimal>();
Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();
//Map<String,Decimal> mapOfProgramAndFirstYearTotal = new Map<String,Decimal>();
//Map<String,Decimal> mapOfProgramAndSecondYearTotal = new Map<String,Decimal>();
Map<String, Map<Decimal, Decimal>> mapGrpAndTotal = new Map<String, Map<Decimal, Decimal>>();

Set<String> setOfRenewablePrograms_Agency = new Set<String>{'ESDA - Enrollment Services - Agency'};
Set<String> setOfOneTimePrograms_Agency = new Set<String>{'ESDNR - Agency Non Renewable'};

Set<String> setOfOneTimeProducts_Agency = new Set<String>{'AGC-Market_Perception_Survey','AGC-Admitted_Student_Survey','AGC-Alumni_Engagmnt_Survey','AGC-Tuition_Pricing_Survey','AGC-First-Year_Experience_Survey','AGC-Issue_Analysis_Survey','AGC-Non_Applicant_Survey'};

List<SBQQ__QuoteLine__c> listOfQLs = new List<SBQQ__QuoteLine__c>();
List<SBQQ__QuoteLineGroup__c> listOfGroups = new List<SBQQ__QuoteLineGroup__c>();

List<Team_Membership__c> listOfAgencyPDE = [SELECT Staff_member__r.Name FROM Team_Membership__c 
                      WHERE Institution__c =: creditingOpp.AccountId
                      AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' 
                      AND Program_Perspectives__c = 'Digital Agency'
                      LIMIT 1];

Boolean isOppSendToFinance = creditingOpp.StageName == sendToFinance;  
Boolean isInitiatingOpp =  creditingOpp.Type2__c == initiatingOpp;  
Boolean isContinuingOpp =  creditingOpp.Type2__c == continuingOpp;  
Boolean isAmendmentOpp =  creditingOpp.Type2__c == amendmentOpp;  
Boolean isRenewalOpp =  creditingOpp.Type2__c == renewalOpp || creditingOpp.SBQQ__RenewedContract__c != null;  
Boolean isDiscountProductUsed = false;
Boolean isLegacyAcquisitionOpp =  creditingOpp.Type2__c == legacyAcquisitionOpp;  

Set<String> setOfProgramsAcronyms = new Set<String>();  
Set<String> setOfProductCode = new Set<String>();

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


for(SBQQ__QuoteLine__c qle :listOfQLs)
{  
        String programAcronym = null;
        mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c); 
        programAcronym = setOfOneTimeProducts_Agency.contains(qle.SBQQ__ProductCode__c) ? 'ESDNR - Agency Non Renewable' :  (qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c));
        //System.debug('programAcronym => ' +  programAcronym);
        //System.debug('QLE GRP=> ' +  qle.SBQQ__Group__r.SBQQ__Number__c);

        if(qle.SBQQ__ProductCode__c == 'DISC-EAB_Invstmnt')
        {
          isDiscountProductUsed = true;
        }  
        if(programAcronym != null && (programAcronym == 'ESDNR - Agency Non Renewable' || programAcronym == 'ESDA'))
        {  
           setOfProgramsAcronyms.add(programAcronym); 
           //System.debug('setOfProgramsAcronyms => ' +  setOfProgramsAcronyms);
           Date startDate = qle.SBQQ__StartDate__c; 
           Date endDate = qle.SBQQ__EndDate__c; 
           if(mapOfProgramStartDate != null && mapOfProgramStartDate.containsKey(programAcronym))
           { 
                if(startDate > mapOfProgramStartDate.get(programAcronym))
                { 

                    startDate = mapOfProgramStartDate.get(programAcronym);
                    //System.debug('startDate => ' +  startDate); 
                } 
            } 

            if(mapOfProgramEndDate != null && mapOfProgramEndDate.containsKey(programAcronym))
            { 

                if(endDate < mapOfProgramEndDate.get(programAcronym))
                { 
                    endDate = mapOfProgramEndDate.get(programAcronym); 
                    //System.debug('endDate => ' +  endDate);

                } 
            } 
            mapOfProgramStartDate.put(programAcronym, startDate);  
            mapOfProgramEndDate.put(programAcronym, endDate);
            //System.debug(' mapOfProgramStartDate => ' +   mapOfProgramStartDate);
            //System.debug(' mapOfProgramEndDate => ' +  mapOfProgramEndDate);  

            
            if(mapOfProgramAndTotalCost.containsKey(programAcronym)) 
            { 

                if( qle.SBQQ__CustomerTotal__c < 0)
                {
                   mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + (0 - qle.SBQQ__CustomerTotal__c)); 
                }
                else
                {
                    mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + qle.SBQQ__CustomerTotal__c);  
                }

            }
            else
            {
                mapOfProgramAndTotalCost.put(programAcronym, qle.SBQQ__CustomerTotal__c); 
            } 
        }
        if(isRenewalOpp && qle.Previous_Year_Quantity__c == 0)
        { 
            isOppRenewalUpsell = true; 
        } 
        
        /*if(!mapOfProgramAndFirstYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 1)
        {
            mapOfProgramAndFirstYearTotal.put(programAcronym, qle.SBQQ__CustomerTotal__c);
        } 
        else if (mapOfProgramAndFirstYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 1)
        {
            mapOfProgramAndFirstYearTotal.put(programAcronym, mapOfProgramAndFirstYearTotal.get(programAcronym) + qle.SBQQ__CustomerTotal__c);
        }

        //System.debug('qle.SBQQ__Group__r.SBQQ__Number__c => ' + qle.SBQQ__Group__r.SBQQ__Number__c);

        if(!mapOfProgramAndSecondYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 2)
        {
            mapOfProgramAndSecondYearTotal.put(programAcronym, qle.SBQQ__CustomerTotal__c);
        } 
        else if (mapOfProgramAndSecondYearTotal.containsKey(programAcronym) && qle.SBQQ__Group__r.SBQQ__Number__c == 2)
        {
            mapOfProgramAndSecondYearTotal.put(programAcronym, mapOfProgramAndSecondYearTotal.get(programAcronym) + qle.SBQQ__CustomerTotal__c);
        }*/
    
        if(mapGrpAndTotal.containsKey(programAcronym))
        {
            if(mapGrpAndTotal.get(programAcronym).containsKey(qle.SBQQ__Group__r.SBQQ__Number__c))
            {
                mapGrpAndTotal.get(programAcronym).put(qle.SBQQ__Group__r.SBQQ__Number__c, mapGrpAndTotal.get(programAcronym).get(qle.SBQQ__Group__r.SBQQ__Number__c) + qle.SBQQ__CustomerTotal__c);
            }
            else
            {
                mapGrpAndTotal.get(programAcronym).put(qle.SBQQ__Group__r.SBQQ__Number__c, qle.SBQQ__CustomerTotal__c);
            }
            
        }
        else
        {
            Map<Decimal, Decimal> m = new Map<Decimal, Decimal>();
            m.put(qle.SBQQ__Group__r.SBQQ__Number__c, qle.SBQQ__CustomerTotal__c);
            mapGrpAndTotal.put(programAcronym, m);
        }

        if(mapOfProgramAndTotalCost.get(programAcronym) == 0)
        {
            setOfProgramsAcronyms.remove(programAcronym);
        }

        //System.debug('program => ' + programAcronym);
        //System.debug('MapTotal => ' + mapGrpAndTotal.get(programAcronym).get(qle.SBQQ__Group__r.SBQQ__Number__c));
        //System.debug('MapTotal => ' + mapGrpAndTotal);
        //system.debug('Set of Programs =>' +  setOfProgramsAcronyms);
        
}

Boolean isThisARenewalForecasting = creditingOpp.IsFcstRenewal__c == 'Yes';  
Boolean isParentOppBlank = creditingOpp.Parent_Opportunity__c == null;  
Boolean isParentOppContracted = creditingOpp.Parent_Opportunity__c != null ? (creditingOpp.Parent_Opportunity__r.SBQQ__Ordered__c || creditingOpp.Parent_Opportunity__r.SBQQ__Contracted__c) : false;  
Boolean contractExist = false; 

//For doing new crediting
List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND StartDate < :Date.today().addYears(-1) AND EndDate > :Date.today().addYears(-1) AND ID != :creditingOpp.LOA_Contract__c]; 

//For checking old Crediting
//List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND StartDate < :creditingOpp.LOA_Contract__r.StartDate.addYears(-1) AND EndDate > :creditingOpp.LOA_Contract__r.StartDate.addYears(-1) AND ID != :creditingOpp.LOA_Contract__c];

List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name
FROM SBQQ__QuoteLine__c
WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true ) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c = :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c = :listOfContractOnAccount)   
AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :setOfProgramsAcronyms)];  
contractExist = listOfQLsAssociatedToContracts.size() > 0;  

if(!listOfQLsAssociatedToContracts.isEmpty() && listOfQLsAssociatedToContracts.size() > 0){
    for(SBQQ__QuoteLine__c qle :listOfQLsAssociatedToContracts){
        setOfRenewalbleProgramsSoldInPast.add(qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
    }
}

Decimal nbbAmountESDA ;
Decimal nbbAmountESDNR ;

Boolean fixedRateContract = false;

for(String program : setOfProgramsAcronyms)
{

   Decimal value2;
   Decimal value1;
   Map<Decimal, Decimal> innerMap =  mapGrpAndTotal.get(program);
   if (program == 'ESDA')
   {
      
      value2 = innerMap.get(2);
      value1 = innerMap.get(1);

      if(innerMap != null && innerMap.containsKey(2))
      {

        if(value2 == value1*0.65 )
        {
            nbbAmountESDA = value1;
        }
        if(value2 < (value1*0.65))
        {
            nbbAmountESDA = value2 + (0.3*(value1-value2));
        }
        else
        {
            nbbAmountESDA = value1;
        }
      } 
      else 
      { 
           nbbAmountESDA = value1;
      } 

    //System.debug('nbbAmountESDA => ' + nbbAmountESDA);
    }
    if ((program == 'ESDNR - Agency Non Renewable' || program == 'ESDNR')&& innerMap != null )
    {
      
        value1 = innerMap.get(1);
        nbbAmountESDNR = 0.3*value1;
        //System.debug('nbbAmountESDNR =>' + nbbAmountESDNR);
    }

    List<Decimal> tempList = mapGrpAndTotal.get(program).values();
    List<Decimal> listOfYearlyTotals = mapGrpAndTotal.get(program).values();

    tempList.sort();

    Set<Decimal> setOfYearlyTotals = new Set<Decimal>(tempList);

    if(setOfYearlyTotals.size() == 1)
    {
        fixedRateContract = true;
    }

}

Date effectiveStartDate;

if(creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c >= contractSignatureDate){

        effectiveStartDate = creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c;
}else{
    effectiveStartDate = contractSignatureDate;
}
//System.debug(' Effective Start Date: ' + effectiveStartDate);

Date currentFYStart;
Date today = consideredToday;/* Date.today(); */
Date nextFyStart = Date.newInstance(today.year(), 7, 1);

if(today < nextFyStart){
    currentFYStart = Date.newInstance(today.year() - 1, 7, 1);
}else{
    nextFyStart = Date.newInstance(today.year() + 1, 7, 1);
    currentFYStart = Date.newInstance(today.year(), 7, 1);
}

Boolean isCurrentFYDeal = effectiveStartDate < nextFyStart;
Boolean isFutureDeal = effectiveStartDate >= nextFyStart;

Decimal baseFeeAmount;
Decimal futureRevenue;
Decimal futureYearRecNBB;
String dealType;
String dealTypeBaseFee = 'Base Fee';
String dealTypeFutureRevenue = 'Future Revenue';
String dealTypeFutureYearRecNBB = 'Future Year Rec. NBB';

if(tipsContract)
{
        nbbAmountESDA = nbbAmountESDA * 0.99;
        nbbAmountESDNR = nbbAmountESDNR * 0.99;
        System.debug('--------------------------- TIPS CONTRACT ---------------------------');
        System.debug('\n');
}

if(fixedRateContract)
{
        System.debug('------------------------------------ FIXED RATE CONTRACT ------------------------------------');
}

if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null){
    System.debug('-----------------ALERT - Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c + ' ---------------  Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c + ' --------------'); 
}
if(creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null){
    System.debug('-----------------ALERT - Secondary Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c + '-------------   Date: '+ creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Early_Termination_Date__c + ' ---------------');
}

Integer counter = 0;
for(String program : setOfProgramsAcronyms)
{
  Boolean upsellRBB = false;
  baseFeeAmount = 0;
  futureRevenue = 0;
  futureYearRecNBB = 0;

  Decimal value2;
  Decimal value1;
  Map<Decimal, Decimal> innerMap =  mapGrpAndTotal.get(program);
    
  if(isCurrentFYDeal && program == 'ESDA')
  {
        if(nbbAmountESDA > innerMap.get(1))
        {
            baseFeeAmount = nbbAmountESDA.setScale(2);
        } 
        else
        {
            baseFeeAmount = (innerMap.get(1)).setScale(2);
            futureYearRecNBB = (nbbAmountESDA - innerMap.get(1)).setScale(2);  
        }
        dealType = dealTypeBaseFee;
    } 
    else if(isFutureDeal && program == 'ESDA')
    {
        if(nbbAmountESDA > innerMap.get(1)){
            futureRevenue = nbbAmountESDA.setScale(2);
        } 
        else
        {
            futureRevenue = (innerMap.get(1)).setScale(2);
            futureYearRecNBB = (nbbAmountESDA - innerMap.get(1)).setScale(2);    
        }
        dealType = dealTypeFutureRevenue;
    }


  if(mapGrpAndTotal.get(program) != null && (program == 'ESDA' || program == 'ESDNR - Agency Non Renewable' || program == 'ESDNR'))
  {

        if(counter == 0)
        {
          System.debug('\n');
          System.debug('=====================================================DEAL INFORMATION======================================================');
          System.debug(' Total Programs to credit : ' + setOfProgramsAcronyms.size());
          System.debug(' Set Of Programs to credit : ' + setOfProgramsAcronyms);
          System.debug(' Propsal Start Date : ' + mapOfProgramStartDate);
          System.debug(' Propsal End Date : ' + mapOfProgramEndDate);
          System.debug(' Cost of Program Without A&T : ' + mapOfProgramAndTotalCost);
          System.debug('===========================================================================================================================');
        }
  }
  if( isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank || !isParentOppContracted) ) || isThisARenewalForecasting)  &&  !contractExist && !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')  )
  { 
       System.debug('====================================================== New Sale ======================================================'); 
  }
  else if(creditingOpp.SBQQ__AmendedContract__c != null  || creditingOpp.Is_this_an_amend_and_restate_contract__c  == 'Yes' || isOppRenewalUpsell)
  {
    System.debug('================================================Upsell RBB=====================================================');
    upsellRBB = true;
            
  }
  else
  {
    identifiedAsRenewal = true;
    System.debug('================================================Renewal========================================================');
  }
  System.debug('--------------------------------------------------Program to Credit :'+program +' -------------------------------------------------'); 
  System.debug(' Program :' + program);
  System.debug(' Program Start Date :' + mapOfProgramStartDate.get(program)); 
  System.debug(' Program End Date :' + mapOfProgramEndDate.get(program));
  if(listOfAgencyPDE.size()>0)
  {
     System.debug(' Credited User: '+ listOfAgencyPDE[0].Staff_member__r.Name); 
  }else{
     System.debug(' Credited User: '+ oppOwner); 
  }

  if(dealType == 'Base Fee' && program == 'ESDA')
  {
    System.debug(' Base Fee Amount: ' + baseFeeAmount);
    if(futureRevenue != 0)
    {
       System.debug(' Future Revenue Amount: ' + futureRevenue);
    }  
  }
  if(dealType == 'Future Revenue' && program == 'ESDA')
  {
    System.debug(' Future Revenue Amount: ' + futureRevenue);
    if(futureYearRecNBB != 0)
    {
      System.debug(' Future Year Rec. NBB Amount: ' + futureYearRecNBB); 
    }
    
  }
  if((program == 'ESDNR - Agency Non Renewable' || program == 'ESDNR'))
  {
    System.debug(' NBB Amount: ' + nbbAmountESDNR);
  }
  System.debug(' NBB Type: '+ 'Base Fee');
  System.debug(' ATL Date: '+ today);
  System.debug(' Binder Date: '+ today);
  System.debug(' Deal Type: '+ 'New Sale');
  System.debug('-------------------------------------------------------------------------------------------------------------------------------------'); 

}
