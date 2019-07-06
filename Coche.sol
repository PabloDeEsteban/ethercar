pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "solidity-treemap/contracts/TreeMap.sol";
import "ERC/ERC809.sol";
import "./Alquiler.sol";

contract Coche is ERC721Full, ERC809 {
  
  using TreeMap for TreeMap.Map;
  // Cada id de coche se corresponde con un mapa que contiene hora_alquiler/id_alquiler
  mapping(uint256 => TreeMap.Map) internal mapaHoras;
  // Cada id de coche se corresponde su marca
  mapping (uint256 => string) public marcaCoche;
  // Direccion del contrato ERC1201 implementado en Alquiler
  address internal contratoAlquiler;

  constructor() public ERC721Full("Coche", "CAR") {
    contratoAlquiler = address(new Alquiler());
  }

  // Crea un nuevo token de coche asociado a la direccion del propietario
  function crearCoche(string memory _marca)
  public
  {
    // Comprueba que el string la variable _marca no este vacia
    require(keccak256(abi.encodePacked(_marca)) != keccak256(abi.encodePacked("")));
    marcaCoche[totalSupply()] = _marca;
    // Llamada al contrato ERC721
    super._mint(msg.sender, totalSupply());
  }

  // Para invocar esta funcion es necesario pagar 1 Gwei (1e9 wei) por cada hora
  function reservar1GweiHora(uint256 _id, uint256 _ini, uint256 _fin)
  public payable returns(uint256)
  {
    require(_exists(_id));
    if (!cocheDisponible(_id, _ini, _fin)) {
      revert("Coche no disponible");
    }
    // Comprueba la cantidad de ether enviada al contrato
    require(msg.value==(_fin-_ini)*1000000000, "La cantidad a transferir es de 1 Gwei por hora");
    // Obtiene la direccion del propietario del token coche que se quiere alquilar
    address payable propietario = address(uint160(ownerOf(_id)));
    // Transfiere al propietario del token la cantidad de Ether que se ha pagado
    propietario.transfer(msg.value);
    // Crea un token de alquiler asociado a la direccion del arrendatario
    Alquiler alquiler = Alquiler(contratoAlquiler);
    // Llamada al contrato ERC1201
    uint256 alquilerId = alquiler.reservar(msg.sender, _id, _ini, _fin);
    mapaHoras[_id].put(_ini, alquilerId);
    return alquilerId;
  }

  // Retorna un booleano en funcion de si el coche _id se encuentra disponible
  function cocheDisponible(uint256 _id, uint256 _ini, uint256 _fin)
  public view returns(bool)
  {
    require(_fin > _ini);
    bool existe;
    uint256 alquilerId;
    uint256 horaIni;
    // Retorna el par clave-valor igual o inmediatamente mayor que _ini
    (existe, horaIni, alquilerId) = mapaHoras[_id].ceilingEntry(_ini);
    // En el caso de que _ini coincida o la franja se solape retorna falso
    if (existe && _fin > horaIni) {
      return false;
    }
    // Retorna el par clave-valor igual o inmediantamente menor que _ini
    (existe, horaIni, alquilerId) = mapaHoras[_id].floorEntry(_ini);
    if (existe) {
      Alquiler alquiler = Alquiler(contratoAlquiler);
      // En el caso de que _ini coincida o la franja se solape retorna falso
      if (alquiler.horasFinal(alquilerId) > _ini) {
        return false;
      }
    }
    return true;
  }

  // Cancela la propiedad de un token alquiler asociado a un token coche
  function cancelar(uint256 _id, uint256 _alquilerId)
  public
  {
    require(_exists(_id));
    Alquiler alquiler = Alquiler(contratoAlquiler);
    uint256 horaIni = alquiler.horasInicio(_alquilerId);
    uint256 cocheId = alquiler.cocheIds(_alquilerId);
    if (cocheId != _id) {
      revert("El identificador es incorrecto");
    }
    // Llamada al contrato ERC1201
    alquiler.cancelar(msg.sender, _alquilerId);
    TreeMap.Map storage horasInicio = mapaHoras[_id];
    // Elimina la hora previamente reservada en el mapa
    horasInicio.remove(horaIni);
  }

  // Retorna la direccion del arrendatario del coche _id en la franja _hora
  function verArrendatario(uint256 _id, uint256 _hora)
  public view returns (address)
  {
    TreeMap.Map storage horasInicio = mapaHoras[_id];
    bool existe;
    uint256 horaIni;
    uint256 alquilerId;
    // Retorna el par clave-valor igual o inmediantamente menor que _hora
    (existe, horaIni, alquilerId) = horasInicio.floorEntry(_hora);
    if (existe) {
      Alquiler alquiler = Alquiler(contratoAlquiler);
      // Una vez obtenida la clave-valor se comprueba que _hora entra en el rango
      if (alquiler.horasFinal(alquilerId) >= _hora) {
        return alquiler.ownerOf(alquilerId);
      }
    }
  }

  // Destruye un token de coche existente si es invocada por su propietario
  function destruirCoche(uint256 _id)
  public
  {
    marcaCoche[_id] = "";
    // Llamada al contrato ERC721
    super._burn(msg.sender, _id);
  }
}
