pragma solidity ^0.4.24;

import "./CommonLib.sol";

contract CMember{
    bool private isCheckManager=true;

    mapping(address => bool) private managerAccountDic;
    
    uint64 private memberInfoID;

    mapping(uint256=>CommonLib.memberInfo) private memberInfo;
    mapping(address=>uint256) private memberDic;

    address[] private allMemberAccount;

    address[] private allU5MemberList;
    address[] private allU6MemberList;
    address[] private allU7MemberList;

    mapping(address=>uint256[]) private ownMemberDic;

    constructor() public{
        memberInfoID=1;

        managerAccountDic[msg.sender]=true;
    }

    function setManagerAccount(address xmanager, bool xisManager)public payable{
        require(managerAccountDic[msg.sender]);

        managerAccountDic[xmanager]=xisManager;

    }

    function checkManager()private constant{
        require(!isCheckManager || managerAccountDic[msg.sender], 'error0');
    }

    function addU5Member(address xaddr)public payable returns(uint256 rcount){
        checkManager();

        allU5MemberList.push(xaddr);

        return allU5MemberList.length;
    }

    function getU5Members(uint256 xindex)public constant returns(address[20] raddrs){
        checkManager();

        uint256 xcur = xindex;
        uint256 xcount = 0;

        uint256 xlen = allU5MemberList.length;

        for(uint256 i = xcur; i<xlen; i++){
            raddrs[xcount] = allU5MemberList[i];

            xcount++;

            if(xcount>=raddrs.length)
                return;
        }
    }

    function getAllU5Count()public constant returns(uint256 rcount){
        checkManager();

        return allU5MemberList.length;
    }

    function addU6Member(address xaddr)public payable returns(uint256 rcount){
        checkManager();

        allU6MemberList.push(xaddr);

        return allU6MemberList.length;
    }

    function getU6Members(uint256 xindex)public constant returns(address[20] raddrs){
        checkManager();

        uint256 xcur = xindex;
        uint256 xcount = 0;

        uint256 xlen = allU6MemberList.length;

        for(uint256 i = xcur; i<xlen; i++){
            raddrs[xcount] = allU6MemberList[i];

            xcount++;

            if(xcount>=raddrs.length)
                return;
        }
    }

    function getAllU6Count()public constant returns(uint256 rcount){
        checkManager();

        return allU6MemberList.length;
    }

    function addU7Member(address xaddr)public payable returns(uint256 rcount){
        checkManager();

        allU7MemberList.push(xaddr);

        return allU7MemberList.length;
    }

    function getU7Members(uint256 xindex)public constant returns(address[20] raddrs){
        checkManager();

        uint256 xcur = xindex;
        uint256 xcount = 0;

        uint256 xlen = allU7MemberList.length;

        for(uint256 i = xcur; i<xlen; i++){
            raddrs[xcount] = allU7MemberList[i];

            xcount++;

            if(xcount>=raddrs.length)
                return;
        }
    }

    function getAllU7Count()public constant returns(uint256 rcount){
        checkManager();

        return allU7MemberList.length;
    }

    function createMember(address xcaller, address xparentAccount) public payable returns(bool risOK, address rparentAccount){
        checkManager();

        risOK = false;

        CommonLib.memberInfo memory tmpMember = memberInfo[memberDic[xcaller]];

        require(tmpMember.state==0);

        address xparentAddr = 0;

        if(xparentAccount!=0){
            xparentAddr = xparentAccount;

            CommonLib.memberInfo storage tmpParentInfo;

            address xtmpParent = xparentAddr;

            for(uint32 i = 1; i<=15; i++){
                tmpParentInfo = memberInfo[memberDic[xtmpParent]];

                if(i==1){
                    tmpParentInfo.directCount += 1;

                    ownMemberDic[xtmpParent].push(memberInfoID);

                    rparentAccount = tmpParentInfo.account;
                }
                else{
                    tmpParentInfo.gapCount += 1;
                }

                if(tmpParentInfo.parentAccount==xtmpParent)
                    break;

                xtmpParent = tmpParentInfo.parentAccount;
            }
        }

        tmpMember = CommonLib.memberInfo({
            account: xcaller,
            parentAccount: xparentAddr,
            directCount: 0,
            gapCount: 0,
            factDirectCount: 0,
            factGapCount: 0,
            dayCalCount: 0,
            memberGrade: 0,
            u5Count: 0,
            u6Count: 0,
            state: 1
        });

        memberInfo[memberInfoID] = tmpMember;
        memberDic[xcaller] = memberInfoID;

        allMemberAccount.push(xcaller);

        memberInfoID += 1;

        risOK = true;
    }

    function getMemberState(address xaddr)public constant returns(uint32){
        checkManager();

        CommonLib.memberInfo memory xmember=memberInfo[memberDic[xaddr]];

        return xmember.state;
    }

    function setMemberState(address xaddr, uint32 xstate)public payable{
        checkManager();

        CommonLib.memberInfo storage xmember=memberInfo[memberDic[xaddr]];

        xmember.state=xstate;
    }

    function changeU5Count(address xaddr, bool xisAdd, uint32 xqty)public payable 
    returns(uint32 ru5Count, uint32 rmemberGrade){
        checkManager();
        checkMemberState_exists(xaddr);

        CommonLib.memberInfo storage xmember = memberInfo[memberDic[xaddr]];

        CommonLib.checkCanAddOrSub(xisAdd, xmember.u5Count, xqty);

        if(xisAdd){
            xmember.u5Count += xqty;
        }
        else{
            xmember.u5Count -= xqty;
        }

        return (xmember.u5Count, xmember.memberGrade);
    }

    function getU5Count(address xaddr)public constant returns(uint32 ru5Count){
        checkManager();

        CommonLib.memberInfo memory xmember=memberInfo[memberDic[xaddr]];

        return xmember.u5Count;
    }

    function changeU6Count(address xaddr, bool xisAdd, uint32 xqty)public payable 
    returns(uint32 ru6count, uint32 rmemberGrade){
        checkManager();
        checkMemberState_exists(xaddr);

        CommonLib.memberInfo storage xmember = memberInfo[memberDic[xaddr]];

        CommonLib.checkCanAddOrSub(xisAdd, xmember.u6Count, xqty);

        if(xisAdd){
            xmember.u6Count += xqty;
        }
        else{
            xmember.u6Count -= xqty;
        }

        return (xmember.u6Count, xmember.memberGrade);
    }

    function getU6Count(address xaddr)public constant returns(uint32 ru6Count){
        checkManager();

        CommonLib.memberInfo memory xmember=memberInfo[memberDic[xaddr]];

        return xmember.u6Count;
    }

    function getMemberGrade(address xaddr)public constant returns(uint32 rgrade){
        checkManager();

        CommonLib.memberInfo memory xmember=memberInfo[memberDic[xaddr]];

        return xmember.memberGrade;

    }

    function upgradeMemberGrade(address xaddr, uint32 xneedGrade)public payable returns(bool risUpgraded){
        checkManager();
        checkMemberState_exists(xaddr);

        CommonLib.memberInfo storage xmember = memberInfo[memberDic[xaddr]];

        if(xmember.memberGrade < xneedGrade){
            xmember.memberGrade = xneedGrade;
            return(true);
        }

        return false;
    }

    function getOwnMemberIDs(address xaddr, uint256 xindex)public constant returns(uint256[20] rids){
        if(xaddr!=msg.sender)
            checkManager();

        uint256 xcur = xindex;
        uint256 xcount = 0;

        uint256 xlen = ownMemberDic[xaddr].length;

        for(uint256 i = xcur; i<xlen; i++){
            rids[xcount] = ownMemberDic[xaddr][i];

            xcount++;

            if(xcount>=rids.length)
                return;
        }
    }

    function checkMemberState_exists(address xaddr)public constant{
        checkManager();

        CommonLib.memberInfo memory tmpMember=memberInfo[memberDic[xaddr]];

        require(tmpMember.state>0);
    }

    function getAllMemberCount()public constant returns(uint256){
        checkManager();

        return allMemberAccount.length;
    }

    function getMemberIDByIndex(uint256 xindex)public constant returns(uint256 rmemberID){
        checkManager();

        rmemberID = memberDic[allMemberAccount[xindex]];
    }

    function getMemberAddress(uint256 xmemberID)public constant returns(address xaddr){
        checkManager();

        xaddr = memberInfo[xmemberID].account;
    }

    function getMemberInfo(address xaccount) public constant returns(
        bool risMemberExists, uint32 rstate, address rparentAccount, uint64 rdirectCount, uint64 rgapCount,
        uint64 rfactDirectCount, uint64 rfactGapCount
    ){
        if(xaccount!=msg.sender)
            checkManager();

        risMemberExists = false;

        CommonLib.memberInfo memory tmpMember = memberInfo[memberDic[xaccount]];

        require(tmpMember.state>0);

        risMemberExists = true;

        rstate = tmpMember.state;
        rparentAccount = tmpMember.parentAccount;
        rdirectCount = tmpMember.directCount;
        rgapCount = tmpMember.gapCount;
        rfactDirectCount = tmpMember.factDirectCount;
        rfactGapCount = tmpMember.factGapCount;

    }

    function getDirectCount(address xaccount)public constant returns(uint64 rdirectCount){
        checkManager();

        CommonLib.memberInfo memory tmpMember=memberInfo[memberDic[xaccount]];

        rdirectCount=tmpMember.directCount;

    }

    function getGapCount(address xaccount)public constant returns(uint64 rgapCount){
        checkManager();

        CommonLib.memberInfo memory tmpMember = memberInfo[memberDic[xaccount]];

        rgapCount = tmpMember.gapCount;

    }

    function getDayCalCount(address xaccount)public constant returns(uint64 rdayCalCount){
        checkManager();

        CommonLib.memberInfo memory tmpMember = memberInfo[memberDic[xaccount]];

        rdayCalCount = tmpMember.dayCalCount;

    }

    function changeDayCalCount(address xaccount, bool xisAdd, uint64 xcount)public payable
    returns(uint64 rnewDayCalCount){
        checkManager();

        CommonLib.memberInfo storage tmpMember=memberInfo[memberDic[xaccount]];

        require(tmpMember.state>0, 'state error');

        CommonLib.checkCanAddOrSub(xisAdd, tmpMember.dayCalCount, xcount);

        if(xisAdd){
            tmpMember.dayCalCount += xcount;
        }
        else{
            tmpMember.dayCalCount -= xcount;
        }

        return tmpMember.dayCalCount;
    }

    function getFactDirectCount(address xaccount)public constant returns(uint64 rdirectCount){
        checkManager();

        CommonLib.memberInfo memory tmpMember=memberInfo[memberDic[xaccount]];

        rdirectCount=tmpMember.factDirectCount;

    }

    function changeFactDirectCount(address xaccount, bool xisAdd, uint64 xcount)public payable{
        checkManager();

        CommonLib.memberInfo storage tmpMember=memberInfo[memberDic[xaccount]];

        require(tmpMember.state>0, 'state error');

        CommonLib.checkCanAddOrSub(xisAdd, tmpMember.factDirectCount, xcount);

        tmpMember.factDirectCount += xcount;

    }

    function getFactGapCount(address xaccount)public constant returns(uint64 rgapCount){
        checkManager();

        CommonLib.memberInfo memory tmpMember = memberInfo[memberDic[xaccount]];

        rgapCount = tmpMember.factGapCount;

    }

    function changeFactGapCount(address xaccount, bool xisAdd, uint64 xcount)public payable{
        checkManager();

        CommonLib.memberInfo storage tmpMember=memberInfo[memberDic[xaccount]];

        require(tmpMember.state>0, 'state error');

        CommonLib.checkCanAddOrSub(xisAdd, tmpMember.factGapCount, xcount);

        tmpMember.factGapCount += xcount;

    }

    function getParentAddr(address xaddr) public constant returns(address rparentAddr){
        checkManager();

        address xtmpAddr = memberInfo[memberDic[xaddr]].parentAccount;

        if(xaddr==xtmpAddr)
            return 0;

        return xtmpAddr;
    }
}