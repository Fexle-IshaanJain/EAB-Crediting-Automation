//Research NBB + RBB

ID OppId = ''; 
Boolean tipsContract = false;

Opportunity creditingOpp = [SELECT ID, StageName, List_of_Product_Families__c,  Owner.Name, LOA_Contract__c, LOA_Contract__r.StartDate, LOA_Contract__r.EndDate,  SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c,
    Parent_Opportunity__c, Parent_Opportunity__r.LOA_Contract__c, Parent_Opportunity__r.SBQQ__RenewedContract__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c, SBQQ__PrimaryQuote__r.Penalty_Fee_Amount__c, SBQQ__PrimaryQuote__r.Opt_Out_Penalty_Amount__c
FROM Opportunity
WHERE ID = :OppId LIMIT 1];

String sendToFinance = 'Contract Received - Send to Finance';  
String initiatingOpp = 'Initiating';  
String continuingOpp = 'Continuing'; 
String amendmentOpp = 'Amendment';  
String renewalOpp = 'Renewal';  
String legacyAcquisitionOpp = 'Legacy Acquisition';  

Id renewedContractID;
Boolean isOppRenewalUpsell = false;
Boolean identifiedAsRenewal = false;
Boolean penaltyFeeApplied = false;
Boolean customResearchProductExist = false;
Set<String> setOfRenewalbleProgramsSoldInPast = new Set<String>();
Map<String,Id> mapOfProgramAndPreviousContractId = new Map<String,Id>();  
Map<String,Date> mapOfProgramStartDate = new Map<String,Date>();  
Map<String,Date> mapOfProgramEndDate = new Map<String,Date>();  
Map<String,Decimal> mapOfProgramAndTotalCost = new Map<String,Decimal>();  
Map<String, Decimal> mapOfProgramAndNBBAmount = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndImplementationFee = new Map<String, Decimal>();  
Map<String, Decimal> mapOfProgramAndAdminTravelFee = new Map<String, Decimal>();  
Map<String, String> mapOfProgramAndParentProductName = new Map<String, String>();

Map<Decimal,Date> mapOfGroupNumberAndStartDate = new Map<Decimal,Date>();
Map<Decimal,Date> mapOfGroupNumberAndEndDate = new Map<Decimal,Date>();
// Map to store total cost per program per group (key format: "programAcronym-GroupNumber")
Map<String,Decimal> mapOfProgramAndGroupTotalCost = new Map<String,Decimal>();
// Map to store CreditAmount per program (key: programAcronym)
// CreditAmount is calculated based on Floor Rule for high price escalation cases
// Uses 1st group data to determine the CreditAmount for the entire program
Map<String,Decimal> mapOfProgramRBBCreditAmount = new Map<String,Decimal>();

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
    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product_with_Parent_Product__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, Group_Number__c,
        SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name 
        FROM SBQQ__QuoteLine__c   
        WHERE SBQQ__Quote__c = :creditingOpp.SBQQ__PrimaryQuote__c
        ORDER BY Related_Product__c ASC ];  
} else {
    listOfQLs = [SELECT ID, Previous_Year_Quantity__c, SBQQ__ProductName__c, Related_Product_with_Parent_Product__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, Group_Number__c,
        SBQQ__CustomerTotal__c, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Family, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name 
        FROM SBQQ__QuoteLine__c   
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

    //System.debug('Program_Acronym__c = ' + qle.SBQQ__Product__r.Program__r.Program_Acronym__c);
    mapOfProgramAndParentProductName.put(qle.SBQQ__ProductName__c, qle.SBQQ__Product__r.Program__r.Program_Acronym__c);  
    programAcronym = qle.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? qle.SBQQ__Product__r.Program__r.Program_Acronym__c : mapOfProgramAndParentProductName.get(qle.Related_Product__c);
	// programAcronym = mapOfEdifyPrograms.containsKey(programAcronym) ? mapOfEdifyPrograms.get(programAcronym) : programAcronym;

    if(qle.SBQQ__ProductCode__c == 'DISC-EAB_Invstmnt'){
        isDiscountProductUsed = true;
        if(qle.Related_Product_with_Parent_Product__c == 'NAV-Nav_4_Year'){
            programAcronym = 'BHCO';
        }
    }
    //System.debug('programAcronym used = ' + programAcronym);

    if(qle.SBQQ__ProductCode__c == 'RES-CUST_RES'){
        customResearchProductExist = true;
    }

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
        
        // Populate Group Number maps
        if(qle.Group_Number__c != null && !mapOfGroupNumberAndStartDate.containsKey(qle.Group_Number__c)){
            mapOfGroupNumberAndStartDate.put(qle.Group_Number__c, qle.SBQQ__StartDate__c);
            mapOfGroupNumberAndEndDate.put(qle.Group_Number__c, qle.SBQQ__EndDate__c);
        }
        
        //System.debug('mapOfProgramAndTotalCost.containsKey(programAcronym) = ' + mapOfProgramAndTotalCost.containsKey(programAcronym));
        if(mapOfProgramAndTotalCost.containsKey(programAcronym) && qle.SBQQ__ProductName__c != 'Administrative & Travel Fee' && qle.SBQQ__ProductName__c != 'Implementation Fee') {                  
            mapOfProgramAndTotalCost.put(programAcronym, mapOfProgramAndTotalCost.get(programAcronym) + qle.SBQQ__CustomerTotal__c);
        } else if (qle.SBQQ__ProductName__c != 'Administrative & Travel Fee' && qle.SBQQ__ProductName__c != 'Implementation Fee'){ 
            mapOfProgramAndTotalCost.put(programAcronym, qle.SBQQ__CustomerTotal__c);
        }
        
        // Calculate total cost per program per group (excluding Admin & Travel Fee and Implementation Fee)
        if(qle.Group_Number__c != null && qle.SBQQ__ProductName__c != 'Administrative & Travel Fee' && qle.SBQQ__ProductName__c != 'Implementation Fee'){
            String programGroupKey = programAcronym + '-' + String.valueOf(qle.Group_Number__c);
            if(mapOfProgramAndGroupTotalCost.containsKey(programGroupKey)){
                mapOfProgramAndGroupTotalCost.put(programGroupKey, mapOfProgramAndGroupTotalCost.get(programGroupKey) + qle.SBQQ__CustomerTotal__c);
            } else {
                mapOfProgramAndGroupTotalCost.put(programGroupKey, qle.SBQQ__CustomerTotal__c);
            }
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
            Decimal sumOfFee = mapOfProgramAndAdminTravelFee.get(mapOfProgramAndParentProductName.get(qle.Related_Product__c)) + qle.SBQQ__CustomerTotal__c;
            mapOfProgramAndAdminTravelFee.put(mapOfProgramAndParentProductName.get(qle.Related_Product__c), sumOfFee);
        } else {
            mapOfProgramAndAdminTravelFee.put(mapOfProgramAndParentProductName.get(qle.Related_Product__c), qle.SBQQ__CustomerTotal__c);
        }
    }
    // System.debug('qle.SBQQ__ProductName__c = ' + qle.SBQQ__ProductName__c);
    if(qle.SBQQ__ProductName__c == 'Implementation Fee'){
        if(mapOfProgramAndImplementationFee.containsKey(mapOfProgramAndParentProductName.get(qle.Related_Product__c))){
            Decimal sumOfFee = mapOfProgramAndImplementationFee.get(mapOfProgramAndParentProductName.get(qle.Related_Product__c)) + qle.SBQQ__CustomerTotal__c;
            mapOfProgramAndImplementationFee.put(mapOfProgramAndParentProductName.get(qle.Related_Product__c), sumOfFee);
        } else {
            mapOfProgramAndImplementationFee.put(mapOfProgramAndParentProductName.get(qle.Related_Product__c), qle.SBQQ__CustomerTotal__c);
        }
    }
    // System.debug('mapOfProgramAndImplementationFee = ' + mapOfProgramAndImplementationFee);

}
for(String program : setOfProgramsAcronyms){
        Integer totalDays = mapOfProgramStartDate.get(program).daysBetween(mapOfProgramEndDate.get(program)) + 1;
    Decimal adminAndTravelFee = mapOfProgramAndAdminTravelFee.containsKey(program) ? mapOfProgramAndAdminTravelFee.get(program) : 0;
    Decimal implementationFee = mapOfProgramAndImplementationFee.containsKey(program) ? mapOfProgramAndImplementationFee.get(program) : 0;
    Decimal totalProgramCost = mapOfProgramAndTotalCost.get(program) + adminAndTravelFee;
    Decimal nbbAmount = ((totalProgramCost/totalDays)*365) + implementationFee;

    if(creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c != null && creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out__c.contains('With Stated Penalty Fee')){
        penaltyFeeApplied = true;
        nbbAmount += creditingOpp.SBQQ__PrimaryQuote__r.Opt_Out_Penalty_Amount__c*0.25;
    }

    if(tipsContract){
        nbbAmount = nbbAmount * 0.99;
    }

    mapOfProgramAndNBBAmount.put(program, nbbAmount.setScale(2));
} 

// ============================================================================================================
// CREDIT AMOUNT CALCULATION - FLOOR RULE IMPLEMENTATION
// ============================================================================================================
// This section calculates CreditAmount for each program-group combination based on Floor Rule.
// Floor Rule applies primarily to high price escalation cases (<10% of contracts).
// Contracts with high price escalations must be discussed before crediting.
// 
// Floor Rule Logic:
// - Floor Amount = 50% of last year's dollars (last group in current contract for the program)
// - CreditAmount calculation varies based on whether 1st group is Gratis, Prorated, or both
// ============================================================================================================

// Process each program-group combination to calculate CreditAmount
// Group numbers directly indicate order: Group 1 = 1st group, Group 2 = 2nd group, etc.
Map<String, Map<Integer, Decimal>> programToGroupCosts = new Map<String, Map<Integer, Decimal>>();
Map<String, Integer> programToMaxGroupNumber = new Map<String, Integer>();

// First pass: Organize data by program and find the highest group number (last group) for each program
for(String programGroupKey : mapOfProgramAndGroupTotalCost.keySet()){
    // Key format: "programAcronym-GroupNumber"
    Integer dashIndex = programGroupKey.indexOf('-');
    if(dashIndex > 0){
        String program = programGroupKey.substring(0, dashIndex);
        String groupNumberStr = programGroupKey.substring(dashIndex + 1);
        Decimal groupNumber = Decimal.valueOf(groupNumberStr);
        
        if(!programToGroupCosts.containsKey(program)){
            programToGroupCosts.put(program, new Map<Integer, Decimal>());
        }
        programToGroupCosts.get(program).put(groupNumber.intValue(), mapOfProgramAndGroupTotalCost.get(programGroupKey));
        
        // Track the highest group number (last group) for floor calculation
        Integer groupNumberInt = groupNumber.intValue();
        if(!programToMaxGroupNumber.containsKey(program) || groupNumberInt > programToMaxGroupNumber.get(program)){
            programToMaxGroupNumber.put(program, groupNumberInt);
        }
    }
}

// Second pass: Calculate CreditAmount for each program (using 1st group data)
for(String program : programToGroupCosts.keySet()){
    Map<Integer, Decimal> groupCosts = programToGroupCosts.get(program);
    Integer maxGroupNumber = programToMaxGroupNumber.get(program);
    
    // Calculate Floor Amount = 50% of last year's dollars (last group = highest group number)
    Decimal floorAmount = 0;
    if(maxGroupNumber != null && groupCosts.containsKey(maxGroupNumber)){
        Decimal lastYearDollars = groupCosts.get(maxGroupNumber);
        if(lastYearDollars != null && lastYearDollars > 0){
            floorAmount = lastYearDollars * 0.50;
        }
    }
    
    // Calculate CreditAmount for the program using 1st group data
    // Only process group 1 to determine CreditAmount for the entire program
    if(groupCosts.containsKey(1)){
        Decimal firstGroupTotalCost = groupCosts.get(1);
        
        // Get 1st group dates (group number is Decimal)
        Decimal groupNumberDecimal = 1;
        Date groupStartDate = mapOfGroupNumberAndStartDate.get(groupNumberDecimal);
        Date groupEndDate = mapOfGroupNumberAndEndDate.get(groupNumberDecimal);
        
        if(groupStartDate != null && groupEndDate != null){
            // Determine if 1st group is Gratis (zero dollar customer total)
            Boolean isGratis = (firstGroupTotalCost == null || firstGroupTotalCost == 0);
            
            // Determine if 1st group is Prorated (less than a full year)
            Integer groupDays = groupStartDate.daysBetween(groupEndDate) + 1;
            Boolean isProrated = (groupDays < 365);
            
            // Calculate CreditAmount based on Floor Rule
            Decimal creditAmount = 0;
            
            // If 1st year is neither Gratis nor Prorated
            if(!isGratis && !isProrated){
                creditAmount = Math.max(firstGroupTotalCost, floorAmount);
            }
            // If 1st year is Gratis OR both Gratis and Prorated
            else if(isGratis || (isGratis && isProrated)){
                creditAmount = floorAmount;
            }
            // If 1st group is Prorated (but not Gratis)
            else if(isProrated && !isGratis){
                // Annualize the amount for the prorated period
                Decimal annualizedAmount = (firstGroupTotalCost / groupDays) * 365;
                
                // Compare annualized amount with Floor Amount
                if(annualizedAmount > floorAmount){
                    // Check if there's a 2nd group (group number = 2) to compare with
                    Decimal secondYearDollars = null;
                    if(groupCosts.containsKey(2)){
                        secondYearDollars = groupCosts.get(2);
                    }
                    
                    // If Annualized First Year's dollars > Second Year's Dollars
                    if(secondYearDollars != null && annualizedAmount > secondYearDollars){
                        creditAmount = secondYearDollars;
                    }
                    // If Annualized First Year's dollars < Second Year's Dollars
                    else if(secondYearDollars != null && annualizedAmount < secondYearDollars){
                        creditAmount = annualizedAmount;
                    }
                    // If no 2nd group, use annualized amount
                    else if(secondYearDollars == null){
                        creditAmount = annualizedAmount;
                    }
                }
                // If Annualized First Year's dollars < Floor Amount
                else {
                    creditAmount = floorAmount;
                }
            }
            
            // Store the calculated CreditAmount for the program
            mapOfProgramRBBCreditAmount.put(program, creditAmount.setScale(2));
        }
    }
}

Boolean isThisARenewalForecasting = creditingOpp.IsFcstRenewal__c == 'Yes';  
Boolean isParentOppBlank = creditingOpp.Parent_Opportunity__c == null;  
Boolean isParentOppContracted = creditingOpp.Parent_Opportunity__c != null ? (creditingOpp.Parent_Opportunity__r.SBQQ__Ordered__c || creditingOpp.Parent_Opportunity__r.SBQQ__Contracted__c) : false;  
Boolean contractExist = false;
//For doing new crediting
List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND StartDate < :Date.today().addYears(-1) AND EndDate > :Date.today().addYears(-1) AND ID != :creditingOpp.LOA_Contract__c]; 

//For checking old Crediting
//List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :creditingOpp.AccountId AND StartDate < :creditingOpp.LOA_Contract__r.StartDate.addYears(-1) AND EndDate > :creditingOpp.LOA_Contract__r.StartDate.addYears(-1) AND ID != :creditingOpp.LOA_Contract__c];

List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__c, SBQQ__Product__r.Program__r.Program_Acronym__c, SBQQ__Product__r.Program__r.Name, SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__r.EndDate
FROM SBQQ__QuoteLine__c
WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true ) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c = :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c = :listOfContractOnAccount)   
AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :setOfProgramsAcronyms)];
contractExist = listOfQLsAssociatedToContracts.size() > 0;

if(!listOfQLsAssociatedToContracts.isEmpty() && listOfQLsAssociatedToContracts.size() > 0){
    for(SBQQ__QuoteLine__c qle :listOfQLsAssociatedToContracts){
        setOfRenewalbleProgramsSoldInPast.add(qle.SBQQ__Product__r.Program__r.Program_Acronym__c);

        if(qle.SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__r.EndDate < mapOfProgramStartDate.get(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
            if(!mapOfProgramAndPreviousContractId.containsKey(qle.SBQQ__Product__r.Program__r.Program_Acronym__c)){
                mapOfProgramAndPreviousContractId.put(qle.SBQQ__Product__r.Program__r.Program_Acronym__c, qle.SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c);
            } else {
                // Note: This comparison needs to query the contract end date to properly compare
                // For now, keeping the existing contract ID
                mapOfProgramAndPreviousContractId.put(qle.SBQQ__Product__r.Program__r.Program_Acronym__c, qle.SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c);
            }
        }
    }
}

//Use cases to get NNLOA SP - Renewed Contract on Crediting Opp, Renewed Contract on Parent Opportunity, LOA Contract on Parent Opportunity, Latest contract ending
if(creditingOpp.SBQQ__RenewedContract__c != null){
    renewedContractID = creditingOpp.SBQQ__RenewedContract__c;
} else if(creditingOpp.Parent_Opportunity__r.SBQQ__RenewedContract__c != null){
    renewedContractID = creditingOpp.Parent_Opportunity__r.SBQQ__RenewedContract__c;
} else if(creditingOpp.Parent_Opportunity__r.LOA_Contract__c != null){
    renewedContractID = creditingOpp.Parent_Opportunity__r.LOA_Contract__c;
}

List<Subscription_Period__c> listOfNeedNewLoaSpsOfRenewedContract = [SELECT ID, Decision_Type__c FROM Subscription_Period__c Where Decision_Type__c = 'Need New LOA' AND (Contract__c = :renewedContractID OR Contract__c IN :mapOfProgramAndPreviousContractId.values())];

System.debug('renewedContractID = ' + renewedContractID);
System.debug('mapOfProgramAndPreviousContractId = ' + mapOfProgramAndPreviousContractId);
System.debug('listOfNeedNewLoaSpsOfRenewedContract = ' + listOfNeedNewLoaSpsOfRenewedContract);
Boolean needNewLoaSpFound = false;
if(!listOfNeedNewLoaSpsOfRenewedContract.isEmpty() && listOfNeedNewLoaSpsOfRenewedContract.size() == 1){
    needNewLoaSpFound = true;
    System.debug('Found 1 Need New LOA SP');
} else if(listOfNeedNewLoaSpsOfRenewedContract.size() > 1){
    for(Subscription_Period__c nnloaSp: listOfNeedNewLoaSpsOfRenewedContract){
    }
}

Boolean listOfNeedNewLoaSpFound = false;
if(!mapOfProgramAndPreviousContractId.isEmpty() && mapOfProgramAndPreviousContractId.size() > 1){
    listOfNeedNewLoaSpFound = true;
    System.debug('Found Multiple Need New LOA SP');
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
        else if(creditingOpp.SBQQ__AmendedContract__c != null || creditingOpp.Is_this_an_amend_and_restate_contract__c == 'Yes' || isOppRenewalUpsell){
            System.debug('----------------------------------Upsell RBB------------------------------------------');
            upsellRBB = true;
        }
        else{
            identifiedAsRenewal = true;
            System.debug('----------------------------------Renewal----------------------------------------------');
        }
        System.debug('---------------------------- Deal Information ----------------------------');
        System.debug(' Program Start Date = ' + mapOfProgramStartDate.get(program)); 
        System.debug(' Program End Date = ' + mapOfProgramEndDate.get(program)); 
        System.debug(' Total Program Cost =>' + mapOfProgramAndTotalCost.get(program));
        System.debug(' Admin and Travel Fee =>' + mapOfProgramAndAdminTravelFee.get(program));
        System.debug(' Implementation Fee =>' + mapOfProgramAndImplementationFee.get(program));

        if(identifiedAsRenewal){
            System.debug('----------------------------------RBB Details:' + program + '-------------------------------------------'); 
            if(needNewLoaSpFound){
                System.debug(' Need New LOA SP : ' + listOfNeedNewLoaSpsOfRenewedContract[0].Id);
            } else if (listOfNeedNewLoaSpFound){
                System.debug(' Previous Contract of the Program : ' + mapOfProgramAndPreviousContractId.get(program));
            }
        }else{
            System.debug('----------------------------------NBB Details:' + program + '-------------------------------------------'); 
        }
        System.debug(' Credited User: ' + creditingOpp.Owner.Name);
        System.debug(' Program: ' + program);
        if(identifiedAsRenewal){
            System.debug(' NBB Amount: ' + mapOfProgramRBBCreditAmount.get(program));
        }
        else if(penaltyFeeApplied == true){
            System.debug(' NBB Amount: ' + mapOfProgramAndNBBAmount.get(program).setScale(2)+ '(25% of penalty fee is applied)');  
        }else{
            System.debug(' NBB Amount: ' + mapOfProgramAndNBBAmount.get(program).setScale(2));
        }
        System.debug(' NBB Type: Base Fee');

        if(upsellRBB){
            System.debug(' Deal Type: Upsell');
        } else if(identifiedAsRenewal){
            System.debug(' Deal Type: Renewal');
        } else {
            System.debug(' Deal Type: New Sale');
        }

        Date atlBinderDate; /*= Date.today() > mapOfProgramStartDate.get(program) ? Date.today() : mapOfProgramStartDate.get(program);*/
        if(date.today().month() == mapOfProgramStartDate.get(program).month()){
        atlBinderDate = date.today();
        }else{
            atlBinderDate = Date.newInstance(mapOfProgramStartDate.get(program).year(), mapOfProgramStartDate.get(program).month(), 1);
        }
        System.debug(' Binder Date: '  + atlBinderDate);
        System.debug(' ATL Date: ' + atlBinderDate);
        System.debug(' Sales Segment: If Institute has another active Research Contract, then "CS", else "none"');
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
if(customResearchProductExist){
    System.debug('----------------------------------ALERT - Custom Research Product Exist - Discuss the Crediting with Onshore Team ---------------------------------------------');
}
