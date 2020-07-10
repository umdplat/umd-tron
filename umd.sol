pragma solidity ^0.4.24;

import "./CommonLib.sol";
import "./CMember.sol";
import "./CDayMechineAccount.sol";
import "./CUsdtMan.sol";
import "./CUmdMan.sol";
import "./CDayMechineDiscount.sol";
import "./CPoolMan.sol";

import "./CUmd_common.sol";

contract umd {
    CommonLib.constDefs private consts;

    CMember private memberInfo;
    CDayMechineAccount private dayMechineAccount;
    CUsdtMan private usdtMan;
    CUmdMan private umdMan;
    CDayMechineDiscount private dayMechineDiscount;
    CPoolMan private poolMan;

    CUmd_common private umdCommon;

    address private managerAccount;

    address private tecAccount;  

    constructor() public{
        consts = CommonLib.constDefs({
            daySeconds: 0,
            rateTicketToBase: 0,
            dayCalPercentPerFund: 0
        });

        CommonLib.initConsts(consts);

        managerAccount = msg.sender;
    }

    function checkManager()private constant{
        require(msg.sender==managerAccount && managerAccount!=0, 'error0');
    }

    function setPart(uint32 xtype, address xaddr)public payable{
        checkManager();

        if(xtype==1)
            memberInfo = CMember(xaddr);
        else if(xtype==4)
            dayMechineAccount = CDayMechineAccount(xaddr);
        else if(xtype==5)
            usdtMan = CUsdtMan(xaddr);
        else if(xtype==6)
            dayMechineDiscount = CDayMechineDiscount(xaddr);
        else if(xtype==7)
            poolMan = CPoolMan(xaddr);
        else if(xtype==8)
            umdMan = CUmdMan(xaddr);

        else if(xtype==9)
            umdCommon = CUmd_common(xaddr);
        else
            require(1==2, 'error1');
    }

    function getDeliveryAmountAtDay(uint256 xday)public constant returns(uint64 rselfAmount, uint64 rsubAmount){
        return dayMechineAccount.getDeliveryAmountAtDay(msg.sender, xday);
    }

    function createMember(address xparentAccount) public payable returns(bool risOK, address rparentAccount){
        require(xparentAccount!=address(0), 'address error');

        if(xparentAccount==msg.sender){
            checkManager();
        }
        else{
            uint xparentState=memberInfo.getMemberState(xparentAccount);

            require(xparentState>0, 'parent state error');

            uint xparentGrade=memberInfo.getMemberGrade(xparentAccount);

            require(xparentGrade>0, 'parent grade error');
        }

        (risOK, rparentAccount) = memberInfo.createMember(msg.sender, xparentAccount);
        require(risOK, 'new member error');

        uint256 xtmpID = dayMechineAccount.createDayMechine(msg.sender);
        require(xtmpID>0, 'new mechine error');
    }

    function getReceiveSumInfoIDs(uint256 xindex)public constant returns(uint256[20] rids){
        return dayMechineAccount.getReceiveSumInfoIDs(msg.sender, xindex);
    }

    function getDayCalInfo(uint256 xid) public constant 
    returns(uint256 rcalDay, uint64 rsum_self, uint64 rsum_sub, uint64 rsum_global){
        return dayMechineAccount.getDayCalInfo(xid);
    }

    function getGlobalReceiveSum()public constant returns(uint256){
        return dayMechineAccount.getGlobalReceiveSum(msg.sender);
    }

    function getReceiveSum()public constant returns(uint256 rsum_self, uint256 rsum_sub, uint256 rsum_global){
        (rsum_self, rsum_sub) = dayMechineAccount.getReceiveSum(msg.sender);
        rsum_global = dayMechineAccount.getGlobalReceiveSum(msg.sender);
    }

    function getLockSum()public constant returns(uint64 rsum){
        uint64 xmax;
        uint64 xover;

        (xmax, xover) = dayMechineAccount.getDayCalLimit(msg.sender);

        return xmax-xover;
    }

    function getFundSum()public constant returns(uint256 rsum_self, uint256 rsum_sub){
        return dayMechineAccount.getFundSum(msg.sender);
    }

    function getOwnMemberIDs(uint256 xindex)public constant returns(uint256[20] rids){
        return memberInfo.getOwnMemberIDs(msg.sender, xindex);
    }

    function getOwnMemberAddress(uint256 xmemberID)public constant returns(address raddr){
        raddr = memberInfo.getMemberAddress(xmemberID);

        bool risMemberExists;
        uint32 rstate;
        address rparentAccount;
        uint64 rdirectCount;
        uint64 rgapCount;
        uint64 rfactDirectCount;
        uint64 rfactGapCount;

        (risMemberExists, rstate, rparentAccount, rdirectCount, rgapCount, rfactDirectCount, rfactGapCount) =  
            memberInfo.getMemberInfo(raddr);

        if(rparentAccount!=msg.sender)
            return 0;

        return raddr;
    }

    function getMemberInfo() public constant returns(
        bool risMemberExists, uint32 rstate, address rparentAccount, uint64 rdirectCount, uint64 rgapCount,
        uint64 rfactDirectCount, uint64 rfactGapCount, uint32 rmemberGrade
    ){
        (risMemberExists, rstate, rparentAccount, rdirectCount, rgapCount,
            rfactDirectCount, rfactGapCount) = memberInfo.getMemberInfo(msg.sender);

        rmemberGrade = memberInfo.getMemberGrade(msg.sender);
    }

    function getContractPoolInfo()public constant returns(uint64 rfundSum, uint64 rlastAmount){
        return poolMan.getContractPoolInfo();
    }

    function getSafePoolInfo()public constant
    returns(uint64 rfundSum, uint64 rlastAmount, uint64 rumdLastAmount, uint64 rumdFloatPoint,
            uint64 rumdPrice, uint64 rumdDiscountLastAmount, uint64 rumdDiscountLimit){
        return poolMan.getSafePoolInfo();
    }

    function needDistribToUMD(uint64 xamount)public payable{
        uint64 xmax;
        uint64 xover;
        uint64 xlast;

        (xmax, xover) = dayMechineAccount.getDayCalLimit(msg.sender);

        CommonLib.checkCanAddOrSub(false, xmax, xover);

        xlast = xmax-xover;

        require(xlast>=xamount, 'qty error');

        dayMechineAccount.addDayCalSum(msg.sender, 0, xamount);

        umdCommon.fundToSafePool_umd(xamount, msg.sender);

    }

    function getContractPoolLastDayFund()public constant returns(uint64 rfundAmountAtLastDay){
        uint256 xday = block.timestamp/consts.daySeconds;

        rfundAmountAtLastDay = poolMan.getFundSumAtDay(xday-1);
    }

    uint256 private safeProcessIndex=0; 
    uint64 private safeProcessCount=201;

    function getSafeProcessInfo()public constant returns(uint256 rindex, uint64 rcount){
        return(safeProcessIndex, safeProcessCount);
    }

    function startSafeProcess()public payable{
        uint256 xday = block.timestamp/consts.daySeconds;

        bool xbool;
        address xaddr;
        uint64 xamount;
        uint64 xfactAmount;

        uint64 xfundAmountAtLastDay = poolMan.getFundSumAtDay(xday-1);

        require(xfundAmountAtLastDay<200*consts.rateTicketToBase, 'sum error');
        
        (xbool,xamount) = poolMan.getLastAmountFromDay(xday);

        require(xamount<100*consts.rateTicketToBase, 'amount error');


        uint64 xtmpCount=safeProcessCount;
        uint256 xtmpIndex=safeProcessIndex;

        if(xtmpCount>=200){  
            xtmpCount=0;
            xtmpIndex=poolMan.getFundInfoCount()-1;
        }

        uint256 xendIndex = (xtmpIndex>=4?xtmpIndex-4:0);

        uint64 xsafeLastAmount = poolMan.getSafePoolLastAmount();

        for(uint256 i=xtmpIndex; i>=xendIndex; i--){
            if(xtmpCount>=200)  
                break;

            xtmpIndex=i; 

            (xaddr, xamount) = poolMan.getFundInfo(i);

            if(xaddr==0){
                if(i<=xendIndex)
                    break;
                continue;
            }

            if(xamount<5000*consts.rateTicketToBase){ 
                if(i<=xendIndex)
                    break;
                continue;
            }

            xfactAmount = xamount*2;

            if(xfactAmount<xamount){
                if(i<=xendIndex)
                    break;
                continue;
            }

            if(xsafeLastAmount-xfactAmount>=xsafeLastAmount){
                if(i<=xendIndex)
                    break;
                continue;
            }

            xsafeLastAmount = xsafeLastAmount-xfactAmount;

            xtmpCount += 1;

            poolMan.changeSafePool(false, 0, xfactAmount, 0, 0);

            usdtMan.sendToMember(xaddr, xfactAmount);

            if(i<=xendIndex)
                break;
        }
        
        safeProcessCount = xtmpCount;
        safeProcessIndex = xtmpIndex;

        if(xtmpCount>=200 || xtmpIndex<=0){  
            safeProcessCount = 201;  

            poolMan.sendSafePoolLastAmountToContractPool(xsafeLastAmount);
        }
        else{
            if(safeProcessIndex>0) 
                safeProcessIndex-=1;
        }

    }
}
