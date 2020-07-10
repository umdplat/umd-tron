pragma solidity ^0.4.24;

import "./CommonLib.sol";
import "./IERC20.sol";

contract CUmdMan {
    bool private isCheckManager=true;

    mapping(address => bool) private managerAccountDic;

    address private umdAddress=address(0x41d171831e6d36b0df74b410cd3e9187eb6300061e);  
    
    

    IERC20 private umdToken;

    constructor() public{
        managerAccountDic[msg.sender]=true;

        umdToken = IERC20(umdAddress);
    }

    function setManagerAccount(address xmanager, bool xisManager)public payable{
        require(managerAccountDic[msg.sender]);

        managerAccountDic[xmanager]=xisManager;

    }

    function checkManager()private constant{
        require(!isCheckManager || managerAccountDic[msg.sender], 'error0');
    }

    function transfer(address xaddr, uint64 xamount)public payable{
        checkManager();

        umdToken.transfer(xaddr, xamount);
    }
}
