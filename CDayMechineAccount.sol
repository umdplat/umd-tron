pragma solidity ^0.4.24;

import "./CommonLib.sol";

contract CDayMechineAccount{
    CommonLib.constDefs private consts;

    uint256 private dayMechineID;

    mapping(uint256 => CommonLib.CDayMechineInfo) private allDayMechine;

    mapping(address => uint256) private allMemberOwnInfo;

    mapping(uint256 => uint64) private allMechineCountOfDay;

    mapping(address=>uint64) private selfReceiveSumDic;
    mapping(address=>uint64) private receiveSumFromOtherDic;

    mapping(address=>uint64) private receiveSumGlobal;

    
    struct CDayCalInfo{
        uint256 calDay;
        uint64 sum_self;
        uint64 sum_sub;
        uint64 sum_global;
    }

    mapping(uint256=>CDayCalInfo) private dayCalInfoDic;
    uint256 private dayCalInfoID;
    mapping(address=>uint256[]) private memberDayCalInfoIDs;

    bool private isCheckManager=true;

    mapping(address => bool)private managerAccountDic;

    constructor() public{
        managerAccountDic[msg.sender]=true;

        consts = CommonLib.constDefs({
            daySeconds: 0,
            rateTicketToBase: 0,
            dayCalPercentPerFund: 0
        });

        CommonLib.initConsts(consts);

        dayMechineID = 1;
        dayCalInfoID = 1;
    }

    function setManagerAccount(address xmanager, bool xisManager)public payable{
        require(managerAccountDic[msg.sender]);

        managerAccountDic[xmanager]=xisManager;

    }

    function checkManager()private constant{
        require(!isCheckManager || managerAccountDic[msg.sender], 'error0');
    }

    function addReceiveSum_day(address xaddr, uint256 xday, uint64 xself, uint64 xsub, uint64 xglobal)public payable{
        checkManager();

        CDayCalInfo memory xinfo = CDayCalInfo({
            calDay: xday,
            sum_self: xself,
            sum_sub: xsub,
            sum_global: xglobal
        });

        dayCalInfoDic[dayCalInfoID] = xinfo;
        memberDayCalInfoIDs[xaddr].push(dayCalInfoID);

        dayCalInfoID += 1;
    }

    function getReceiveSumInfoIDs(address xaddr, uint256 xindex)public constant returns(uint256[20] rids){
        checkManager();

        uint256 xcur = xindex;
        uint256 xcount = 0;

        uint256 xlen = memberDayCalInfoIDs[xaddr].length;

        for(uint256 i = xcur; i<xlen; i++){
            rids[xcount] = memberDayCalInfoIDs[xaddr][i];

            xcount++;

            if(xcount>=rids.length)
                return;
        }
    }

    function getDayCalInfo(uint256 xid) public constant returns(
        uint256 rcalDay, uint64 rsum_self, uint64 rsum_sub, uint64 rsum_global
    ){
        checkManager();

        CDayCalInfo memory xinfo = dayCalInfoDic[xid];
        
        rcalDay = xinfo.calDay;
        rsum_self = xinfo.sum_self;
        rsum_sub = xinfo.sum_sub;
        rsum_global = xinfo.sum_global;

    }

    function getFundSum(address xaddr)public constant returns(uint64 rsum_self, uint64 rsum_sub){
        checkManager();

        uint256 xid = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo memory xinfo = allDayMechine[xid];

        return (xinfo.fundSum_self, xinfo.fundSum_sub);
    }

    function getReceiveSum(address xaddr)public constant returns(uint256 rsum_self, uint256 rsum_sub){
        checkManager();

        rsum_self = selfReceiveSumDic[xaddr];
        rsum_sub = receiveSumFromOtherDic[xaddr];
    }

    function changeReceiveSum(address xaddr, bool xisAdd, uint64 xqty_self, uint64 xqty_sub)public payable{
        checkManager();

        if(xqty_self>0){
            CommonLib.checkCanAddOrSub(xisAdd, selfReceiveSumDic[xaddr], xqty_self);

            if(xisAdd){
                selfReceiveSumDic[xaddr] += xqty_self;
            }
            else{
                selfReceiveSumDic[xaddr] -= xqty_self;
            }
        }

        if(xqty_sub>0){
            CommonLib.checkCanAddOrSub(xisAdd, receiveSumFromOtherDic[xaddr], xqty_sub);

            if(xisAdd){
                receiveSumFromOtherDic[xaddr] += xqty_sub;
            }
            else{
                receiveSumFromOtherDic[xaddr] -= xqty_sub;
            }
        }
    }

    function getGlobalReceiveSum(address xaddr)public constant returns(uint256 rsum){
        checkManager();

        return receiveSumGlobal[xaddr];
    }

    function changeGlobalReceiveSum(address xaddr, bool xisAdd, uint64 xqty)public payable{
        checkManager();

        CommonLib.checkCanAddOrSub(xisAdd, receiveSumGlobal[xaddr], xqty);

        if(xisAdd){
            receiveSumGlobal[xaddr] += xqty;
        }
        else{
            receiveSumGlobal[xaddr] -= xqty;
        }
    }

    function createDayMechine(address xaddr)public payable returns(uint256 rdayMechineID)
    {
        rdayMechineID = 0;

        checkManager();

        uint256 xid = allMemberOwnInfo[xaddr];

        if(xid>0)
            return xid;

        CommonLib.CDayMechineInfo memory tmpInfo = CommonLib.CDayMechineInfo({
            dayMechineID: dayMechineID,
            createDate: block.timestamp,
            lastDeliveryDay: 0,

            dayAmount_self: 0,
            allAmount_self: 0,
            lastAmount_self: 0,

            dayAmount_sub: 0,
            allAmount_sub: 0,
            lastAmount_sub: 0,

            fundSum_self: 0,
            fundSum_sub: 0,

            dayCalMaxLimit: 0,
            currentDayCalOver: 0
        });

        allDayMechine[dayMechineID] = tmpInfo;

        allMemberOwnInfo[xaddr] = dayMechineID;

        rdayMechineID = dayMechineID;
        dayMechineID += 1;

    }

    function addDayCalSum(address xaddr, uint64 xmaxLimit, uint64 xover)public payable{
        checkManager();

        uint256 xdayMechineID = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo storage xinfo = allDayMechine[xdayMechineID];

        if(xmaxLimit>0){
            CommonLib.checkCanAddOrSub(true, xinfo.dayCalMaxLimit, xmaxLimit);

            xinfo.dayCalMaxLimit += xmaxLimit;
        }
        
        if(xover>0){
            CommonLib.checkCanAddOrSub(true, xinfo.currentDayCalOver, xover);

            xinfo.currentDayCalOver += xover;
        }

    }

    function getDayCalLimit(address xaddr)public constant
    returns(uint64 rmaxLimit, uint64 rover){
        checkManager();

        uint256 xdayMechineID = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo memory xinfo = allDayMechine[xdayMechineID];

        return(xinfo.dayCalMaxLimit, xinfo.currentDayCalOver);
    }

    function fundDayMechine(address xaddr, uint64 xdayAmount, uint64 xallAmount, uint64 xallProfitAmount, bool xisSelf)public payable{
        checkManager();

        uint256 xid = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo storage xinfo = allDayMechine[xid];

        if(xisSelf){
            if(xinfo.lastDeliveryDay==0){  
                xinfo.lastDeliveryDay = block.timestamp/consts.daySeconds;
            }

            CommonLib.checkCanAddOrSub(true, xinfo.dayAmount_self, xdayAmount);
            CommonLib.checkCanAddOrSub(true, xinfo.allAmount_self, xallProfitAmount);

            xinfo.dayAmount_self += xdayAmount;
            xinfo.allAmount_self += xallProfitAmount;

            changeMemberLastAmount(xaddr, true, xallProfitAmount, xisSelf);

            changeFundSum(xaddr, true, xallAmount, true);
        }
        else{
            CommonLib.checkCanAddOrSub(true, xinfo.dayAmount_sub, xdayAmount);
            CommonLib.checkCanAddOrSub(true, xinfo.allAmount_sub, xallProfitAmount);

            xinfo.dayAmount_sub += xdayAmount;
            xinfo.allAmount_sub += xallProfitAmount;

            changeMemberLastAmount(xaddr, true, xallProfitAmount, xisSelf);

            changeFundSum(xaddr, true, xallAmount, false);
        }

    }

    function changeFundSum(address xaddr, bool xisAdd, uint64 xqty, bool xisSelf)public payable{
        checkManager();

        uint256 xid = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo storage xinfo = allDayMechine[xid];

        if(xisSelf){
            CommonLib.checkCanAddOrSub(xisAdd, xinfo.fundSum_self, xqty);

            if(xisAdd){
                xinfo.fundSum_self += xqty;
            }
            else{
                xinfo.fundSum_self -= xqty;
            }
        }
        else{
            CommonLib.checkCanAddOrSub(xisAdd, xinfo.fundSum_sub, xqty);

            if(xisAdd){
                xinfo.fundSum_sub += xqty;
            }
            else{
                xinfo.fundSum_sub -= xqty;
            }
        }
    }

    function changeDayAmount(address xaddr, bool xisAdd, uint64 xqty, bool xisSelf)public payable{
        checkManager();

        uint256 xid = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo storage xinfo = allDayMechine[xid];

        if(xisSelf){
            CommonLib.checkCanAddOrSub(xisAdd, xinfo.dayAmount_self, xqty);

            if(xisAdd){
                xinfo.dayAmount_self += xqty;
            }
            else{
                xinfo.dayAmount_self -= xqty;
            }
        }
        else{
            CommonLib.checkCanAddOrSub(xisAdd, xinfo.dayAmount_sub, xqty);

            if(xisAdd){
                xinfo.dayAmount_sub += xqty;
            }
            else{
                xinfo.dayAmount_sub -= xqty;
            }
        }
    }

    function changeMemberLastAmount(address xaddr, bool xisAdd, uint64 xqty, bool xisSelf)public payable{
        checkManager();

        uint256 xid = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo storage xinfo = allDayMechine[xid];

        if(xisSelf){
            CommonLib.checkCanAddOrSub(xisAdd, xinfo.lastAmount_self, xqty);

            if(xisAdd){
                xinfo.lastAmount_self += xqty;
            }
            else{
                xinfo.lastAmount_self -= xqty;
            }
        }
        else{
            CommonLib.checkCanAddOrSub(xisAdd, xinfo.lastAmount_sub, xqty);

            if(xisAdd){
                xinfo.lastAmount_sub += xqty;
            }
            else{
                xinfo.lastAmount_sub -= xqty;
            }
        }
    }

    function checkDayMechineExists(address xaddr)public constant returns(uint256 rid){
        uint256 xid = allMemberOwnInfo[xaddr];

        require(xid>0, 'id error');

        CommonLib.CDayMechineInfo memory xinfo = allDayMechine[xid];

        require(xinfo.dayMechineID>0, 'mechine info error');

        rid = xinfo.dayMechineID;

        return(rid);
    }

    function changeLastDeliveryDay(address xaddr, uint256 xnewDate_day)public payable{
        checkManager();

        uint256 xdayMechineID = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo storage xinfo = allDayMechine[xdayMechineID];

        xinfo.lastDeliveryDay = xnewDate_day;

    }

    function checkDayCalDay(address xaddr, uint256 xcalDate_day)public constant{
        checkManager();

        uint256 xdayMechineID = checkDayMechineExists(xaddr);
        
        CommonLib.CDayMechineInfo memory xinfo = allDayMechine[xdayMechineID];

        require(xinfo.lastDeliveryDay>0 && xcalDate_day>xinfo.lastDeliveryDay,'day error');
    }

    function getDeliveryAmountAtDay(address xaddr, uint256 xcalDate_day)public constant
    returns(uint64 rselfAmount, uint64 rsubAmount){
        checkManager();

        uint256 xdayMechineID = checkDayMechineExists(xaddr);

        CommonLib.CDayMechineInfo memory xinfo = allDayMechine[xdayMechineID];

        if(xinfo.lastDeliveryDay>=xcalDate_day)
            return(0,0);

        if(xinfo.lastAmount_self<xinfo.dayAmount_self)
            rselfAmount = xinfo.lastAmount_self;
        else
            rselfAmount = xinfo.dayAmount_self;

        if(xinfo.lastAmount_sub<xinfo.dayAmount_sub)
            rsubAmount = xinfo.lastAmount_sub;
        else
            rsubAmount = xinfo.dayAmount_sub;

        return (rselfAmount, rsubAmount);
    }

    function getAllDayMechineCount()public constant returns(uint256){
        checkManager();

        return dayMechineID-1;
    }

    function getDayMechineID(address xaddr)public constant returns(uint256 rid){
        checkManager();

        return (allMemberOwnInfo[xaddr]);
    }

    function getDayMechineInfo(uint256 xid)public constant returns(
            uint256 rdayMechineID, uint256 rcreateDate, uint256 rlastDeliveryDay,
            uint64 rdayAmount_self, uint64 rallAmount_self, uint64 rlastAmount_self,
            uint64 rdayAmount_sub, uint64 rallAmount_sub, uint64 rlastAmount_sub
            ){
        checkManager();

        CommonLib.CDayMechineInfo memory xinfo = allDayMechine[xid];

        return(
            xinfo.dayMechineID, xinfo.createDate, xinfo.lastDeliveryDay,
            xinfo.dayAmount_self, xinfo.allAmount_self, xinfo.lastAmount_self,
            xinfo.dayAmount_sub, xinfo.allAmount_sub, xinfo.lastAmount_sub
            );
    }


}