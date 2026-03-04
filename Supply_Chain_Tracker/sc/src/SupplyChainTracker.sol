// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    
    enum State { Created, InTransit, Received, Completed }
    enum Role { Producer, Factory, Retailer, Consumer }

    struct Product {
        uint256 id;
        string description;
        address currentOwner;
        address pendingOwner;
        Role currentStage;
        State state;
        address[] history; // Trazabilidad completa
    }

    mapping(uint256 => Product) public products;
    uint256 public productCount;

    event TransferInitiated(uint256 productId, address from, address to);
    event TransferAccepted(uint256 productId, address receiver, Role stage);

    // 1. El Productor crea el lote
    uint256 public constant TOTAL_STAGES = 4;

    function createProduct(string memory _description) public {
        productCount++;
        address[] memory _history = new address[](1);
        _history[0] = msg.sender;

        products[productCount] = Product({
            id: productCount,
            description: _description,
            currentOwner: msg.sender,
            pendingOwner: address(0),
            currentStage: Role.Producer,
            state: State.Created,
            history: _history
        });
    }

    // 2. Iniciar transferencia al siguiente eslabón
    function transferProduct(uint256 _productId, address _nextOwner) public {
        Product storage product = products[_productId];
        
        require(msg.sender == product.currentOwner, "No eres el poseedor actual");
        require(product.state != State.InTransit, "El producto ya esta en camino");
        require(product.currentStage != Role.Consumer, "El ciclo ya finalizo");

        product.pendingOwner = _nextOwner;
        product.state = State.InTransit;

        emit TransferInitiated(_productId, msg.sender, _nextOwner);
    }

    // 3. El receptor debe aceptar la transaccion para confirmar recepcion
    function acceptTransfer(uint256 _productId) public {
        Product storage product = products[_productId];

        require(msg.sender == product.pendingOwner, "No eres el receptor designado");
        require(product.state == State.InTransit, "No hay una transferencia pendiente");

        // Actualizar datos de posesión
        product.currentOwner = msg.sender;
        product.pendingOwner = address(0);
        product.state = State.Received;
        
        // Actualizar etapa automáticamente
        if (product.currentStage == Role.Producer) product.currentStage = Role.Factory;
        else if (product.currentStage == Role.Factory) product.currentStage = Role.Retailer;
        else if (product.currentStage == Role.Retailer) {
            product.currentStage = Role.Consumer;
            product.state = State.Completed;
        }

        // Registrar en el historial de trazabilidad
        product.history.push(msg.sender);

        emit TransferAccepted(_productId, msg.sender, product.currentStage);
    }

    // 4. Ver trazabilidad
    function getHistory(uint256 _productId) public view returns (address[] memory) {
        return products[_productId].history;
    }
}