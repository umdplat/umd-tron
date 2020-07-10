pragma solidity ^0.4.24;

library CommonLib{
    struct constDefs{
        uint256 daySeconds;

        uint64 rateTicketToBase;

        uint64 dayCalPercentPerFund;

    }

    function initConsts(constDefs storage xconst)internal{
        xconst.daySeconds = 86400;

        xconst.rateTicketToBase = 1000*1000;

        xconst.dayCalPercentPerFund = 80;
    }

    function checkCanAddOrSub(bool xisAdd, uint64 xcur, uint64 xqty) public{
        if(xisAdd){
            require(xcur+xqty>=xcur, 'qty error');

        }
        else{
            require(xcur>=xqty, 'qty error');
            require(xcur-xqty<=xcur, 'qty error');
        }
    }

    struct memberInfo{
        address account;
        address parentAccount;
        
        uint64 directCount;
        uint64 gapCount;

        uint64 factDirectCount;
        uint64 factGapCount;

        uint64 dayCalCount;

        uint32 memberGrade;

        uint32 u5Count;
        uint32 u6Count;

        uint32 state;
    }

    struct CMinerInfo{
        uint256 minerID;
        uint256 createDate;

        uint64 mechineCount;
        uint64 receiveAmount;
        uint32 state;

        uint256 lastReceiveDateDay;
        uint256 lastReceiveDateDayAtDay;

        uint256 lockToDate;
        uint32 lockToType;
    }

    struct CDayMechineInfo{
        uint256 dayMechineID;
        uint256 createDate;
        uint256 lastDeliveryDay;

        uint64 dayAmount_self;
        uint64 allAmount_self;
        uint64 lastAmount_self;

        uint64 dayAmount_sub;
        uint64 allAmount_sub;
        uint64 lastAmount_sub;

        uint64 fundSum_self;
        uint64 fundSum_sub;

        uint64 dayCalMaxLimit;
        uint64 currentDayCalOver;
    }

    struct CDayMechineDiscountInfo{
        uint256 discountID;
        uint64 dayCalCount;
        uint64 discountAmount;
        bool isOver;
    }
}