pragma solidity ^0.4.24;

import "./CommonLib.sol";

import "./CUmd_common.sol";

contract umd_fund {
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

    event Debug(string xmsg, uint256 xpara);

    function log(string xmsg, uint256 xpara)private{
        emit Debug(xmsg, xpara);
    }

    function setTecAccount(address xaddr)public payable{
        checkManager();

        tecAccount = xaddr;
    }

    function getTecAccount()public constant returns(address raddr){
        checkManager();
        return tecAccount;
    }

    function fund(uint32 xtype) public payable returns(bool risOK){
        uint64 xamount = 0;
        uint64 xprofit = 0;
        uint32 xthisGrade = 0;

        uint64 xtmp;
        uint64 xtmp2;

        if(xtype==1){
            xamount = 200;
            xprofit = xamount*22/10;
            xthisGrade = 1;
        }
        else if(xtype==2){
            xamount = 1500;
            xprofit = xamount*25/10;
            xthisGrade = 2;
        }
        else if(xtype==3){
            xamount = 5000;
            xprofit = xamount*28/10;
            xthisGrade = 3;
        }
        else if(xtype==4){
            xamount = 10000;
            xprofit = xamount*3;
            xthisGrade = 4;
        }
        else if(xtype==5){
            xamount = 50000;
            xprofit = xamount*3;
            xthisGrade = 5;
        }
        else{
            require(1==2, 'type error');
        }

        xamount = xamount * consts.rateTicketToBase;
        xprofit = xprofit * consts.rateTicketToBase;

        uint32 xmemberState = memberInfo.getMemberState(msg.sender);
        require(xmemberState>0, 'state error');

        uint32 xmemberOldGrade = memberInfo.getMemberGrade(msg.sender);

        usdtMan.memberFundIn(msg.sender, xamount);
        xtmp = xamount*90/100;  
        fundToContractPool(xtmp-xamount*3/100); 
        xtmp = xamount - xtmp;  
        umdCommon.fundToSafePool_umd(xtmp, address(0x410000000000000000000000000000000000000000)); 
        fundToSafePool_usdt(xtmp); 
        upgradeMemberGrade(msg.sender, xthisGrade);
        (xtmp, xtmp2) = addDayMechine(msg.sender, xamount, xprofit, true);
        fundToParent(msg.sender, xtmp, xtmp2, xamount, xmemberOldGrade==0);
        usdtMan.sendToMember(tecAccount, xamount*3/100);
        poolMan.addFundInfo(msg.sender, xamount);
    }

    function upgradeMemberGrade(address xaddr, uint32 xthisGrade)private{
        bool xisUpgraded = memberInfo.upgradeMemberGrade(xaddr, xthisGrade);

        if(xisUpgraded){  
            address xparentAddr = memberInfo.getParentAddr(xaddr);

            if(xparentAddr>0 && xparentAddr!=address(0x410000000000000000000000000000000000000000)){
                uint32 xparentSubCount;
                uint32 xparentGrade;

                if(xthisGrade==5){ 
                    memberInfo.addU5Member(xaddr);
                    (xparentSubCount, xparentGrade) = memberInfo.changeU5Count(xparentAddr, true, 1);

                    if(xparentSubCount>=3 && xparentGrade>=5){
                        xisUpgraded = memberInfo.upgradeMemberGrade(xparentAddr, 6);
                        if(xisUpgraded){  
                            memberInfo.addU6Member(xaddr);

                            xparentAddr = memberInfo.getParentAddr(xparentAddr);

                            (xparentSubCount, xparentGrade) = memberInfo.changeU6Count(xparentAddr, true, 1);

                            if(xparentSubCount>=3 && xparentGrade>=6){
                                xisUpgraded = memberInfo.upgradeMemberGrade(xparentAddr, 7);
                                if(xisUpgraded){  
                                    memberInfo.addU7Member(xaddr);
                                }
                            }
                        }
                    }
                }
                else if(xthisGrade==6){  
                    memberInfo.addU6Member(xaddr);
                    (xparentSubCount, xparentGrade) = memberInfo.changeU6Count(xparentAddr, true, 1);

                    if(xparentSubCount>=3 && xparentGrade>=6){
                        xisUpgraded = memberInfo.upgradeMemberGrade(xparentAddr, 7);
                        if(xisUpgraded){  
                            memberInfo.addU7Member(xaddr);
                        }
                    }
                }
                else if(xthisGrade==7){  
                    memberInfo.addU7Member(xaddr);
                }
            }
        }
    }

    function fundToContractPool(uint64 xamount)private{
        poolMan.changeContractPool(true, xamount, xamount, block.timestamp/consts.daySeconds);
    }

    function fundToSafePool_usdt(uint64 xamount)private{
        poolMan.changeSafePool(true, xamount, xamount, 0, 0);

    }

    function fundToParent(address xaddr, uint64 xdayCalCount, uint64 xdayAmountToBase, 
            uint64 xfundAmountToBase, bool xisFirstFund)private{
        bool xbln;
        uint64 xtmp;
        uint64 xparentAmount;
        uint64 xparentDayAmount;
        uint64 xparentCurrentDayCalCount;

        if(xdayCalCount<=0 || xdayAmountToBase<=0){
            return;
        }
        
        address xparentAddr;
        address xaddr_cur = xaddr;

        for(uint64 i = 1; i<=7; i++){
            xparentAddr = memberInfo.getParentAddr(xaddr_cur);

            if(xparentAddr==0 || 
                    xparentAddr==address(0x410000000000000000000000000000000000000000) || 
                    xparentAddr==xaddr){
                break;
            }

            if(i==1){  
                if(xisFirstFund){
                    memberInfo.changeFactDirectCount(xparentAddr, true, 1);
                }

                xbln = true;
            }
            else{  
                if(xisFirstFund){
                    memberInfo.changeFactGapCount(xparentAddr, true, 1);
                }

                xtmp = memberInfo.getFactDirectCount(xparentAddr);
                if(xtmp>=i){  
                    xbln = true;
                }
                else{ 
                    xbln = false;
                }
            }

            if(xbln){
                if(i>=1 && i<=9){
                    xparentDayAmount = xfundAmountToBase*1/100;
                }
                else if(i>=10 && i<=15){
                    xparentDayAmount = xfundAmountToBase*5/1000;
                }

                xparentAmount = xparentDayAmount; 

                dayMechineAccount.fundDayMechine(xparentAddr, xparentDayAmount, xfundAmountToBase, xparentAmount, false);

                xparentCurrentDayCalCount = memberInfo.getDayCalCount(xparentAddr);
                require(xparentCurrentDayCalCount+1>xparentCurrentDayCalCount, 'day error');

                xtmp = xparentCurrentDayCalCount+1;

                dayMechineDiscount.addDiscountInfo(xparentAddr, xtmp, xparentDayAmount, false);

                xparentDayAmount = 0; 
                
                if(i==1){
                    xparentDayAmount = xdayAmountToBase*18/100;
                }
                else if(i==2){
                    xparentDayAmount = xdayAmountToBase*12/100;
                }
                else if(i==3){
                    xparentDayAmount = xdayAmountToBase*10/100;
                }
                else if(i>=4 && i<=15){
                    xparentDayAmount = xdayAmountToBase*5/100;
                }

                xparentAmount = xparentDayAmount*xdayCalCount;  

                dayMechineAccount.fundDayMechine(xparentAddr, xparentDayAmount, 0, xparentAmount, false);

                require(xparentCurrentDayCalCount+xdayCalCount>xparentCurrentDayCalCount, 'day error');

                xtmp = xparentCurrentDayCalCount+xdayCalCount;

                dayMechineDiscount.addDiscountInfo(xparentAddr, xtmp, xparentDayAmount, false);
            }

            xaddr_cur = xparentAddr;
        }
    }

    function addDayMechine(address xaddr, uint64 xamountToBase, uint64 xallAmountToBase, bool xisSelf)private
    returns(uint64 rdayCalCount, uint64 rdayAmountToBase){
        (rdayCalCount, rdayAmountToBase) = getDayCalCountByAmount(xamountToBase, xallAmountToBase);

        require(rdayCalCount>0, 'day error');
        require(rdayAmountToBase>0, 'day amount error');

        dayMechineAccount.addDayCalSum(xaddr, xallAmountToBase, 0);

        dayMechineAccount.fundDayMechine(xaddr, rdayAmountToBase, xamountToBase, xallAmountToBase, xisSelf);

        uint64 xtmp = memberInfo.getDayCalCount(xaddr);
        require(xtmp+rdayCalCount>xtmp, 'day error');

        xtmp += rdayCalCount;

        dayMechineDiscount.addDiscountInfo(xaddr, xtmp, rdayAmountToBase, xisSelf);
    }

    function getDayCalCountByAmount(uint64 xamountToBase, uint64 xallAmountToBase)private constant
    returns(uint64 rdayCalCount, uint64 rdayAmountToBase){
        rdayAmountToBase = xamountToBase*consts.dayCalPercentPerFund/10000;

        rdayCalCount = xallAmountToBase/rdayAmountToBase;

        if(rdayCalCount*rdayAmountToBase<xallAmountToBase){  
            rdayCalCount += 1;
        }

        return (rdayCalCount, rdayAmountToBase);
    }
}
