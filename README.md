# SupplyChainPro - Contrato Inteligente para Gestión de Cadena de Suministro

## Descripción General
SupplyChainPro es un contrato inteligente para Ethereum que implementa un sistema de gestión de cadena de suministro utilizando el estándar de token ERC1155. Este contrato permite rastrear y transferir productos a través de las diferentes etapas de la cadena de suministro, desde los productores hasta los consumidores.

## Características
- **Control de Acceso Basado en Roles**: Diferentes roles (Admin, Producer, Factory, Retailer, Consumidor) con permisos específicos.
- **Gestión del Ciclo de Vida del Producto**: Seguimiento de productos desde materias primas hasta productos terminados.
- **Sistema de Propuesta de Transferencia**: Transferencia segura de productos entre entidades.
- **Transformación de Productos**: Conversión de materias primas en productos terminados.
- **Compras de Consumidores**: Permite a los consumidores comprar productos terminados.
- **Rastreo Completo de Historial**: Mantenimiento de un historial completo de propiedad y transferencias de productos.

## Instalación
1. Clona este repositorio
2. Instala las dependencias: `npm install`
3. Compila el contrato: `npx hardhat compile`

## Uso

### Roles
- **Admin**: Puede otorgar roles a otras direcciones.
- **Producer**: Puede crear tokens de materias primas.
- **Factory**: Puede transformar materias primas en productos terminados.
- **Retailer**: Puede transferir productos entre entidades.
- **Consumer**: Puede comprar productos terminados.

### Funciones Principales
1. **produceRawMaterial**: Crear un nuevo token de materia prima.
2. **proposeTransfer**: Proponer una transferencia de un producto a otra dirección.
3. **acceptTransfer**: Aceptar una transferencia propuesta.
4. **rejectTransfer**: Rechazar una transferencia propuesta.
5. **transformToProduct**: Convertir materias primas en productos terminados.
6. **buyProduct**: Comprar un producto terminado.

## Flujo de Trabajo
1. Un productor crea materias primas: produceRawMaterial("Acero", 100);
2. El productor propone transferir las materias a una fábrica: proposeTransfer(1, direccionDeFabrica);
3. La fábrica acepta la transferencia: acceptTransfer(1);
4. La fábrica transforma las materias primas en un producto terminado: transformToProduct(1);
5. La fábrica propone transferir el producto terminado a un minorista: proposeTransfer(1, direccionDeMinorista);
6. El minorista acepta la transferencia: acceptTransfer(1);
7. Un consumidor compra el producto terminado: buyProduct(1);

Consideraciones de Seguridad
- Todas las transferencias están protegidas por un mecanismo de apretón de manos (propuesta/aceptación).
- Cada rol tiene permisos específicos para realizar ciertas acciones.
- El contrato mantiene un historial completo de todas las transferencias de productos.
- Licencia: Este proyecto está bajo la Licencia MIT.

