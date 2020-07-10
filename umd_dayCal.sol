pragma solidity ^0.4.24;

import "./CommonLib.sol";

import "./CUmd_common.sol";

contract umd_dayCal {
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
    
    function dayCal()public payable{
        address xaddr=msg.sender;

        uint256 xnow_day = block.timestamp / consts.daySeconds;

        dayMechineAccount.checkDayCalDay(xaddr, xnow_day);

        uint64 xamountSelf;
        uint64 xamountSub;
        uint64 xamountGlobal;
        
        (xamountSelf, xamountSub) = dayMechineAccount.getDeliveryAmountAtDay(xaddr, xnow_day);

        xamountGlobal = calGlobalDayCalAmount(xaddr);
        (xamountSelf, xamountSub, xamountGlobal) = calFactDayCalAmount(xaddr, xamountSelf, xamountSub, xamountGlobal);

        require(xamountSelf>0 || xamountSub>0 || xamountGlobal>0, 'amount error');
        dayMechineAccount.addDayCalSum(xaddr, 0, xamountSelf+xamountSub+xamountGlobal);

        uint64 xdayCalCount = memberInfo.changeDayCalCount(xaddr, true, 1);
        dayMechineAccount.changeLastDeliveryDay(xaddr, xnow_day);
        dayMechineAccount.changeMemberLastAmount(xaddr, false, xamountSelf, true);
        dayMechineAccount.changeMemberLastAmount(xaddr, false, xamountSub, false);
        uint64 xdiscountAmountSelf;
        uint64 xdiscountAmountSub;
        
        (xdiscountAmountSelf, xdiscountAmountSub) = dayMechineDiscount.getDiscountAmount(xaddr, xdayCalCount);

        if(xdiscountAmountSelf>0){
            dayMechineAccount.changeDayAmount(xaddr, false, xdiscountAmountSelf, true);
        }
        
        if(xdiscountAmountSub>0){
            dayMechineAccount.changeDayAmount(xaddr, false, xdiscountAmountSub, false);
        }
        poolMan.changeContractPool(false, 0, xamountSelf+xamountSub+xamountGlobal, xnow_day);

        usdtMan.sendToMember(xaddr, xamountSelf+xamountSub+xamountGlobal);
        dayMechineAccount.changeReceiveSum(xaddr, true, xamountSelf, xamountSub);
        dayMechineAccount.changeGlobalReceiveSum(xaddr, true, xamountGlobal);
        dayMechineAccount.addReceiveSum_day(xaddr, xnow_day, xamountSelf, xamountSub, xamountGlobal);
    }

    function calGlobalDayCalAmount(address xaddr)public returns(uint64 ramountGlobal){
        uint32 xgrade = memberInfo.getMemberGrade(xaddr);

        if(xgrade<5)
            return 0;

        uint256 xday = block.timestamp/consts.daySeconds-1;

        bool xbool;
        uint64 xlastAmountPreDay;
        (xbool,xlastAmountPreDay) = poolMan.getLastAmountFromDay(xday);

        if(!xbool)
            return 0;

        uint64 xamount = 0;
        uint64 xmemberCount = 0;
        if(xgrade>=5){
            xmemberCount = uint64(memberInfo.getAllU5Count());

            require(xmemberCount>0, 'qty error');
            xamount += xlastAmountPreDay*5/(xmemberCount*10000);
        }

        if(xgrade>=6){
            xmemberCount = uint64(memberInfo.getAllU6Count());

            require(xmemberCount>0, 'qty error');
            xamount += xlastAmountPreDay*5/(xmemberCount*10000);
        }

        if(xgrade>=7){
            xmemberCount = uint64(memberInfo.getAllU7Count());

            require(xmemberCount>0, 'qty error');
            xamount += xlastAmountPreDay*5/(xmemberCount*10000);
        }

        return xamount;
    }
    function calFactDayCalAmount(address xaddr, uint64 xamountSelf, uint64 xamountSub, uint64 xamountGlobal)private
    returns(uint64 rfactSelf, uint64 rfactSub, uint64 rfactGlobal){
        uint64 xmax;
        uint64 xover;
        uint64 xall;
        uint64 xpoolLastAmount = poolMan.getContractPoolLastAmount();  

        require(xamountSelf+xamountSub>=xamountSelf);

        if(xamountSelf+xamountSub>xpoolLastAmount){ 
            if(xamountSelf>xpoolLastAmount){  
                xamountSelf=xpoolLastAmount;
                xamountSub=0;
            }
            else{
                xamountSub=xpoolLastAmount-xamountSelf;
            }

            xamountGlobal = 0;
        }
        else{
            if(xamountSelf+xamountSub+xamountGlobal>xpoolLastAmount){ 
                xamountGlobal=xpoolLastAmount-(xamountSelf+xamountSub);
            }
        }

        (xmax, xover) = dayMechineAccount.getDayCalLimit(xaddr);

        xall = xamountSelf+xamountSub; 

        require(xover+xall+xamountGlobal>xover, 'qty error');

        if(xover+xall>xmax){  
            xall = xmax-xover;

            rfactSelf = xall/2;

            if(rfactSelf>xamountSelf){ 
                rfactSelf = xamountSelf;
            }
            rfactSub = xall-rfactSelf;

            return(rfactSelf, rfactSub, 0);  
        }
        else{  
            if(xover+xall+xamountGlobal>xmax){ 
                rfactSelf = xamountSelf;
                rfactSub = xamountSub;

                rfactGlobal = xmax-xover-xall;

                return(rfactSelf, rfactSub, rfactGlobal);
            }
            else{  
                return(xamountSelf, xamountSub, xamountGlobal);
            }

        }
    }
}
