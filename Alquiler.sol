pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "ERC/ERC1201.sol";


contract Alquiler is ERC721Full, Ownable, ERC1201 {

  // Cada id de alquiler se corresponde con un id de coche
  mapping(uint256 => uint256) public cocheIds;
  // Cada id de alquiler se corresponde con una hora de inicio de alquiler
  mapping(uint256 => uint256) public horasInicio;
  // Cada id de alquiler se corresponde con una hora de final de alquiler
  mapping(uint256 => uint256) public horasFinal;
  // Contador de numero de id de alquiler
  uint256 siguienteNumId;

  constructor() public ERC721Full("Alquiler", "ALQ") {
  }

  // Reserva un espacio de tiempo asociado a un token de coche y emite un token de alquiler
  function reservar(address _arrend, uint256 _cocheId, uint256 _ini, uint256 _fin)
  external onlyOwner() returns(uint256)
  {
    uint256 tokenId = siguienteNumId;
    siguienteNumId = siguienteNumId.add(1);
    // Llamada al contrato ERC721
    super._mint(_arrend, tokenId);
    // Actualiza los mapas con la informacion del token de alquiler recien creado
    cocheIds[tokenId] = _cocheId;
    horasInicio[tokenId] = _ini;
    horasFinal[tokenId] = _fin;
    // Emite el evento creacion par que sea registrado y retorna el numero de token
    emit Crear(_arrend, _cocheId, tokenId);
    return tokenId;
  }

  // Elimina del contrato un espacio de tiempo de alquiler asociado a un token de coche
  function cancelar(address _prop, uint256 _id)
  external onlyOwner()
  {
    // Llamada al contrato ERC721
    super._burn(_prop, _id);
    // Actualiza los mapas con la informacion del token de alquiler a eliminar
    uint256 cocheId = cocheIds[_id];
    delete cocheIds[_id];
    delete horasInicio[_id];
    delete horasFinal[_id];
    // Emite el evento creacion par que sea registrado
    emit Cancelar(_prop, cocheId, _id);
  }
}
