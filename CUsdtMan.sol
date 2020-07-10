pragma solidity ^0.4.24;

import "./CommonLib.sol";
import "./IERC20_usdt.sol";

contract CUsdtMan {
    bool private isCheckManager=true;

    mapping(address => bool) private managerAccountDic;

    address private usdtAddress=address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C);
    
    
    IERC20_usdt private usdtToken;

    constructor() public{
        managerAccountDic[msg.sender]=true;

        usdtToken = IERC20_usdt(usdtAddress);
    }

    function setManagerAccount(address xmanager, bool xisManager)public payable{
        require(managerAccountDic[msg.sender]);

        managerAccountDic[xmanager]=xisManager;

    }

    function checkManager()private constant{
        require(!isCheckManager || managerAccountDic[msg.sender], 'error0');
    }

    function memberFundIn(address xaddr, uint64 xamount)public payable{
        checkManager();

        usdtToken.transferFrom(xaddr, this, xamount);
    }

    function sendToMember(address xaddr, uint64 xamount)public payable{
        checkManager();

        usdtToken.transfer(xaddr, xamount);
    }
}
