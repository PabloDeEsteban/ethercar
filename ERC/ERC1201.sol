pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract ERC1201 is ERC721 {
  event Crear(address indexed _prop, uint256 _cocheId, uint256 _id);
  event Cancelar(address indexed _renter, uint256 _cocheId, uint256 _id);
}
