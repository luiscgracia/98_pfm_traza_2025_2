// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SupplyChainPro is ERC1155, AccessControl {
    using Counters for Counters.Counter;

    // Definición de Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant RETAILER_ROLE = keccak256("RETAILER_ROLE");

    Counters.Counter private _itemIds;

    struct Item {
        uint256 id;
        string name;
        address currentOwner;
        address pendingOwner;
        bool isFinishedProduct; // false = Materia Prima, true = Producto Terminado
        bool transitStatus;     // true si está esperando aceptación
        address[] history;      // Trazabilidad de movimientos
    }

    mapping(uint256 => Item) public items;

    event ItemCreated(uint256 indexed id, string name, address producer);
    event TransferProposed(uint256 indexed id, address indexed from, address indexed to);
    event TransferAccepted(uint256 indexed id, address indexed receiver);

    constructor() ERC1155("https://api.tuservidor.com/metadata/{id}.json") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // --- GESTIÓN DE ROLES (Aprobación del Admin) ---

    function approveRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    // --- CICLO DE VIDA DEL PRODUCTO ---

    // 1. El Productor tokeniza Materia Prima
    function produceRawMaterial(string memory _name, uint256 _amount) public onlyRole(PRODUCER_ROLE) {
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();

        _mint(msg.sender, newItemId, _amount, "");

        Item storage newItem = items[newItemId];
        newItem.id = newItemId;
        newItem.name = _name;
        newItem.currentOwner = msg.sender;
        newItem.isFinishedProduct = false;
        newItem.history.push(msg.sender);

        emit ItemCreated(newItemId, _name, msg.sender);
    }

    // 2. Propuesta de movimiento (Producer -> Factory, etc.)
    function proposeTransfer(uint256 _id, address _to) public {
        require(items[_id].currentOwner == msg.sender, "No eres el dueno");
        require(!items[_id].transitStatus, "Ya hay una transferencia en curso");

        items[_id].pendingOwner = _to;
        items[_id].transitStatus = true;

        emit TransferProposed(_id, msg.sender, _to);
    }

    // 3. Aceptación del receptor (Handshake)
    function acceptTransfer(uint256 _id) public {
        Item storage item = items[_id];
        require(msg.sender == item.pendingOwner, "No eres el receptor designado");
        require(item.transitStatus, "No hay transferencia pendiente");

        address oldOwner = item.currentOwner;

        // Ejecutar transferencia real del token
        _safeTransferFrom(oldOwner, msg.sender, _id, balanceOf(oldOwner, _id), "");

        // Actualizar estado del registro
        item.currentOwner = msg.sender;
        item.pendingOwner = address(0);
        item.transitStatus = false;
        item.history.push(msg.sender);

        emit TransferAccepted(_id, msg.sender);
    }

    // 4. Transformación: De Materia Prima a Producto Terminado (Solo Factory)
    function transformToProduct(uint256 _rawMaterialId) public onlyRole(FACTORY_ROLE) {
        Item storage item = items[_rawMaterialId];
        require(item.currentOwner == msg.sender, "No posees esta materia prima");
        require(!item.isFinishedProduct, "Ya es un producto terminado");

        item.isFinishedProduct = true;
        item.name = string(abi.encodePacked("Finished: ", item.name));
    }

    // --- TRAZABILIDAD ---

    function getFullHistory(uint256 _id) public view returns (address[] memory) {
        return items[_id].history;
    }

    // Función necesaria para recibir tokens ERC1155
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}