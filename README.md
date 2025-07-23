# 🚜 P2P Agricultural Equipment Lending

A decentralized peer-to-peer platform for agricultural equipment sharing built on the Stacks blockchain. Farmers can tokenize their tractors and tools for rental while earning passive income, and renters provide stake-backed incentives for timely returns.

## 🌾 Features

- **Equipment Tokenization**: Register tractors, harvesters, and tools as digital assets
- **Stake-Backed Rentals**: Renters provide collateral ensuring equipment return
- **Automated Payments**: Smart contract handles rental payments and stake management  
- **Overdue Protection**: Equipment owners can claim stakes if items aren't returned on time
- **Transparent Marketplace**: All transactions recorded on-chain for trust and accountability

## 🛠️ Contract Functions

### For Equipment Owners

#### `register-equipment`
Register new agricultural equipment for rental
```clarity
(register-equipment "John Deere Tractor" "2020 model, 100HP" u50 u200)
```
- `name`: Equipment name (max 50 chars)
- `description`: Equipment details (max 200 chars) 
- `daily-rate`: Daily rental cost in microSTX
- `stake-required`: Security deposit amount in microSTX

#### `claim-overdue-stake`
Claim stake when equipment isn't returned on time
```clarity
(claim-overdue-stake u1)
```

### For Renters

#### `rent-equipment`
Rent equipment by paying daily rate + stake
```clarity
(rent-equipment u1 u7)
```
- `equipment-id`: ID of equipment to rent
- `rental-days`: Number of days to rent

#### `return-equipment`
Return equipment and get stake back
```clarity
(return-equipment u1)
```

### Read-Only Functions

- `get-equipment`: View equipment details
- `get-rental`: View rental information
- `get-user-stake`: Check user's stake amount
- `is-rental-overdue`: Check if rental is past due date

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Setup
1. Clone this repository
2. Navigate to project directory
3. Run tests: `clarinet test`
4. Deploy locally: `clarinet console`

### Usage Example

1. **Register Equipment** 🚜
   ```clarity
   (contract-call? .P2P-Agricultural-Equipment-Lending register-equipment "Kubota Tractor" "25HP compact tractor" u30 u100)
   ```

2. **Rent Equipment** 💰
   ```clarity
   (contract-call? .P2P-Agricultural-Equipment-Lending rent-equipment u1 u5)
   ```

3. **Return Equipment** ✅
   ```clarity
   (contract-call? .P2P-Agricultural-Equipment-Lending return-equipment u1)
   ```

## 📊 How It Works

```
Owner registers equipment → Renter pays rate + stake → Equipment marked unavailable
                                      ↓
Renter returns on time ← Stake refunded ← Equipment marked available
                                      ↓
Equipment overdue → Owner claims stake → Equipment marked available
```

## 🔐 Security Features

- **Stake Protection**: Renters must provide collateral
- **Time-Based Returns**: Automated overdue detection
- **Owner Controls**: Only equipment owners can claim overdue stakes
- **Access Control**: Users can only return their own rentals

## 💡 Use Cases

- **Small Farmers**: Access expensive equipment without buying
- **Equipment Owners**: Monetize idle agricultural machinery
- **Seasonal Farming**: Rent specialized tools for specific crops
- **Rural Communities**: Share resources efficiently

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

---

*Built with ❤️ for the farming community on Stacks blockchain* 🌱
