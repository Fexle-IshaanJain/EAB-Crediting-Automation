ID OppId = '006Pr00000JHCUtIAP';
Boolean tipsContract = false;
try {
    Opportunity opp = [SELECT ID, Name, StageName, OwnerId, Owner.Name, List_of_Product_Families__c, LOA_Contract__c, LOA_Contract__r.StartDate, LOA_Contract__r.EndDate, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, Is_this_an_amend_and_restate_contract__c, Type2__c, IsFcstRenewal__c, Parent_Opportunity__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.SBQQ__Contracted__c, Parent_Opportunity__r.SBQQ__Ordered__c, AccountId, Account.Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c, SBQQ__PrimaryQuote__r.SBQQ__EndDate__c, SBQQ__PrimaryQuote__r.Opt_Out__c, SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c, SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c FROM Opportunity WHERE ID = :OppId LIMIT 1];
    Boolean ownerIsUser = String.valueOf(opp.OwnerId).startsWith('005');
    User ownerUser = null;
    if (ownerIsUser) {
        List<User> ownerUsers = [SELECT ID, Name, Title, UserRole.Name FROM User WHERE ID = :opp.OwnerId LIMIT 1];
        if (ownerUsers.size() > 0) ownerUser = ownerUsers[0];
    }
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('              OPPORTUNITY INFORMATION');
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('  ID:          ' + opp.ID);
    System.debug('  Name:        ' + opp.Name);
    System.debug('  Owner:       ' + opp.Owner.Name);
    if (ownerUser != null) {
        System.debug('  Owner Title: ' + (ownerUser.Title != null ? ownerUser.Title : 'N/A'));
        System.debug('  Owner Role:  ' + (ownerUser.UserRole != null && ownerUser.UserRole.Name != null ? ownerUser.UserRole.Name : 'N/A'));
    }
    System.debug('  Stage:       ' + opp.StageName);
    System.debug('  Type2:       ' + opp.Type2__c);
    System.debug('  Parent Opp:  ' + opp.Parent_Opportunity__c);
    Boolean isParentBlank = opp.Parent_Opportunity__c == null;
    Boolean isRenewal = opp.Type2__c == 'Renewal' || opp.SBQQ__RenewedContract__c != null || opp.IsFcstRenewal__c == 'Yes';
    Boolean isAmendment = opp.Type2__c == 'Amendment' || opp.SBQQ__AmendedContract__c != null || opp.Is_this_an_amend_and_restate_contract__c == 'Yes';
    Boolean ownerIsPDE = ownerIsUser && ownerUser != null && (opp.Owner.Name.contains('PDE') || opp.Owner.Name.containsIgnoreCase('PDE') || (ownerUser.Title != null && (ownerUser.Title.containsIgnoreCase('PDE') || ownerUser.Title.containsIgnoreCase('Partner Development'))));
    Boolean ownerIsSL = false;
    if (ownerIsUser && ownerUser != null) {
        if (ownerIsPDE) {
            ownerIsSL = false;
        } else {
            ownerIsSL = (opp.Owner.Name.contains('SL') || opp.Owner.Name.contains('Sales Leader') || opp.Owner.Name.containsIgnoreCase('SL') || (ownerUser.Title != null && (ownerUser.Title.containsIgnoreCase('Sales Leader') || ownerUser.Title.containsIgnoreCase('SL'))));
            if (!ownerIsSL) {
                ownerIsSL = true;
            }
        }
    }
    Boolean hasPrevContracted = false;
    if (opp.Parent_Opportunity__c != null) {
        hasPrevContracted = opp.Parent_Opportunity__r.SBQQ__Contracted__c || opp.Parent_Opportunity__r.SBQQ__Ordered__c;
    }
    Date endDateCheck = Date.today() < opp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c ? Date.today().addYears(-1) : opp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c.addYears(-1);
    List<Contract> prevContracts = [SELECT ID FROM Contract WHERE AccountId = :opp.AccountId AND StartDate < :endDateCheck AND EndDate > :endDateCheck AND ID != :opp.LOA_Contract__c];
    Boolean hasPrevOpp = prevContracts.size() > 0 || hasPrevContracted;
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('           IDENTIFICATION LOGIC EVALUATION');
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('  Parent Opp Blank:     ' + isParentBlank);
    System.debug('  Is This Renewal:      ' + isRenewal);
    System.debug('  Is This Amendment:    ' + isAmendment);
    System.debug('  Owner Is PDE:         ' + ownerIsPDE);
    System.debug('  Owner Is SL:          ' + ownerIsSL);
    System.debug('  Owner Is User:        ' + ownerIsUser);
    System.debug('  Owner User Object:    ' + (ownerUser != null ? 'Found' : 'Not Found'));
    System.debug('  Has Previous Opp:     ' + hasPrevOpp);
    Boolean isThisARenewalForecasting = opp.IsFcstRenewal__c == 'Yes';
    Boolean isNBB = false;
    Boolean isRBB = false;
    // Initial NBB/RBB identification (will be re-evaluated after contractExist is calculated)
    if ((isParentBlank && !isRenewal && !isAmendment && ownerIsPDE && !hasPrevOpp) || ((isAmendment || opp.SBQQ__AmendedContract__c != null) && ownerIsSL)) {
        isNBB = true;
    }
    if ((opp.Parent_Opportunity__c != null || isRenewal || isAmendment) && ownerIsSL && hasPrevOpp) {
        isRBB = true;
    }
    if (!isNBB && !isRBB) {
        System.debug('  WARNING: Could not identify as NBB or RBB based on criteria');
        System.debug('  Analysis:');
        if (!ownerIsPDE && !ownerIsSL) {
            System.debug('    - Owner is neither PDE nor SL (Owner: ' + opp.Owner.Name + ')');
            if (ownerUser != null && ownerUser.Title != null) {
                System.debug('    - Owner Title: ' + ownerUser.Title);
            }
        }
        if (isRenewal && !ownerIsSL) {
            System.debug('    - Is Renewal but Owner is not SL');
        }
        if (hasPrevOpp && !ownerIsSL) {
            System.debug('    - Has Previous Opp but Owner is not SL');
        }
        System.debug('  Note: If owner is not PDE, they may be considered SL by default');
    }
    List<SBQQ__QuoteLine__c> qls = new List<SBQQ__QuoteLine__c>();
    if (opp.SBQQ__PrimaryQuote__r.Opt_Out__c == null || opp.SBQQ__PrimaryQuote__r.Opt_Out__c == 'Funds Appropriation Opt Out') {
        qls = [SELECT ID, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__r.Program_Acronym__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :opp.SBQQ__PrimaryQuote__c ORDER BY SBQQ__CustomerTotal__c ASC];
    } else {
        qls = [SELECT ID, SBQQ__ProductName__c, Related_Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__CustomerTotal__c, SBQQ__ProductCode__c, SBQQ__Product__r.Program__r.Program_Acronym__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :opp.SBQQ__PrimaryQuote__c AND SBQQ__EndDate__c <= :opp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c ORDER BY SBQQ__CustomerTotal__c ASC];
    }
    Set<String> oneTimeProducts = new Set<String>{'FEE-Implementation_Fee', 'VTR-EAB_Team_Shoot_VidPlus', 'VTR-EAB_Team_Shoot', 'FEE-EAB_BoxPACK', 'FEE-AZ_PhotoVideo_Onsite', 'VTR-FTE_Employ_Shoot', 'VTR-Contrctor_Shoot_Mini', 'FEE-Vrtl_Tr_sutp_Fee', 'VTR-Contrctor_Shoot_Full', 'VTR-Contnt_Lcnsng_OnTm_F', 'VTR-Drone_Still', 'VTR-Drone_Vid', 'VTR-Drone_Vid_Still'};
    Set<String> programs = new Set<String>();
    Set<String> setOfProductCode = new Set<String>();
    Map<String, Date> progStart = new Map<String, Date>();
    Map<String, Date> progEnd = new Map<String, Date>();
    Map<String, Decimal> progCost = new Map<String, Decimal>();
    Map<String, Decimal> progATFee = new Map<String, Decimal>();
    Map<String, Decimal> progImpFee = new Map<String, Decimal>();
    Map<String, String> progParent = new Map<String, String>();
    Map<String, Decimal> nbbAmt = new Map<String, Decimal>();
    Map<String, Decimal> firstYrVal = new Map<String, Decimal>();
    for (SBQQ__QuoteLine__c ql : qls) {
        String prog = null;
        progParent.put(ql.SBQQ__ProductName__c, ql.SBQQ__Product__r.Program__r.Program_Acronym__c != null ? ql.SBQQ__Product__r.Program__r.Program_Acronym__c : '');
        if (oneTimeProducts.contains(ql.SBQQ__ProductCode__c)) {
            prog = 'YOUVSS - Studio Services';
        } else if (ql.SBQQ__Product__r.Program__r.Program_Acronym__c != null) {
            prog = ql.SBQQ__Product__r.Program__r.Program_Acronym__c;
        } else if (ql.Related_Product__c != null) {
            prog = progParent.get(ql.Related_Product__c);
        }
        if (prog != null && (prog == 'YOUVSS - Studio Services' || prog == 'Youv' || prog == 'YOUV - Virtual Tour')) {
            programs.add(prog);
            Date qlStartDate = ql.SBQQ__StartDate__c;
            Date qlEndDate = ql.SBQQ__EndDate__c;
            // For YOUVSS, track actual quote line dates to determine if it's only in first year
            // For other programs, use proposal dates
            if (prog == 'YOUVSS - Studio Services') {
                // Track actual YOUVSS quote line dates (earliest start, latest end)
                if (!progStart.containsKey(prog) || qlStartDate < progStart.get(prog)) {
                    progStart.put(prog, qlStartDate);
                }
                if (!progEnd.containsKey(prog) || qlEndDate > progEnd.get(prog)) {
                    progEnd.put(prog, qlEndDate);
                }
            } else {
                // For Youv/YOUV - Virtual Tour, use proposal dates
                Date proposalStart = opp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c;
                Date proposalEnd = opp.SBQQ__PrimaryQuote__r.SBQQ__EndDate__c;
                if (opp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c != null && opp.SBQQ__PrimaryQuote__r.Opt_Out__c != null && opp.SBQQ__PrimaryQuote__r.Opt_Out__c != 'Funds Appropriation Opt Out') {
                    proposalEnd = opp.SBQQ__PrimaryQuote__r.Contract_Early_Termination_Date__c;
                }
                if (!progStart.containsKey(prog)) {
                    progStart.put(prog, proposalStart);
                }
                if (!progEnd.containsKey(prog)) {
                    progEnd.put(prog, proposalEnd);
                }
            }
            if (ql.SBQQ__ProductName__c != 'Administrative & Travel Fee') {
                progCost.put(prog, progCost.containsKey(prog) ? progCost.get(prog) + ql.SBQQ__CustomerTotal__c : ql.SBQQ__CustomerTotal__c);
            }
        }
        if (ql.SBQQ__ProductName__c == 'Administrative & Travel Fee') {
            String rp = progParent.get(ql.Related_Product__c);
            if (rp != null) progATFee.put(rp, progATFee.containsKey(rp) ? progATFee.get(rp) + ql.SBQQ__CustomerTotal__c : ql.SBQQ__CustomerTotal__c);
        }
        if (ql.SBQQ__ProductName__c == 'Implementation Fee') {
            String rp = progParent.get(ql.Related_Product__c);
            if (rp != null) progImpFee.put(rp, progImpFee.containsKey(rp) ? progImpFee.get(rp) + ql.SBQQ__CustomerTotal__c : ql.SBQQ__CustomerTotal__c);
        }
        if (ql.SBQQ__ProductName__c != 'Administrative & Travel Fee' && ql.SBQQ__ProductName__c != 'Implementation Fee') {
            setOfProductCode.add(ql.SBQQ__ProductCode__c);
        }
    }
    Boolean contractExist = false;
    List<Contract> listOfContractOnAccount = [SELECT ID FROM Contract WHERE AccountId = :opp.AccountId AND StartDate < :Date.today().addYears(-1) AND EndDate > :Date.today().addYears(-1) AND ID != :opp.LOA_Contract__c];
    if (listOfContractOnAccount.size() > 0) {
        List<SBQQ__QuoteLine__c> listOfQLsAssociatedToContracts = [SELECT ID, SBQQ__ProductCode__c, SBQQ__Product__r.Program__r.Program_Acronym__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Primary__c = true AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c = true OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = true) AND (SBQQ__Quote__r.SBQQ__Opportunity2__r.LOA_Contract__c IN :listOfContractOnAccount OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c IN :listOfContractOnAccount) AND (SBQQ__ProductCode__c IN :setOfProductCode OR SBQQ__Product__r.Program__r.Program_Acronym__c IN :programs)];
        contractExist = listOfQLsAssociatedToContracts.size() > 0;
    }
    // Re-evaluate NBB identification based on contractExist (matching old script logic)
    if (!contractExist && isParentBlank && !isThisARenewalForecasting && opp.SBQQ__AmendedContract__c == null && (opp.Is_this_an_amend_and_restate_contract__c == null || opp.Is_this_an_amend_and_restate_contract__c == 'No')) {
        isNBB = true;
        isRBB = false;
    } else if (opp.SBQQ__AmendedContract__c != null || opp.Is_this_an_amend_and_restate_contract__c == 'Yes') {
        isRBB = true;
        isNBB = false;
    } else if (contractExist || hasPrevOpp || isRenewal || isAmendment) {
        isRBB = true;
        isNBB = false;
    }
    for (String prog : programs) {
        Date startDate = progStart.get(prog);
        Date endDate = progEnd.get(prog);
        // Ensure start date is before end date
        if (startDate != null && endDate != null && startDate > endDate) {
            Date temp = startDate;
            startDate = endDate;
            endDate = temp;
        }
        Integer totalDays = startDate.daysBetween(endDate) + 1;
        if (totalDays < 1) {
            totalDays = 1; // Ensure totalDays is at least 1
        }
        Decimal adminAndTravelFee = progATFee.containsKey(prog) ? progATFee.get(prog) : 0;
        Decimal implementationFee = progImpFee.containsKey(prog) ? progImpFee.get(prog) : 0;
        Decimal totalProgramCost = progCost.get(prog) + adminAndTravelFee;
        Decimal nbbAmount = ((totalProgramCost / totalDays) * 365) + implementationFee;
        if(tipsContract){
            nbbAmount = nbbAmount * 0.99;
        }
        // For NBB and YOUVSS - Studio Services with <= 365 days, credit the full Total Program Cost
        if (isNBB && totalDays <= 365 && prog == 'YOUVSS - Studio Services') {
            nbbAmt.put(prog, progCost.get(prog).setScale(2));
        } else {
            nbbAmt.put(prog, nbbAmount.setScale(2));
        }
        Decimal fyv = totalProgramCost;
        if (totalDays > 365) fyv = (totalProgramCost / totalDays) * 365;
        firstYrVal.put(prog, fyv.setScale(2));
    }
    Boolean isUGPartner12M = false;
    Date checkDate = Date.today() < opp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c ? Date.today().addMonths(-12) : opp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c.addMonths(-12);
    List<Membership__c> ugMem = [SELECT ID, Last_End_Date_2__c FROM Membership__c WHERE Program__r.Partner_360_Terrain__c = 'Enrollment Services' AND Membership_Status__c = 'Member - Payer' AND Account_Name__c = :opp.AccountId AND Last_End_Date_2__c > :checkDate];
    if (ugMem != null && ugMem.size() > 1) {
        isUGPartner12M = true;
    }
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('                    UG PARTNER       ');
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('  Is UG Partner (12+ months):  ' + (isUGPartner12M ? 'YES ✓' : 'NO ✗'));
    System.debug('  UG Memberships Found:        ' + ugMem.size());
    List<Team_Membership__c> vtPDE = [SELECT Staff_member__r.Name FROM Team_Membership__c WHERE Institution__c = :opp.AccountId AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' AND (Program_Perspectives__c = 'Virtual Tour' OR Program_Perspectives__c LIKE '%Virtual%') LIMIT 1];
    List<Team_Membership__c> ugPDE = [SELECT Staff_member__r.Name FROM Team_Membership__c WHERE Institution__c = :opp.AccountId AND Role__r.Name = 'PDE (EXEC)' AND Status__c = 'Active' AND Program_Perspectives__c = 'Undergrad Enrollment' LIMIT 1];
    List<Team_Membership__c> vtPSM = [SELECT Staff_member__r.Name FROM Team_Membership__c WHERE Institution__c = :opp.AccountId AND Role__r.Name = 'PSM' AND Status__c = 'Active' AND (Program_Perspectives__c = 'Virtual Tour' OR Program_Perspectives__c LIKE '%Virtual%') LIMIT 1];
    String vtPDEname = vtPDE.size() > 0 ? vtPDE[0].Staff_member__r.Name : (ugPDE.size() > 0 ? ugPDE[0].Staff_member__r.Name : null);
    String vtPSMname = vtPSM.size() > 0 ? vtPSM[0].Staff_member__r.Name : null;
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('              ACTIVE STAFF ASSIGNMENTS');
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('  Virtual Tour PDE:  ' + (vtPDEname != null ? vtPDEname : 'NOT FOUND ⚠'));
    System.debug('  Virtual Tour PSM:  ' + (vtPSMname != null ? vtPSMname : 'NOT FOUND ⚠'));
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('              PROGRAMS TO PROCESS');
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('  Total Programs:  ' + programs.size());
    System.debug('  Programs:        ' + programs);
    Integer cnt = 0;
    for (String prog : programs) {
        cnt++;
        System.debug('════════════════════════════════════════════════════════════════');
        System.debug('  PROGRAM #' + cnt + ': ' + prog);
        System.debug('════════════════════════════════════════════════════════════════');
        System.debug('  Start Date:           ' + progStart.get(prog));
        System.debug('  End Date:             ' + progEnd.get(prog));
        System.debug('  Total Program Cost:   $' + progCost.get(prog));
        System.debug('  Admin & Travel Fee:   $' + (progATFee.containsKey(prog) ? progATFee.get(prog) : 0));
        System.debug('  Implementation Fee:   $' + (progImpFee.containsKey(prog) ? progImpFee.get(prog) : 0));
        Integer totalDays = progStart.get(prog).daysBetween(progEnd.get(prog)) + 1;
        Decimal adminAndTravelFee = progATFee.containsKey(prog) ? progATFee.get(prog) : 0;
        Decimal implementationFee = progImpFee.containsKey(prog) ? progImpFee.get(prog) : 0;
        Decimal totalProgramCost = progCost.get(prog) + adminAndTravelFee;
        System.debug('  Total Days:           ' + totalDays);
        System.debug('  Total Program Cost (with A&T): $' + totalProgramCost);
        System.debug('  NBB Amount:           $' + nbbAmt.get(prog));
        if (isRBB) {
            System.debug('  First Year Value:     $' + firstYrVal.get(prog));
        }
        if (isNBB) {
            System.debug('------------------------------------------------------------');
            System.debug('*** PROCESSING AS: NBB (New SALE) ***');
            System.debug('------------------------------------------------------------');
            Date curr = Date.today();
            Date propStart = progStart.get(prog);
            Date atl = propStart > curr ? Date.newInstance(propStart.year(), propStart.month(), 1) : curr;
            Date binder = curr;
            System.debug('  ATL Date:     ' + atl);
            System.debug('  Binder Date:  ' + binder);
            if (isUGPartner12M) {
                System.debug('  --- CREDIT ASSIGNMENT: UG Partner (12+ months) ---');
                System.debug('');
                Decimal shadowNBB = nbbAmt.get(prog);
                Decimal adamShadowNBB = 0 - shadowNBB;
                System.debug('  SHADOW CREDIT RECORD #1');
                System.debug('  ------------------------------------------------------');
                System.debug('  Credited User:  ' + opp.Owner.Name);
                System.debug('  NBB Amount:     $' + shadowNBB);
                System.debug('  NBB Type:       Shadow Credit');
                System.debug('  Deal Type:      New Sale');
                System.debug('  Program Name:   ' + prog);
                System.debug('  ATL Date:        ' + atl);
                System.debug('  Binder Date:     ' + binder);
                System.debug('');
                System.debug('  SHADOW CREDIT RECORD #2 (NEGATIVE)');
                System.debug('  ------------------------------------------------------');
                System.debug('  Credited User:  Adam Sutton');
                System.debug('  NBB Amount:     $' + adamShadowNBB);
                System.debug('  NBB Type:       Shadow Credit');
                System.debug('  Deal Type:      New Sale');
                System.debug('  Program Name:   ' + prog);
                System.debug('  ATL Date:        ' + atl);
                System.debug('  Binder Date:     ' + binder);
                System.debug('');
                System.debug('  NOTE: No Base Fee credit created for UG Partners');
                System.debug('  ------------------------------------------------------------');
            } else {
                System.debug('  --- CREDIT ASSIGNMENT: Not UG Partner ---');
                System.debug('');
                System.debug('  BASE FEE RECORD');
                System.debug('  ------------------------------------------------------');
                System.debug('  Credited User:  ' + opp.Owner.Name);
                System.debug('  NBB Amount:     $' + nbbAmt.get(prog));
                System.debug('  NBB Type:       Base Fee');
                System.debug('  Deal Type:      New Sale');
                System.debug('  Program Name:   ' + prog);
                System.debug('  ATL Date:        ' + atl);
                System.debug('  Binder Date:     ' + binder);
                if (vtPDEname != null) {
                    Decimal shadowNBB = nbbAmt.get(prog);
                    Decimal adamShadowNBB = 0 - shadowNBB;
                    System.debug('');
                    System.debug('  SHADOW CREDIT RECORD #1');
                    System.debug('  ------------------------------------------------------');
                    System.debug('  Credited User:  ' + vtPDEname + ' (Virtual Tour PDE)');
                    System.debug('  NBB Amount:     $' + shadowNBB);
                    System.debug('  NBB Type:       Shadow Credit');
                    System.debug('  Deal Type:      New Sale');
                    System.debug('  Program Name:   ' + prog);
                    System.debug('  ATL Date:        ' + atl);
                    System.debug('  Binder Date:     ' + binder);
                    System.debug('');
                    System.debug('  SHADOW CREDIT RECORD #2 (NEGATIVE)');
                    System.debug('  ------------------------------------------------------');
                    System.debug('  Credited User:  Adam Sutton');
                    System.debug('  NBB Amount:     $' + adamShadowNBB);
                    System.debug('  NBB Type:       Shadow Credit');
                    System.debug('  Deal Type:      New Sale');
                    System.debug('  Program Name:   ' + prog);
                    System.debug('  ATL Date:        ' + atl);
                    System.debug('  Binder Date:     ' + binder);
                } else {
                    System.debug('');
                    System.debug('  WARNING: No Virtual Tour PDE or Undergrad PDE found');
                    System.debug('            for Shadow Credit assignment');
                }
                System.debug('  ------------------------------------------------------------');
            }
        }
        if (isRBB) {
            System.debug('════════════════════════════════════════════════════════════════');
            System.debug('           PROCESSING NEEDED AS: RBB (Renewal )        ');
            System.debug('════════════════════════════════════════════════════════════════');
            Boolean isAmend = isAmendment || opp.SBQQ__AmendedContract__c != null;
            Date atl = null;
            Date binder = Date.today();
            String nbbType = null;
            String dealType = 'Renewal';
            String whereTo = null;
            String subPeriodId = null;
            String subPeriodName = null;
            Contract targetContract = null;
            if (prog == 'Youv' || prog == 'YOUV - Virtual Tour') {
                if (isAmend) {
                    whereTo = 'Subscription Period of Amendment Contract (Same Year)';
                    targetContract = opp.SBQQ__AmendedContract__c != null ? [SELECT ID, ContractNumber FROM Contract WHERE ID = :opp.SBQQ__AmendedContract__c LIMIT 1] : null;
                } else {
                    whereTo = 'NNLOA Subscription Period of Previous Contract';
                    if (opp.SBQQ__RenewedContract__c != null) {
                        targetContract = [SELECT ID, ContractNumber FROM Contract WHERE ID = :opp.SBQQ__RenewedContract__c LIMIT 1];
                    } else if (prevContracts.size() > 0) {
                        targetContract = [SELECT ID, ContractNumber FROM Contract WHERE ID = :prevContracts[0].ID LIMIT 1];
                    }
                }
                nbbType = 'Base Fee';
                dealType = 'Renewal';
                atl = opp.LOA_Contract__r.StartDate != null ? opp.LOA_Contract__r.StartDate : opp.SBQQ__PrimaryQuote__r.SBQQ__StartDate__c;
                System.debug('  Program Type:     YOUV' + (isAmend ? ' (Amendment)' : ' (Renewal)'));
            } else if (prog == 'YOUVSS - Studio Services') {
                whereTo = 'Subscription Period of New Contract';
                targetContract = opp.LOA_Contract__c != null ? [SELECT ID, ContractNumber FROM Contract WHERE ID = :opp.LOA_Contract__c LIMIT 1] : null;
                nbbType = 'One Time Non Renewable Fee';
                dealType = 'Renewal';
                atl = Date.today();
                System.debug('  Program Type:     YOUVSS');
            }
            if (targetContract != null) {
                System.debug('  Searching Contract: ' + targetContract.ID + ' (' + targetContract.ContractNumber + ')');
                List<Subscription_Period__c> subPeriods = [SELECT ID, Name, Decision_Type__c, Program__c FROM Subscription_Period__c WHERE Contract__c = :targetContract.ID AND Decision_Type__c = 'Need New LOA' AND (Program__c = 'YOUV - Virtual Tour' OR Program__c LIKE '%YOUV - Virtual Tour%') ORDER BY CreatedDate DESC LIMIT 1];
                if (subPeriods.size() > 0) {
                    subPeriodId = subPeriods[0].ID;
                    subPeriodName = subPeriods[0].Name;
                } else {
                    List<Subscription_Period__c> allSPs = [SELECT ID, Name, Decision_Type__c, Program__c FROM Subscription_Period__c WHERE Contract__c = :targetContract.ID AND Decision_Type__c = 'Need New LOA'];
                    if (allSPs.size() > 0) {
                        for (Subscription_Period__c sp : allSPs) {
                            if (sp.Program__c != null && (sp.Program__c.contains('YOUV') || sp.Program__c.contains('Virtual Tour'))) {
                                subPeriodId = sp.ID;
                                subPeriodName = sp.Name;
                                break;
                            }
                        }
                    }
                    if (subPeriodId == null) {
                        System.debug('  Total SPs with Decision Type "Need New LOA": ' + allSPs.size());
                        if (allSPs.size() > 0) {
                            System.debug('  Available SPs:');
                            for (Subscription_Period__c sp : allSPs) {
                                System.debug('    - ID: ' + sp.ID + ' | Name: ' + sp.Name + ' | Decision Type: ' + sp.Decision_Type__c + ' | Program: ' + sp.Program__c);
                            }
                        }
                    }
                }
            } else {
                System.debug('  Target Contract: NULL - Cannot search for Subscription Period');
            }
            //System.debug('--- RENEWAL BINDER RECORD DETAILS ---');
            //System.debug('');
            System.debug('  Where to Create: ' + whereTo);
            if (subPeriodId != null) {
                System.debug('  Subscription Period Found:');
                System.debug('  ------------------------------------------------------------');
                System.debug('    * ID:   ' + subPeriodId);
                System.debug('    * Name: ' + subPeriodName);
                String orgUrl = URL.getOrgDomainUrl().toExternalForm();
                System.debug('    * Link: ' + orgUrl + '/' + subPeriodId);
                System.debug('  ------------------------------------------------------------');
            } else {
                if (whereTo == 'NNLOA Subscription Period of Previous Contract') {
                    System.debug('  Subscription Period: NOT FOUND - Please locate manually NNLOA Subscription Period of Previous Contract');
                } else {
                    System.debug('  Subscription Period: NOT FOUND - Please locate manually');
                }
                if (targetContract != null) {
                    System.debug('  Contract Searched: ' + targetContract.ID + ' (' + targetContract.ContractNumber + ')');
                } else {
                    System.debug('  Contract Searched: No contract found to query');
                }
            }
            String creditedUser = vtPSMname != null ? vtPSMname : opp.Owner.Name;
            System.debug('  Credited User:   ' + creditedUser + (vtPSMname == null ? ' (Opp Owner - PSM)' : ''));
            System.debug('  Amount:          $' + firstYrVal.get(prog));
            System.debug('  NBB Type:        ' + nbbType);
            System.debug('  Deal Type:       ' + dealType);
            System.debug('  Program Name:    ' + prog);
            System.debug('  ATL Date:        ' + atl);
            System.debug('  Binder Date:     ' + binder);
            System.debug('  Record Type:     Renewal Binder');
            System.debug('  ------------------------------------------------------------');
        }
    }
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('                    FINAL SUMMARY');
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('  Record Type Identified:  ' + (isNBB ? 'NBB (New SALE)' : (isRBB ? 'RBB (Renewal Binder)' : 'UNKNOWN')));
    System.debug('  Total Programs Processed: ' + cnt);
    System.debug('  UG Partner Status:       ' + (isUGPartner12M ? 'Yes (12+ months)' : 'No'));
    System.debug('  Virtual Tour PDE:        ' + (vtPDEname != null ? vtPDEname : 'NOT FOUND'));
    System.debug('  Virtual Tour PSM:        ' + (vtPSMname != null ? vtPSMname : 'NOT FOUND'));
    if (opp.SBQQ__PrimaryQuote__r.Opt_Out__c != null) {
        System.debug('  ALERT - Opt Out: ' + opp.SBQQ__PrimaryQuote__r.Opt_Out__c);
    }
    if (opp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c != null) {
        System.debug('  ALERT - Secondary Opt Out: ' + opp.SBQQ__PrimaryQuote__r.Secondary_Opt_Out_or_Opt_In_Type__c);
    }
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('════════════════════════════════════════════════════════════════');
} catch (Exception e) {
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('                        ERROR OCCURRED');
    System.debug('════════════════════════════════════════════════════════════════');
    System.debug('  Error Message:  ' + e.getMessage());
    System.debug('  Stack Trace:    ' + e.getStackTraceString());
    System.debug('════════════════════════════════════════════════════════════════');
}
