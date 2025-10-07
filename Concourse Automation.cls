ID OppId = ''; 
Boolean tipsContract = false;

Opportunity creditingOpp = [SELECT ID, StageName, List_of_Product_Families__c,  Owner.Name, LOA_Contract__c, LOA_Contract__r.StartDate, LOA_Contract__r.EndDate,  SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c
FROM Opportunity
WHERE ID = :OppId LIMIT 1];

List<Team_Membership__c> listOfActiveTechPDE = [SELECT Staff_member__r.Name,Role__r.Name, Program_Perspectives__c, Role__r.Business_Line__c, Role__r.Department__c 
FROM Team_Membership__c Where Active_Institution__c = :creditingOpp.AccountId AND Role__r.Name = 'PDE (Exec)' AND Program_Perspectives__c IN ('2Yr Nav, Edify','2Yr Nav, Edify, SAS 2 Year','4Yr Nav, Edify, Pan-Tech','4Yr Nav, Pan-Tech','Edify','Edify, SAS 2 Year','Forage')];

// Set<String> setOfTechPDENames = new Set<String>();
// if(!listOfActiveTechPDE.isEmpty()){
//     for(Team_Membership__c techPde :listOfActiveTechPDE){
//         setOfTechPDENames.add(listOfActiveTechPDE.Staff_member__r.Name);
//     }
// }

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
Set<String> setOfNavigateProgram = new Set<String>{'BHAPR','BHDR','BHCO','BHLMS','BHCON','BHPRO','BHSE','HECGC','BHGCL','BHAP','BHAN','BHAI','BHAF'};
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
Boolean bothEdifyAndNavigateOpp = creditingOpp.List_of_Product_Families__c != null && creditingOpp.List_of_Product_Families__c.contains('Edify') && creditingOpp.List_of_Product_Families__c.contains('Navigate') ? true : false;
System.debug('bothEdifyAndNavigateOpp = ' + bothEdifyAndNavigateOpp);

Set<String> setOfProgramsAcronyms = new Set<String>();  
Set<String> setOfProductCode = new Set<String>();  

List<SBQQ__QuoteLine__c> listOfQLs = new List<SBQQ__QuoteLine__c>();
if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == null || creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c == 'Funds Appropriation Opt Out'){
    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product_with_Parent_Product__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c
    ORDER BY Related_Product__c ASC ];  
} else {
    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product_with_Parent_Product__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name FROM SBQQ__QuoteLine__c   
    WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :creditingOpp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c
    ORDER BY Related_Product__c ASC ];  
}

List<Team_Membership__c> listOfCcnPDE = [SELECT Staff_member__r.Name FROM Team_Membership__c 
                      WHERE Institution__c =: creditingOpp.AccountId
                      AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' 
                      AND (Program_Perspectives__c LIKE '%Domestic Match%' OR Program_Perspectives__c LIKE '%Global Match%')
                      LIMIT 1];


List<Team_Membership__c> listOfEnrollPDE= [SELECT Staff_member__r.Name FROM Team_Membership__c 
                      WHERE Institution__c =: creditingOpp.AccountId
                      AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' 
                      AND Program_Perspectives__c = 'Undergrad Enrollment'
                      LIMIT 1];

String CcnPDE;
String enrollPDE;
String creditUser;
String shadowCreditUser;

if(listOfCcnPDE.size()>0){
    CcnPDE = listOfCcnPDE[0].Staff_member__r.Name;
    System.debug('Concourse PDE: ' + CcnPDE);
}

if(listOfEnrollPDE.size()>0){
    enrollPDE = listOfEnrollPDE[0].Staff_member__r.Name;
    System.debug('Enroll PDE: ' + enrollPDE);
}

if(enrollPDE !=null && creditingOpp.Owner.Name == enrollPDE){
    creditUser = enrollPDE;
    shadowCreditUser = CcnPDE;
}else{
    creditUser = CcnPDE;
    shadowCreditUser = enrollPDE;
}/*else{
    creditUser = creditingOpp.Owner.Name;
}*/

for(SBQQ__QuoteLine__c qle :listOfQLs){  
    String programAcronym = null;
     
    //System.debug('---------------------------------------------------------');
    // System.debug('qle.SBQQ__ProductCode__c = ' + qle.SBQQ__ProductCode__c);
    //System.debug('qle.SBQQ__ProductName__c = ' + qle.SBQQ__ProductName__c);
    //System.debug('qle.SBQQ__Product__r.Program__r.Program_Acronym__c = ' + qle.SBQQ__Product__r.Program__r.Program_Acronym__c);

    //System.debug('qle.SBQQ__CustomerTotal__c = ' + qle.SBQQ__CustomerTotal__c);

    
    //System.debug('Program_Acronym__c = ' + qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
    mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c);  
    programAcronym = qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c);
	programAcronym = mapOfEdifyPrograms.containsKey(programAcronym) ? mapOfEdifyPrograms.get(programAcronym) : programAcronym;

    if(qle.SBQQ__ProductCode__c == 'DISC-EAB_Invstmnt'){
        isDiscountProductUsed = true;
        if(qle.Related_Product_with_Parent_Product__c == 'NAV-Nav_4_Year'){
            programAcronym = 'BHCO';
        }
    }
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
    // System.debug('qle.SBQQ__ProductName__c = ' + qle.SBQQ__ProductName__c);
    if(qle.SBQQ__ProductName__c == 'Implementation Fee'){
        if(mapOfProgramAndImplementationFee.containsKey(mapOfProgramAndParentProductName.get(qle.Related_Product__c))){
            Decimal sumOfFee = mapOfProgramAndImplementationFee.get(mapOfProgramAndParentProductName.get(qle.Related_Product__c)) + qle.SBQQ__CustomerTotal__c;
            mapOfProgramAndImplementationFee.put(mapOfProgramAndParentProductName.get(qle.Related_Product__c) ,sumOfFee);
        } else {
            mapOfProgramAndImplementationFee.put( mapOfProgramAndParentProductName.get(qle.Related_Product__c) ,qle.SBQQ__CustomerTotal__c);
        }
    }
    // System.debug('mapOfProgramAndImplementationFee = ' + mapOfProgramAndImplementationFee);

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

// if(program == 'BHAI'){
//  System.debug('Program => ' + program);
//  System.debug('totalDays = ' + totalDays);
//  System.debug('adminAndTravelFee = ' + adminAndTravelFee);
//  System.debug('implementationFee = ' + implementationFee);
//  System.debug('cost of program without a&t = ' + mapOfProgramAndTotalCost.get(program));
//  System.debug('nbbAmount = ' + nbbAmount);

// }

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

//System.debug('listOfQLsAssociatedToContracts = ' + listOfQLsAssociatedToContracts);
//System.debug('isInitiatingOpp = ' + isInitiatingOpp);
//System.debug('isThisARenewalForecasting = ' + isThisARenewalForecasting);
//System.debug('isParentOppBlank = ' + isParentOppBlank );
//System.debug('isParentOppContracted = ' + isParentOppContracted);
//System.debug('contractExist = ' + contractExist);
//System.debug('creditingOpp.SBQQ__AmendedContract__c = ' + creditingOpp.SBQQ__AmendedContract__c);
//System.debug('creditingOpp.Is_this_an_amend_and_restate_contract__c = ' + creditingOpp.Is_this_an_amend_and_restate_contract__c);



for(String program : setOfProgramsAcronyms){
    Boolean upsellRBB = false;
    if(mapOfProgramAndNBBAmount.get(program) > 0){
        System.debug('\n\n\n');
        
        if( ( !setOfRenewalbleProgramsSoldInPast.isEmpty() && !setOfRenewalbleProgramsSoldInPast.contains(program) ) || isInitiatingOpp && (( !isThisARenewalForecasting && (isParentOppBlank ||  !isParentOppContracted) ) || isThisARenewalForecasting)  &&  !contractExist && !(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes')  ){
            System.debug('----------------------------------New Sale-------------------------------------------');
        }
        else if(creditingOpp.SBQQ__AmendedContract__c != null  || creditingOpp.Is_this_an_amend_and_restate_contract__c  == 'Yes' || isOppRenewalUpsell){
            System.debug('----------------------------------Upsell RBB------------------------------------------');
            upsellRBB = true;
            
        }
        else{
            identifiedAsRenewal = true;
            System.debug('----------------------------------Renewal----------------------------------------------');
        }
    
        // System.debug(' mapOf Program And Parent Product Name (For A&T and Imp) = ' + mapOfProgramAndParentProductName); 
        if(bothEdifyAndNavigateOpp && setOfNavigateProgram.contains(program)){
            System.debug('----------------------------------ALERT: Both Edify and Navigate Present on the Opp----------------------------------');
            System.debug(' Comment by Alex: The Edify NBB will be credited to Matthew Ingram (the opportunity owner), but for the Navigate NBB, we should split the NBB credit evenly (50/50) between Matthew Ingram and Dustin Ott.');
        }
        System.debug('---------------------------- Deal Information ----------------------------');
        System.debug(' Program Start Date = ' + mapOfProgramStartDate.get(program)); 
        System.debug(' Program End Date = ' + mapOfProgramEndDate.get(program)); 
        System.debug(' Total Program Cost =>' + mapOfProgramAndTotalCost.get(program));
        System.debug(' Admin and Travel Fee =>' + mapOfProgramAndAdminTravelFee.get(program));
        System.debug(' Implementation Fee =>' + mapOfProgramAndImplementationFee.get(program));

        System.debug('----------------------------------NBB Details:' + program + '-------------------------------------------'); 
        System.debug(' Credited User: ' + creditUser);  
        System.debug(' Program: ' + program);
        System.debug(' NBB Amount: ' + mapOfProgramAndNBBAmount.get(program).setScale(2));
        System.debug(' NBB Type: Base Fee');
        
        if(bothEdifyAndNavigateOpp && setOfNavigateProgram.contains(program)){
            System.debug(' NBB Amount Split => ' + mapOfProgramAndNBBAmount.get(program).setScale(2)/2);
        }
        
        if(bothEdifyAndNavigateOpp && setOfNavigateProgram.contains(program)){
            System.debug(' Credit to 2 people Matthew Ingram and Dustin Ott');
        }

        if(program == 'BHTF'){
            System.debug(' Transfer Portal --> Create Shadow credits if Opp Owner is not Transfer Portal PDE');
        }
        
        if(upsellRBB){
            System.debug(' Deal Type: Upsell');
        } else {
            System.debug(' Deal Type: New Sale');
        }

        Date atlBinderDate = Date.today() > mapOfProgramStartDate.get(program) ? Date.today() : mapOfProgramStartDate.get(program);
        System.debug(' Binder Date: '  + atlBinderDate);
        System.debug(' ATL Date: ' + atlBinderDate);

        if(shadowCreditUser != null){
            System.debug('------------------------------------ 1st Shadow Record Details ------------------------------------');
            System.debug(' Program => ' + program);
            System.debug(' Credited User => '+ shadowCreditUser);
            System.debug(' NBB Amount => ' + mapOfProgramAndNBBAmount.get(program).setScale(2));
            System.debug(' NBB Type => '+ 'Shadow Credit');
            System.debug(' ATL Date => '+ atlBinderDate);
            System.debug(' Binder Date => '+ atlBinderDate);
            System.debug(' Deal Type => '+ 'New Sale');

            System.debug('------------------------------------ 2nd Shadow Record Details ------------------------------------');
            System.debug(' Program => ' + program);
            System.debug(' Credited User => '+ 'Adam Sutton');
            System.debug(' NBB Amount => -' + mapOfProgramAndNBBAmount.get(program).setScale(2));
            System.debug(' NBB Type => '+ 'Shadow Credit');
            System.debug(' ATL Date => '+ atlBinderDate);
            System.debug(' Binder Date => '+ atlBinderDate);
            System.debug(' Deal Type => '+ 'New Sale');
        }
    }
        
}
System.debug('\n\n\n');
if(isDiscountProductUsed){
    System.debug('----------------------------------ALERT - Discount Product Used - NBB amount may differ ------------------------------------------'); 
}
System.debug('---------------------------------------------------------------------------------------------'); 
if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null){
    System.debug('----------------------------------ALERT - Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c + ' ---------------------------------------------'); 
}
if(creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null){
    System.debug('----------------------------------ALERT - Secondary Opt Out: ' + creditingOpp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c + ' ---------------------------------------------'); 
}
