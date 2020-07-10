pragma solidity ^0.4.24;

import "./CommonLib.sol";

contract CDayMechineDiscount{
    CommonLib.constDefs private consts;

    uint256 private discountID_self;
    uint256 private discountID_sub;

    mapping(uint256 => CommonLib.CDayMechineDiscountInfo) private allDiscount_self;
    mapping(uint256 => CommonLib.CDayMechineDiscountInfo) private allDiscount_sub;

    mapping(address => mapping(uint64 => uint256)) private allMemberDiscountInfo_self;

    mapping(address => mapping(uint64 => uint256)) private allMemberDiscountInfo_sub;

    bool private isCheckManager=true;

    mapping(address => bool) private managerAccountDic;

    constructor() public{
        managerAccountDic[msg.sender]=true;

        consts = CommonLib.constDefs({
            daySeconds: 0,
            rateTicketToBase: 0,
            dayCalPercentPerFund: 0
        });

        CommonLib.initConsts(consts);

        discountID_self = 1;
        discountID_sub = 1;
    }

    function setManagerAccount(address xmanager, bool xisManager)public payable{
        require(managerAccountDic[msg.sender]);

        managerAccountDic[xmanager]=xisManager;

    }

    function checkManager()private constant{
        require(!isCheckManager || managerAccountDic[msg.sender], 'error0');
    }

    function addDiscountInfo(address xaddr, uint64 xdayCalCount, uint64 xdiscountAmount, bool xisSelf)public payable
    returns(uint256 rdiscountID){
        checkManager();

        uint256 xid = getDiscountID(xaddr, xdayCalCount, xisSelf);

        if(xid<=0){
            CommonLib.CDayMechineDiscountInfo memory tmpInfo;

            if(xisSelf){
                tmpInfo = CommonLib.CDayMechineDiscountInfo({
                    discountID: discountID_self,
                    dayCalCount: xdayCalCount,
                    discountAmount: xdiscountAmount,
                    isOver: false
                });

                allDiscount_self[discountID_self] = tmpInfo;

                allMemberDiscountInfo_self[xaddr][xdayCalCount] = discountID_self;

                rdiscountID = discountID_self;
                discountID_self += 1;
            }
            else{
                tmpInfo = CommonLib.CDayMechineDiscountInfo({
                    discountID: discountID_sub,
                    dayCalCount: xdayCalCount,
                    discountAmount: xdiscountAmount,
                    isOver: false
                });

                allDiscount_sub[discountID_sub] = tmpInfo;

                allMemberDiscountInfo_sub[xaddr][xdayCalCount] = discountID_sub;

                rdiscountID = discountID_sub;
                discountID_sub += 1;
            }
        }
        else{
            if(xisSelf){
                require(allDiscount_self[xid].discountAmount+xdiscountAmount>allDiscount_self[xid].discountAmount, 'amount error');
            
                allDiscount_self[xid].discountAmount += xdiscountAmount;
            }
            else{
                require(allDiscount_sub[xid].discountAmount+xdiscountAmount>allDiscount_sub[xid].discountAmount, 'amount error');

                allDiscount_sub[xid].discountAmount += xdiscountAmount;
            }

            rdiscountID = xid;
        }

    }

    function getAllDiscountCount(bool xisSelf)public constant returns(uint256){
        checkManager();

        if(xisSelf)
            return discountID_self-1;
        else
            return discountID_sub-1;
    }

    function changeDiscountInfo(uint256 xid, uint64 xdayCalCount, uint64 xdiscountAmount, bool xisOver, bool xisSelf)public payable{
        checkManager();

        CommonLib.CDayMechineDiscountInfo storage xinfo;

        if(xisSelf){
            xinfo = allDiscount_self[xid];
        }
        else{
            xinfo = allDiscount_sub[xid];
        }

        require(xinfo.discountID>0, 'day error');

        xinfo.dayCalCount = xdayCalCount;
        xinfo.discountAmount = xdiscountAmount;
        xinfo.isOver = xisOver;
    }

    function changeDiscountState(uint256 xid, bool xisOver, bool xisSelf)public payable{
        checkManager();

        CommonLib.CDayMechineDiscountInfo storage xinfo;

        if(xisSelf){
            xinfo = allDiscount_self[xid];
        }
        else{
            xinfo = allDiscount_sub[xid];
        }
        

        require(xinfo.discountID>0, 'day error');

        xinfo.isOver = xisOver;
    }

    function getDiscountID(address xaddr, uint64 xdayCalCount, bool xisSelf)public constant returns(uint256 rdiscountID){
        checkManager();

        if(xisSelf)
            return allMemberDiscountInfo_self[xaddr][xdayCalCount];
        else
            return allMemberDiscountInfo_sub[xaddr][xdayCalCount];
    }

    function getDiscountInfo(uint256 xid, bool xisSelf)public constant
    returns(uint256 rdiscountID, uint64 rdayCalCount, uint64 rdiscountAmount, bool risOver){
        checkManager();

        CommonLib.CDayMechineDiscountInfo memory xinfo;
        
        if(xisSelf){
            xinfo = allDiscount_self[xid];
        }
        else{
            xinfo = allDiscount_sub[xid];
        }

        return(
            xinfo.discountID, xinfo.dayCalCount, xinfo.discountAmount, xinfo.isOver
            );
    }

    function getDiscountAmount(address xaddr, uint64 xdayCalCount)public constant
    returns(uint64 rdiscountAmount_self, uint64 rdiscountAmount_sub){
        checkManager();

        CommonLib.CDayMechineDiscountInfo memory xinfo;
        
        uint256 xid = getDiscountID(xaddr, xdayCalCount, true);

        if(xid>0){
            xinfo = allDiscount_self[xid];
            rdiscountAmount_self = xinfo.discountAmount;
        }
        
        xid = getDiscountID(xaddr, xdayCalCount, false);
            
        if(xid>0){
            xinfo = allDiscount_sub[xid];
            rdiscountAmount_sub = xinfo.discountAmount;
        }
            

        return(rdiscountAmount_self, rdiscountAmount_sub);
        
    }
}