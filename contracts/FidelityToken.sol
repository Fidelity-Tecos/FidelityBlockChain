pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FidelityToken is ERC20, Ownable{
    constructor() ERC20("FidelityToken", "FT") public {
    _mint(msg.sender, 50000000 * 10 ** uint256(decimals()));
    }
}
