// SPDX-License-Identifier: MIT
// Get funds from users.
// Withdraw funds.
// Set a minimum funding value on USD.

pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
// gas optimization -> use const and immutable where its needed.

error FundMe__NotOwner();

contract FundMe {
    
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;

    address[] public funders;
    mapping (address funders => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "You're not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }
    

    //-- What is a revert?
    //-- Undo any actions that have been done, and send the remaining gas back.
    //-- uint256 public myValue = 1;

    // sending funds through a function
    function fund() public payable {
        // Allow users to send $
        // Have a minimum $ sent

        //-- myValue = myValue + 2;
        
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough ETH"); // 1 ETH

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // for loop
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];

            addressToAmountFunded[funder] = 0;

        }

        // reset funders array
        funders = new address[](0);
        // withdraw the funds

        // 3 ways:
        // tranfer
        // payable(msg.sender).transfer(address(this).balance);
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

}