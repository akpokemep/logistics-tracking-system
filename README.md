# ShipmentFlow - Decentralized Logistics Tracking

A Clarity smart contract for end-to-end shipment tracking and carrier management on the Stacks blockchain, providing transparency and accountability in logistics operations.

## Features

- **Carrier Management**: Register and rate logistics carriers
- **Shipment Creation**: Create shipments with origin, destination, and delivery estimates
- **Real-time Tracking**: Update shipment status with location checkpoints
- **Delay Detection**: Automatically identify delayed shipments
- **Audit Trail**: Immutable history of all shipment movements and status changes

## Contract Functions

### Public Functions
- `register-carrier(name, contact)` - Register a new logistics carrier
- `create-shipment(origin, destination, carrier-id, estimated-delivery, recipient)` - Create new shipment
- `update-shipment-status(shipment-id, status, location, notes)` - Update shipment progress
- `rate-carrier(carrier-id, rating)` - Rate carrier performance (1-10 scale)

### Read-only Functions
- `get-shipment(shipment-id)` - Get complete shipment details
- `get-carrier(carrier-id)` - Get carrier information and rating
- `is-shipment-delayed(shipment-id)` - Check if shipment is past due date

## Shipment Statuses

- `CREATED` - Shipment created, awaiting pickup
- `IN_TRANSIT` - Shipment en route to destination
- `DELIVERED` - Shipment successfully delivered
- `DELAYED` - Shipment experiencing delays
- `RETURNED` - Shipment returned to sender

## Usage

Register carriers first, then create shipments and track their progress through status updates. Each status change creates an immutable checkpoint for complete visibility.

## Development

Built with Clarity for the Stacks blockchain. Designed for integration with existing logistics systems and IoT tracking devices.