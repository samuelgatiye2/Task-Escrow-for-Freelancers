# 💼 Task Escrow for Freelancers

> 🛡️ **Secure, Trustless Payment Protection** for the Freelance Economy

A Clarity smart contract that creates a trustless escrow system for freelancer-client relationships, ensuring fair payment protection for both parties through blockchain technology.

## 🌟 Features

- 💰 **Escrow Protection** - Client funds are securely held until task completion
- 🎯 **Milestone-Based Payments** - Support for phased project releases
- ⚖️ **Dispute Resolution** - Built-in mediation system for conflicts
- ⭐ **Rating System** - User reputation tracking for trust building
- 🔒 **Smart Contract Security** - Trustless, automated payment execution

## 🚀 Quick Start

### Creating a Task

```clarity
(contract-call? .Task-Escrow-for-Freelancers create-task
  'SP2FREELANCER123... ;; freelancer address
  "Website Development" ;; title
  "Build responsive React website" ;; description
  u1000000 ;; amount in microSTX
  u3 ;; number of milestones
  u1000 ;; deadline block height
)
```

### Approving Milestones

```clarity
(contract-call? .Task-Escrow-for-Freelancers approve-milestone
  u1 ;; task-id
  u1 ;; milestone-id
)
```

### Releasing Funds

```clarity
(contract-call? .Task-Escrow-for-Freelancers release-milestone-funds
  u1 ;; task-id
  u1 ;; milestone-id
)
```

## 📋 How It Works

### 1. 📝 Task Creation
- Client creates task with project details and deposits full payment + platform fee
- Funds are locked in smart contract escrow
- Project is divided into milestones for phased completion

### 2. 🎯 Milestone System
- Freelancer submits completed milestones
- Client reviews and approves milestone delivery
- Approved milestone funds are released to freelancer

### 3. 🔐 Security Features
- **Automatic Fund Release** - No manual intervention needed once approved
- **Cancellation Protection** - Clients can only cancel before work begins
- **Dispute Handling** - Contract owner can resolve conflicts

## 🛠️ Contract Functions

### Public Functions

| Function | Description | Who Can Call |
|----------|-------------|--------------|
| `create-task` | 📋 Create new escrow task | Anyone |
| `approve-milestone` | ✅ Approve milestone completion | Client only |
| `release-milestone-funds` | 💸 Release approved milestone payment | Anyone |
| `create-dispute` | ⚠️ Raise payment dispute | Task participants |
| `resolve-dispute` | ⚖️ Resolve disputes | Contract owner |
| `cancel-task` | ❌ Cancel task before work starts | Client only |
| `rate-user` | ⭐ Rate freelancer/client (1-5 stars) | Anyone |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-task` | 📖 Get task details |
| `get-milestone` | 🎯 Get milestone status |
| `get-user-rating` | ⭐ Get user's average rating |
| `get-contract-balance` | 💰 Check contract STX balance |

## 💡 Use Cases

### 🎨 **Creative Projects**
- Web design and development
- Logo and branding creation
- Content writing and copywriting

### 💻 **Technical Services**
- Smart contract development
- Mobile app creation
- API integrations

### 📊 **Business Services**
- Market research
- Business plan development
- Social media management

## 🔧 Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- [Node.js](https://nodejs.org/) (for testing)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd Task-Escrow-for-Freelancers

# Check contract syntax
clarinet check

# Run tests
npm install
npm test
```

## 📊 Platform Economics

- **Platform Fee**: 2.5% (250 basis points) of task value
- **Fee Collection**: Collected when task is completed successfully
- **Minimum Task Value**: 1 microSTX
- **Maximum Rating**: 5 stars

## 🛡️ Security Considerations

- ✅ **Reentrancy Protection** - Safe fund transfers
- ✅ **Access Control** - Function-level permissions
- ✅ **Input Validation** - Parameter sanitization
- ✅ **Error Handling** - Comprehensive error codes

## 🚨 Error Codes

| Code | Description |
|------|-------------|
| `u100` | Not authorized for this action |
| `u101` | Task not found |
| `u102` | Task already exists |
| `u103` | Invalid amount |
| `u104` | Task not active |
| `u105` | Task already completed |
| `u106` | Insufficient funds |
| `u107` | Invalid milestone |
| `u108` | Milestone already released |
| `u109` | Dispute already exists |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Guide](https://docs.stacks.co/clarity/)
- [Clarinet Testing Framework](https://github.com/hirosystems/clarinet)

---

*Built with ❤️ for the decentralized freelance economy*
