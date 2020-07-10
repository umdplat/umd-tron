pragma solidity ^0.4.24;

import "./CommonLib.sol";

import "./CMember.sol";
import "./CDayMechineAccount.sol";
import "./CUsdtMan.sol";
import "./CUmdMan.sol";
import "./CDayMechineDiscount.sol";
import "./CPoolMan.sol";

contract CUmd_common {
    CommonLib.constDefs private consts;

    CMember private memberInfo;
    CDayMechineAccount private dayMechineAccount;
    CUsdtMan private usdtMan;
    CUmdMan private umdMan;
    CDayMechineDiscount private dayMechineDiscount;
    CPoolMan private poolMan;

    bool private isCheckManager=true;

    mapping(address => bool) private managerAccountDic;

    address private tecAccount;

    constructor() public{
        managerAccountDic[msg.sender]=true;
        
        consts = CommonLib.constDefs({
            daySeconds: 0,
            rateTicketToBase: 0,
            dayCalPercentPerFund: 0
        });

        CommonLib.initConsts(consts);

    }

    function setManagerAccount(address xmanager, bool xisManager)public payable{
        require(managerAccountDic[msg.sender]);

        managerAccountDic[xmanager]=xisManager;

    }

    function checkManager()private constant{
        require(!isCheckManager || managerAccountDic[msg.sender], 'error0');
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
        else
            require(1==2, 'error1');
    }

    function fundToSafePool_umd(uint64 xamount, address xsendToAddr)public payable{
        checkManager();

        uint64 xumdLastAmount;
        uint64 xumdFloatPoint;
        uint64 xumdPrice;
        uint64 xumdDiscountLastAmount;
        uint64 xumdDiscountLimit;
        
        (xumdLastAmount, xumdFloatPoint, xumdPrice, xumdDiscountLastAmount, xumdDiscountLimit) = poolMan.getSafePoolInfo2();

        uint64 xumdAmount = xamount*(10**xumdFloatPoint)/xumdPrice;  

        uint64 xlowLimit = 1800*10000*(10**xumdFloatPoint);  

        CommonLib.checkCanAddOrSub(false, xumdLastAmount, xlowLimit+xumdAmount);

        if(xumdDiscountLastAmount>xumdAmount){  
            poolMan.changeSafePool(false, 0, 0, xumdAmount, xumdAmount);

            umdMan.transfer(xsendToAddr, xumdAmount);
        }
        else{  
            poolMan.changeSafePool(false, 0, 0, xumdDiscountLastAmount, xumdDiscountLastAmount);

            umdMan.transfer(xsendToAddr, xumdDiscountLastAmount);

            poolMan.changeUmdPrice(true, 100000);

            poolMan.resetDiscountLimit(xlowLimit);

            uint64 xtmp = xumdAmount-xumdDiscountLastAmount;

            if(xtmp>0){  
                xtmp = xtmp*xumdPrice/(10**xumdFloatPoint);

                fundToSafePool_umd(xtmp, xsendToAddr);
            }
        }
    }
}
