pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MUSDC is ERC20 {
    // Mint 1 million mUSDC for the smart contract creator
    constructor() ERC20("mUSDC", "mUSDC") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    // Let anyone mint 100_000 mUSDC for free to try a swap
    function mint() external {
        _mint(msg.sender, 100_000 * 10 ** decimals());
    }
}