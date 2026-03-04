// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GlobalSupplyChain is ERC1155, AccessControl {
    
    // Definición de Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant RETAILER_ROLE = keccak256("RETAILER_ROLE");

    uint256 public itemCount;

    struct Item {
        uint256 id;
        string name;
        address currentOwner;
        address pendingOwner;
        bool isFinishedProduct; 
        bool inTransit;
        address[] history; // Trazabilidad completa
    }

    mapping(uint256 => Item) public items;

    event TransferProposed(uint256 indexed itemId, address from, address indexed to);
    event TransferAccepted(uint256 indexed itemId, address indexed receiver);

    constructor() ERC1155("https://api.tu-servidor.com/metadata/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // --- GESTIÓN DE ROLES ---
    // Solo el administrador puede autorizar nuevos participantes
    function authorizeParticipant(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    // --- CREACIÓN Y TOKENIZACIÓN ---
    function mintRawMaterial(string memory _name, uint256 _amount) public onlyRole(PRODUCER_ROLE) {
        itemCount++;
        _mint(msg.sender, itemCount, _amount, "");

        Item storage newItem = items[itemCount];
        newItem.id = itemCount;
        newItem.name = _name;
        newItem.currentOwner = msg.sender;
        newItem.isFinishedProduct = false;
        newItem.history.push(msg.sender);
    }

    // --- LÓGICA DE TRANSFERENCIA CON ACEPTACIÓN ---
    
    // El poseedor actual propone el envío
    function proposeTransfer(uint256 _itemId, address _to) public {
        Item storage item = items[_itemId];
        require(item.currentOwner == msg.sender, "No eres el dueno actual");
        require(!item.inTransit, "El producto ya esta en transito");

        item.pendingOwner = _to;
        item.inTransit = true;

        emit TransferProposed(_itemId, msg.sender, _to);
    }

    // El receptor debe aceptar para que el token se mueva realmente
    function acceptTransfer(uint256 _itemId) public {
        Item storage item = items[_itemId];
        require(msg.sender == item.pendingOwner, "No eres el receptor designado");
        require(item.inTransit, "No hay transferencia pendiente");

        address previousOwner = item.currentOwner;
        uint256 amount = balanceOf(previousOwner, _itemId);

        // Transferencia real del token ERC1155
        _safeTransferFrom(previousOwner, msg.sender, _itemId, amount, "");

        // Actualización de estado y trazabilidad
        item.currentOwner = msg.sender;
        item.pendingOwner = address(0);
        item.inTransit = false;
        item.history.push(msg.sender);

        emit TransferAccepted(_itemId, msg.sender);
    }

    // --- TRANSFORMACIÓN (Solo Fábrica) ---
    function transformToFinishedProduct(uint256 _itemId) public onlyRole(FACTORY_ROLE) {
        Item storage item = items[_itemId];
        require(item.currentOwner == msg.sender, "No posees la materia prima");
        require(!item.isFinishedProduct, "Ya es un producto terminado");

        item.isFinishedProduct = true;
        item.name = string(abi.encodePacked("PROD_FINAL: ", item.name));
    }

    // --- CONSULTA DE TRAZABILIDAD ---
    function getTraceability(uint256 _itemId) public view returns (address[] memory) {
        return items[_itemId].history;
    }

    // Boilerplate necesario para recibir ERC1155
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}