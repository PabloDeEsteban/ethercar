pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract ERC809 is ERC721 {
  function verArrendatario(uint256 _id, uint256 _hora) public view returns (address);
  function cocheDisponible(uint256 _id, uint256 _ini, uint256 _fin) public view returns (bool);
  function cancelar(uint256 _id, uint256 _alquilerId) public;
}
