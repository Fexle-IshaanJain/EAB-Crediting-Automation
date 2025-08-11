//Virtual Tour
ID OppId = '006Pr00000FYutZIAT';
//String signedDate = '';
//String oppCameInQueue = '';
//Date consideredToday = Date.parse(oppCameInQueue);
//Date contractSignatureDate = Date.parse(signedDate);
Boolean tipsContract = false;

Opportunity creditingOpp = [SELECT ID, StageName, List_of_Product_Families__c,  Owner.Name, LOA_Contract__c, LOA_Contract__r.StartDate, LOA_Contract__r.EndDate,  SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c
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
Map<String,Date> mapOfProgramStartDate = new Map<String,Date>();  
Map<String,Date> mapOfProgramEndDate = new Map<String,Date>();  
Map<String,Decimal> mapOfProgramAndTotalCost = new Map<String,Decimal>();  
Map<String, Decimal> mapOfProgramAndNBBAmount = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndImplementationFee = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndAdminTravelFee = new Map<String, Decimal>();  
Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();

Set<String> setOfRenewablePrograms_Virtual = new Set<String>{'YOUV - Virtual Tour'};
Set<String> setOfOneTimePrograms_Virtual = new Set<String>{'YOUVSS - Studio Services'};

Set<String> setOfOneTimeProducts_Virtual = new Set<String>{ 'FEE-Implementation_Fee', 'VTR-EAB_Team_Shoot_VidPlus','VTR-EAB_Team_Shoot','FEE-EAB_BoxPACK','FEE-AZ_PhotoVideo_Onsite','VTR-FTE_Employ_Shoot','VTR-Contrctor_Shoot_Mini','FEE-Vrtl_Tr_sutp_Fee' ,'VTR-Contrctor_Shoot_Full','VTR-Contnt_Lcnsng_OnTm_F','VTR-Drone_Still','VTR-Drone_Vid','VTR-Drone_Vid_Still'};

/*Map<String, String> mapOfVirtualOneTimeProducts = new Map<String, String>{
    'VTR-EAB_Team_Shoot_VidPlus' => 'YOUVSS - Studio Services',
    'VTR-EAB_Team_Shoot' => 'YOUVSS - Studio Services',
    'FEE-EAB_BoxPACK' => 'YOUVSS - Studio Services',
    'FEE-AZ_PhotoVideo_Onsite' => 'YOUVSS - Studio Services',
    'VTR-FTE_Employ_Shoot' => 'YOUVSS - Studio Services',
    'VTR-Contrctor_Shoot_Mini' => 'YOUVSS - Studio Services',
    'FEE-Vrtl_Tr_stup_Fee' => 'YOUVSS - Studio Services',
    'VTR-Contrctor_Shoot_Full' => 'YOUVSS - Studio Services',
    'VTR-Contnt_Lcnsng_OnTm_F' => 'YOUVSS - Studio Services',
    'VTR-Drone_Still' => 'YOUVSS - Studio Services',
    'VTR-Drone_Vid' => 'YOUVSS - Studio Services',
    'VTR-Drone_Vid_Still' => 'YOUVSS - Studio Services'
};*/


Boolean isOppSendToFinance = creditingOpp.StageName == sendToFinance;  
Boolean isInitiatingOpp =  creditingOpp.Type2__c == initiatingOpp;  
Boolean isContinuingOpp =  creditingOpp.Type2__c == continuingOpp;  
Boolean isAmendmentOpp =  creditingOpp.Type2__c == amendmentOpp;  
Boolean isRenewalOpp =  creditingOpp.Type2__c == renewalOpp || creditingOpp.SBQQ__RenewedContract__c != null;  
Boolean isDiscountProductUsed = false;
Boolean isLegacyAcquisitionOpp =  creditingOpp.Type2__c == legacyAcquisitionOpp;  


Set<String> setOfProgramsAcronyms = new Set<String>();  
Set<String> setOfProductCode = new Set<String>();  

List<Team_Membership__c> listOfUgPDE = [SELECT Staff_member__r.Name FROM Team_Membership__c 
                      WHERE Institution__c =: creditingOpp.AccountId
                      AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' 
                      AND Program_Perspectives__c = 'Undergrad Enrollment'
                      LIMIT 1];

//System.debug(listOfUgPDE);
List<SBQQ__QuoteLine__c> listOfQLs = new List<SBQQ__QuoteLine__c>();

if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == null || creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == 'Funds Appropriation Opt Out'){
    listOfQLs = [SELECT ID, Product_Code_Combination__c, Related_Product_with_Parent_Product__c, Related_Product_with_Parent_Product_Name__c, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c
    ORDER BY SBQQ__CustomerTotal__c ASC ];
} else {
    listOfQLs = [SELECT ID, Product_Code_Combination__c, Related_Product_with_Parent_Product__c, Related_Product_with_Parent_Product_Name__c, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c
    ORDER BY SBQQ__CustomerTotal__c ASC ];
}

String shadowCreditUser;
Boolean activeRyauMembership = false;
Decimal shadowNBB;
Decimal adamShadowNBB;

Date endDateOfContractToConsider = Date.today() < creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c ? Date.today().addYears(-1) : creditingOpp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c.addYears(-1);

List<Membership__c> ryauMembership = [SELECT ID, Program__r.Name, Membership_Status__c, Last_End_Date_2__c FROM Membership__c WHERE Program__r.Partner_360_Terrain__c = 'Enrollment Services' AND Membership_Status__c = 'Member - Payer' AND Last_End_Date_2__c > :endDateOfContractToConsider AND Account_Name__c = :creditingOpp.AccountId];
//System.debug('ryauMembership = ' + ryauMembership);

if (ryauMembership != null && ryauMembership.size() > 1){
    activeRyauMembership = true;
    System.debug('RYAU Membership considered');
    // System.debug('ryauMembership.Membership_Status__c = ' + ryauMembership.Membership_Status__c);
}
//System.debug('activeRyauMembership = ' + activeRyauMembership);

if(listOfUgPDE.size()>0 && ryauMembership != null && ryauMembership.size() > 1)
{
    shadowCreditUser = listOfUgPDE[0].Staff_member__r.Name;
    //System.debug('Ug PDE: ' + shadowCreditUser);
}



for(SBQQ__QuoteLine__c qle :listOfQLs){  
    String programAcronym = null;

    //System.debug('qle.SBQQ__ProductName__c = ' + qle.SBQQ__ProductName__c);     
   //System.debug('qle.SBQQ__Product__r.Program__r.Program_Acronym__c = ' + qle.SBQQ__Product__r.Program__r.Program_Acronym__c);     
    //System.debug('qle.SBQQ__ProductCode__c = ' + qle.SBQQ__ProductCode__c);


    mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c); 
    programAcronym = setOfOneTimeProducts_Virtual.contains(qle.SBQQ__ProductCode__c) ? 'YOUVSS - Studio Services' :  (qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c));
    
    //System.debug('mapOfProgramAndParentProductName = ' + mapOfProgramAndParentProductName);
    //System.debug('programAcronym = ' + programAcronym);

    if(qle.SBQQ__ProductCode__c == 'DISC-EAB_Invstmnt'){
        isDiscountProductUsed = true;
        
    }
    //System.debug('programAcronym used = ' + programAcronym);
     
    if(programAcronym != null && (programAcronym == 'YOUVSS - Studio Services' || programAcronym == 'Youv')){  
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
        if(mapOfProgramAndTotalCost.containsKey(programAcronym) && qle.SBQQ__ProductName__c != 'Administrative & Travel Fee') {                  
            mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + qle.SBQQ__CustomerTotal__c);  

        } else if (qle.SBQQ__ProductName__c != 'Administrative & Travel Fee') {  
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
    // System.debug('qle.SBQQ__ProductName__c = ' + qle.SBQQ__ProductName__c);
    // if(qle.SBQQ__ProductName__c == 'Implementation Fee' )
    // {
    //     System.debug('mapOfProgramAndImplementationFee = ' + mapOfProgramAndImplementationFee);
    //     System.debug('mapOfProgramAndParentProductName = ' + mapOfProgramAndParentProductName);
    //     System.debug('qle.Related_Product__c = ' + qle.Related_Product__c);
    //     if(mapOfProgramAndImplementationFee.containsKey(mapOfProgramAndParentProductName.get(qle.Related_Product__c)))
    //     {
    //         Decimal sumOfFee = mapOfProgramAndImplementationFee.get(mapOfProgramAndParentProductName.get(qle.Related_Product__c)) + qle.SBQQ__CustomerTotal__c;
    //         mapOfProgramAndImplementationFee.put(mapOfProgramAndParentProductName.get(qle.Related_Product__c) ,sumOfFee);
         
    //     } else {
    //         mapOfProgramAndImplementationFee.put( mapOfProgramAndParentProductName.get(qle.Related_Product__c) ,qle.SBQQ__CustomerTotal__c);
    //     }
    //     System.debug('mapOfProgramAndImplementationFee = ' + mapOfProgramAndImplementationFee);
    // }

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



Integer counter = 0;
for(String program : setOfProgramsAcronyms){
    Boolean upsellRBB = false;

        System.debug('setOfRenewalbleProgramsSoldInPast = ' + setOfRenewalbleProgramsSoldInPast);
        System.debug('setOfRenewalbleProgramsSoldInPast.contains(program) = ' + setOfRenewalbleProgramsSoldInPast.contains(program));
        System.debug('program = ' + program);
        System.debug('isInitiatingOpp = ' + isInitiatingOpp);
        System.debug('isThisARenewalForecasting = ' + isThisARenewalForecasting);
        System.debug('isParentOppBlank = ' + isParentOppBlank);
        System.debug('isParentOppContracted = ' + isParentOppContracted);
        System.debug('contractExist = ' + contractExist);
        System.debug('creditingOpp.SBQQ__AmendedContract__c = ' + creditingOpp.SBQQ__AmendedContract__c);
        System.debug('creditingOpp.Is_this_an_amend_and_restate_contract__c = ' + creditingOpp.Is_this_an_amend_and_restate_contract__c);

    if(mapOfProgramAndNBBAmount.get(program) > 0 && (program == 'Youv' || program == 'YOUVSS - Studio Services')){

        if(counter == 0){
        System.debug('\n');
        System.debug('=====================================================DEAL INFORMATION======================================================');
        System.debug(' Total Programs to credit : ' + setOfProgramsAcronyms.size());
        System.debug(' Set Of Programs to credit : ' + setOfProgramsAcronyms);
        System.debug(' Propsal Start Date : ' + mapOfProgramStartDate);
        System.debug(' Propsal End Date : ' + mapOfProgramEndDate);
        System.debug(' Cost of Program Without A&T : ' + mapOfProgramAndTotalCost);
        //   System.debug(' Admin And Travel Fee : ' + mapOfProgramAndAdminTravelFee);
        System.debug('===========================================================================================================================');
        counter =+1;
        }

        if( ( isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank ||  !isParentOppContracted) ) || isThisARenewalForecasting)  &&  !contractExist ) || !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')  ){
            System.debug('=======================================================New Sale============================================================');
        }
        else if(creditingOpp.SBQQ__AmendedContract__c != null  || creditingOpp.Is_this_an_amend_and_restate_contract__c  == 'Yes' || isOppRenewalUpsell){
            System.debug('================================================Upsell RBB=====================================================');
            upsellRBB = true;
            
        }
        else{
            identifiedAsRenewal = true;
            System.debug('================================================Renewal========================================================');
        }
    
        // System.debug(' mapOf Program And Parent Product Name (For A&T and Imp) = ' + mapOfProgramAndParentProductName); 
        
        Integer dayDiffrence = mapOfProgramStartDate.get(program).daysBetween(mapOfProgramEndDate.get(program));
        //System.debug(dayDiffrence);     
        //System.debug(program);    
        System.debug('--------------------------------------------------Program to Credit :'+program +' -------------------------------------------------'); 
        System.debug(' Program :' + program);
        System.debug(' Program Start Date :' + mapOfProgramStartDate.get(program)); 
        System.debug(' Program End Date :' + mapOfProgramEndDate.get(program)); 
        System.debug(' Total Program Cost :' + mapOfProgramAndTotalCost.get(program));
        System.debug(' Admin and Travel Fee :' + mapOfProgramAndAdminTravelFee.get(program));
        System.debug(' Implementation Fee :' + mapOfProgramAndImplementationFee.get(program));
        if(dayDiffrence <= 365 && program == 'YOUVSS - Studio Services'){
                  System.debug(' NBB Amount :' + mapOfProgramAndTotalCost.get(program).setScale(2));
                  shadowNBB = mapOfProgramAndTotalCost.get(program).setScale(2);
                  adamShadowNBB = 0 - shadowNBB;
         }
        else{
                  System.debug(' NBB Amount :' + mapOfProgramAndNBBAmount.get(program).setScale(2));
                  shadowNBB = mapOfProgramAndNBBAmount.get(program).setScale(2);
                  adamShadowNBB = 0 - shadowNBB;
        }
        Date atlBinderDate = Date.today() > mapOfProgramStartDate.get(program) ? Date.today() : mapOfProgramStartDate.get(program);
        System.debug(' Binder Date : '  + atlBinderDate);
        System.debug(' ATL Date : ' + atlBinderDate);
        System.debug(' Opp Owner : ' + creditingOpp.Owner.Name);

        if(shadowCreditUser != null)
        {
           System.debug('------------------------------------------------- 1st Shadow Record Details ----------------------------------------------------');
           System.debug(' Program :' + program);
           System.debug(' Credited User :'+ shadowCreditUser);
           System.debug(' NBB Amount :' + shadowNBB);
           System.debug(' NBB Type :'+ 'Shadow Credit');
           System.debug(' ATL Date :'+ atlBinderDate);
           System.debug(' Binder Date :'+ atlBinderDate);
           System.debug(' Deal Type :'+ 'New Sale');
   
           System.debug('------------------------------------------------- 2nd Shadow Record Details ----------------------------------------------------');
           System.debug(' Program :' + program);
           System.debug(' Credited User :'+ 'Adam Sutton');
           System.debug(' NBB Amount :' + adamShadowNBB);
           System.debug(' NBB Type :'+ 'Shadow Credit');
           System.debug(' ATL Date :'+  atlBinderDate);
           System.debug(' Binder Date :'+ atlBinderDate);
           System.debug(' Deal Type :'+ 'New Sale');
        }

        
        if(upsellRBB){
            System.debug(' Deal Type: Upsell');
        } else {
            System.debug(' Deal Type: New Sale');
        }
        System.debug(' NBB Type: Base Fee');
        System.debug('-----------------------------------------------------------------------------------------------------------------------------');
    }
    
    
}
System.debug('\n\n\n');
if(isDiscountProductUsed){
    System.debug('----------------------------------ALERT - Discount Product Used - NBB amount may differ ------------------------------------------'); 
} 
if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null){
    System.debug('----------------------------------ALERT - Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c + ' ---------------------------------------------'); 
}
if(creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null){
    System.debug('----------------------------------ALERT - Secondary Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c + ' ---------------------------------------------'); 
}
