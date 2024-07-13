pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MUNI is ERC20 {
    // Mint 1 million mUNI for the smart contract creator
    constructor() ERC20("mUNI", "mUNI") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    // Let anyone mint 100_000 mUNI for free to try a swap
    function mint() external {
        _mint(msg.sender, 100_000 * 10 ** decimals());
    }
}