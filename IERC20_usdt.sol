pragma solidity ^0.4.24;

interface IERC20_usdt {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender)
    external view returns (uint256);
    function transfer(address _to, uint _value) external returns(bool);
    function approve(address _spender, uint _value) external returns(bool);
    function transferFrom(address _from, address _to, uint _value) external returns(bool);
    event Transfer(
    address indexed from,
    address indexed to,
        uint256 value
    );
    event Approval(
    address indexed owner,
    address indexed spender,
        uint256 value
    );
}