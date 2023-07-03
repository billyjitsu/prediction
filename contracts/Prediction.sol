// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@api3/contracts/v0.8/interfaces/IProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address holder) external returns (uint256);
}

contract Prediction is Ownable{
        
        uint256 constant PREDICTION_LENGTH = 7 days;
        uint256 constant PRICE_PREDICTION = 35000;  // 35,000 USD per BTC
        uint256 constant MIN_USDC = 35000e6;        //6 decimals  //Proxy Mumbai 0x8DF7d919Fe9e866259BB4D135922c5Bd96AF6A27
        uint256 constant MIN_WBTC = 1e8;            //8 decimals  //Proxy Mumbai 0x28Cac6604A8f2471E19c8863E8AfB163aB60186a
        uint256 public startBetTimestamp;

        address public proxyAddress;
        address public wbtcDepositor;
        address public usdcDepositor;

        bool public usdcDeposited;
        bool public wbtcDeposited;
        bool public betInitiated;

        mapping (address => uint256) public usdcDeposit;
        mapping (address => uint256) public wbtcDeposit;


        IERC20 USDC;
        IERC20 WBTC;

        constructor(address _proxyAddress, address _USDC, address _WBTC) {
            proxyAddress = _proxyAddress;
            USDC = IERC20(_USDC);
            WBTC = IERC20(_WBTC);
        }

        function setProxyAddress (address _proxyAddress) public onlyOwner {
            proxyAddress = _proxyAddress;
        }

        function depositWBTC(uint256 _amount)external{

            WBTC.transferFrom(msg.sender, address(this), _amount);
            wbtDeposited = true;
            wbtcDeposit[msg.sender] += _amount;
        }

        function depositUSDC(uint256 _amount)external{
            
            USDC.transferFrom(msg.sender, address(this), _amount);
            usdcDeposited = true;
            usdcDeposit[msg.sender] += _amount;
        }

        function closePrediction() external{
            require(betInitiated, "Bet not initiated");
            require(block.timestamp >= startBet + BET_LENGTH, "Bet not finished");
            require(readDataFeed() >= PRICE_PREDICTION, "Price not reached");

            betInitiated = false; // reset bet
            //verify price feed
            address winner;
            //decide winner
            uint256 usdcBalance = USDC.balanceOf(address(this));
            uint256 wbtcBalance = WBTC.balanceOf(address(this));
            USDC.transfer(winner, usdcBalance);
            WBTC.transfer(winner, wbtcBalance);
            //reset deposits
        }

        function returnFunds() external {
            require(betInitiated, "Bet not initiated");
            uint256 usdcBalance = USDC.balanceOf(address(this));
            uint256 wbtcBalance = WBTC.balanceOf(address(this));
            USDC.transfer(owner(), usdcBalance);
            WBTC.transfer(owner(), wbtcBalance);
        }


        function readDataFeed() external view returns (uint256, uint256){
            (int224 value, uint256 timestamp) = IProxy(proxyAddress).read();
            uint256 price = uint224(value);
            return price;
        }

}