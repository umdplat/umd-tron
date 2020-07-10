pragma solidity ^0.4.24;

import "./CommonLib.sol";

contract CPoolMan {
    struct CContractPoolInfo{
        uint64 fundSum;
        uint64 lastAmount;
    }

    struct CSafePoolInfo{
        uint64 fundSum;
        uint64 lastAmount;
        uint64 umdLastAmount;
        uint64 umdFloatPoint;
        uint64 umdPrice;
        uint64 umdDiscountLastAmount;
        uint64 umdDiscountLimit;
    }

    struct CFundInfo{
        address memberAddr;
        uint64 fundAmount;
    }

    CFundInfo[] private fundInfoList;

    CContractPoolInfo private contractPool;
    CSafePoolInfo private safePool;

    mapping(uint256=>bool) lastAmountUpdatedDay;
    mapping(uint256=>uint64) private lastAmount_day;

    mapping(uint256=>uint64) private fundSum_day;

    uint256 private lastSendSafeToContractDate;

    bool private isCheckManager=true;

    mapping(address => bool) private managerAccountDic;

    constructor() public{
        managerAccountDic[msg.sender]=true;

        contractPool = CContractPoolInfo({
            fundSum: 0,
            lastAmount: 0
        });

        safePool = CSafePoolInfo({
            fundSum: 0,
            lastAmount: 0,
            umdLastAmount: 8600*10000*1000000,
            umdFloatPoint: 6,
            umdPrice: 100000,
            umdDiscountLastAmount: 800000*1000000,
            umdDiscountLimit: 800000*1000000
        });
    }

    function setManagerAccount(address xmanager, bool xisManager)public payable{
        require(managerAccountDic[msg.sender]);

        managerAccountDic[xmanager]=xisManager;

    }

    function checkManager()private constant{
        require(!isCheckManager || managerAccountDic[msg.sender], 'error0');
    }

    function addFundInfo(address xaddr, uint64 xamount)public payable{
        checkManager();
        CFundInfo memory xinfo = CFundInfo({
            memberAddr: xaddr,
            fundAmount: xamount
        });

        fundInfoList.push(xinfo);
    }

    function getFundInfoCount()public constant returns(uint256 rcount){
        checkManager();
        return fundInfoList.length;
    }

    function getFundInfo(uint256 xindex)public constant
    returns(address xaddr, uint64 xamount){
        checkManager();

        CFundInfo memory xinfo = fundInfoList[xindex];

        require(xinfo.memberAddr>0, 'index error');

        return(xinfo.memberAddr, xinfo.fundAmount);
    }

    function changeLastAmountAtDay(uint256 xdate_day, bool xisAdd, uint64 xqty)public payable{
        checkManager();

        uint64 xtmp = lastAmount_day[xdate_day];

        if(xisAdd){
            require(xtmp+xqty>=xtmp, 'qty error');
            lastAmount_day[xdate_day] += xqty;
        }
        else{
            require(xtmp>=xqty);
            require(xtmp-xqty<=xtmp);
            lastAmount_day[xdate_day] -= xqty;
        }

        lastAmountUpdatedDay[xdate_day]=true;
    }

    function getLastAmountFromDay(uint256 xdate_day)public constant returns(bool risHad, uint64 ramount){
        checkManager();

        while(!lastAmountUpdatedDay[xdate_day]){
            xdate_day -= 1;

            if(xdate_day<18400){
                return(false, 0);
            }
        }
        
        return(true,lastAmount_day[xdate_day]);
    }

    function getLastAmountAtDay(uint256 xdate_day)public constant returns(uint64 rqty){
        checkManager();

        return lastAmount_day[xdate_day];
    }

    function changeFundSumAtDay(uint256 xdate_day, bool xisAdd, uint64 xqty)public payable{
        checkManager();

        uint64 xtmp = fundSum_day[xdate_day];

        if(xisAdd){
            require(xtmp+xqty>xtmp, 'qty error');
            fundSum_day[xdate_day] += xqty;
        }
        else{
            require(xtmp>xqty);
            require(xtmp-xqty<xtmp);
            fundSum_day[xdate_day] -= xqty;
        }
    }

    function getFundSumAtDay(uint256 xdate_day)public constant returns(uint64 rqty){
        checkManager();

        return fundSum_day[xdate_day];
    }

    function changeUmdPrice(bool xisAdd, uint64 xqty)
    public payable{
        checkManager();

        CommonLib.checkCanAddOrSub(xisAdd, safePool.umdPrice, xqty);

        if(xisAdd){
            safePool.umdPrice += xqty;
        }
        else{
            safePool.umdPrice -= xqty;
        }
    }

    function getUmdPrice()public constant returns(uint64 rprice, uint64 rumdFloatPoint){
        checkManager();

        return (safePool.umdPrice, safePool.umdFloatPoint);
    }

    function resetDiscountLimit(uint64 xlowLimit)public payable{
        checkManager();

        if(safePool.umdLastAmount>=xlowLimit+safePool.umdDiscountLimit){
            safePool.umdDiscountLastAmount = safePool.umdDiscountLimit;
        }
        else{
            safePool.umdDiscountLastAmount = safePool.umdDiscountLimit-((xlowLimit+safePool.umdDiscountLimit)-safePool.umdLastAmount);
        }
        
    }

    function changeSafePool(bool xisAdd, uint64 xqty_fund, uint64 xqty_lastAmount,
        uint64 qty_umdLastAmount, uint64 xqty_discountLastAmount)
    public payable{
        checkManager();
        
        if(xqty_fund>0){
            CommonLib.checkCanAddOrSub(xisAdd, safePool.fundSum, xqty_fund);

            if(xisAdd){
                safePool.fundSum += xqty_fund;
            }
            else{
                safePool.fundSum -= xqty_fund;
            }
        }

        if(xqty_lastAmount>0){
            CommonLib.checkCanAddOrSub(xisAdd, safePool.lastAmount, xqty_lastAmount);

            if(xisAdd){
                safePool.lastAmount += xqty_lastAmount;
            }
            else{
                safePool.lastAmount -= xqty_lastAmount;
            }
        }

        if(qty_umdLastAmount>0){
            CommonLib.checkCanAddOrSub(xisAdd, safePool.umdLastAmount, qty_umdLastAmount);

            if(xisAdd){
                safePool.umdLastAmount += qty_umdLastAmount;
            }
            else{
                safePool.umdLastAmount -= qty_umdLastAmount;
            }
        }

        if(xqty_discountLastAmount>0){
            CommonLib.checkCanAddOrSub(xisAdd, safePool.umdDiscountLastAmount, xqty_discountLastAmount);

            if(xisAdd){
                safePool.umdDiscountLastAmount += xqty_discountLastAmount;
            }
            else{
                safePool.umdDiscountLastAmount -= xqty_discountLastAmount;
            }
        }
    }

    function changeContractPool(bool xisAdd, uint64 xqty_fund, uint64 xqty_lastAmount, uint256 xdate_day)public payable{
        checkManager();
        
        if(xqty_fund>0){
            CommonLib.checkCanAddOrSub(xisAdd, contractPool.fundSum, xqty_fund);

            if(xisAdd){
                contractPool.fundSum += xqty_fund;
            }
            else{
                contractPool.fundSum -= xqty_fund;
            }

            changeFundSumAtDay(xdate_day, xisAdd, xqty_fund);
        }

        if(xqty_lastAmount>0){
            CommonLib.checkCanAddOrSub(xisAdd, contractPool.lastAmount, xqty_lastAmount);

            if(xisAdd){
                contractPool.lastAmount += xqty_lastAmount;
            }
            else{
                contractPool.lastAmount -= xqty_lastAmount;
            }

            lastAmount_day[xdate_day] = contractPool.lastAmount;
            lastAmountUpdatedDay[xdate_day]=true;
        }
    }

    function getContractPoolInfo()public constant returns(uint64 rfundSum, uint64 rlastAmount){
        checkManager();
        
        return (contractPool.fundSum, contractPool.lastAmount);
    }

    function getContractPoolLastAmount()public constant returns(uint64 rlastAmount){
        checkManager();
        
        return (contractPool.lastAmount);
    }

    function getSafePoolInfo()public constant
    returns(uint64 rfundSum, uint64 rlastAmount, uint64 rumdLastAmount, uint64 rumdFloatPoint,
        uint64 rumdPrice, uint64 rumdDiscountLastAmount, uint64 rumdDiscountLimit)
    {
        checkManager();

        return (safePool.fundSum, safePool.lastAmount, safePool.umdLastAmount, safePool.umdFloatPoint,
            safePool.umdPrice, safePool.umdDiscountLastAmount, safePool.umdDiscountLimit);
    }

    function getSafePoolLastAmount()public constant returns(uint64 ramount){
        checkManager();

        return safePool.lastAmount;
    }

    function sendSafePoolLastAmountToContractPool(uint64 xamount)public payable{
        checkManager();

        CommonLib.checkCanAddOrSub(false, safePool.lastAmount, xamount);
        CommonLib.checkCanAddOrSub(true, contractPool.lastAmount, xamount);

        safePool.lastAmount -= xamount;
        contractPool.lastAmount += xamount;

        lastSendSafeToContractDate = block.timestamp;
    }

    function getLastSendSafeToContractDate()public constant returns(uint256 rdate){
        checkManager();

        return lastSendSafeToContractDate;
    }

    function getSafePoolInfo2()public constant
    returns(uint64 rumdLastAmount, uint64 rumdFloatPoint,
        uint64 rumdPrice, uint64 rumdDiscountLastAmount, uint64 rumdDiscountLimit)
    {
        checkManager();

        return (safePool.umdLastAmount, safePool.umdFloatPoint, 
            safePool.umdPrice, safePool.umdDiscountLastAmount, safePool.umdDiscountLimit);
    }
}
