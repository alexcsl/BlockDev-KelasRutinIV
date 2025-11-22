# ZK Age Verifier

A privacy-preserving age verification system using Zero-Knowledge Proofs (ZK-SNARKs) built with Circom and Solidity. This application allows users to prove they are 18 years or older without revealing their actual birth date.

##  Features

- **Privacy-First**: Prove your age without revealing your exact birth date
- **Zero-Knowledge Proofs**: Uses Circom circuits and Groth16 proving system
- **Blockchain Integration**: Smart contract verification on EVM-compatible chains
- **Modern UI**: React + TypeScript + Vite with RainbowKit wallet integration
- **Commitment Scheme**: Prevents proof replay attacks using commitments

##  Architecture

### Components

1. **Circom Circuit** (`circuits/ageVerification.circom`)
   - Validates birth date is valid (day: 1-31, month: 1-12, year: 1900-2010)
   - Calculates age based on current date
   - Outputs: `isAdult` (0/1) and `commitment` (hash of birth data + salt)

2. **Smart Contract** (`contracts/AgeVerifier.sol`)
   - Verifies ZK proofs on-chain
   - Tracks verified addresses
   - Prevents replay attacks via commitment tracking

3. **Frontend Application** (`src/`)
   - React interface for proof generation
   - Wallet connection via RainbowKit
   - Real-time circuit and proof status

##  Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v18 or higher)
- **npm** or **yarn**
- **Circom** compiler
- **snarkjs** CLI tool
- **Git**

### Installing Circom

```bash
# Install Rust (required for Circom)
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

# Install Circom
git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
```

### Installing snarkjs

```bash
npm install -g snarkjs
```

##  Installation

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd zkAgeVerifier/zk-age-verification
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Compile the Circuit

The circuit files need to be compiled to generate the necessary proving and verification keys.

```bash
# Make the script executable (Linux/Mac)
chmod +x scripts/compile-circuit.sh

# Run the compilation script
npm run compile-circuit

# Or manually run the script
./scripts/compile-circuit.sh ageVerification
```

This will:
- Compile the Circom circuit to R1CS
- Generate witness generation files
- Download Powers of Tau ceremony files
- Generate proving and verification keys
- Copy files to the public directory

### 4. Generate Solidity Verifier

After compiling the circuit, generate the Solidity verifier contract:

```bash
cd circuits/build
snarkjs zkey export solidityverifier ageVerification_0001.zkey ../../contracts/verifier.sol
```

##  Usage

### Running the Development Server

```bash
npm run dev
```

The application will be available at `http://localhost:5173`

### Building for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

##  Smart Contract Deployment

### Prerequisites

- Install a blockchain development framework (Hardhat, Foundry, or Remix)
- Have testnet/mainnet ETH for gas fees
- Configure your wallet private key

### Using Hardhat

1. **Install Hardhat**:
```bash
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
```

2. **Initialize Hardhat**:
```bash
npx hardhat init
```

3. **Create deployment script** (`scripts/deploy.js`):
```javascript
const hre = require("hardhat");

async function main() {
  // Deploy the Groth16Verifier first
  const Verifier = await hre.ethers.getContractFactory("Groth16Verifier");
  const verifier = await Verifier.deploy();
  await verifier.waitForDeployment();
  const verifierAddress = await verifier.getAddress();
  
  console.log("Verifier deployed to:", verifierAddress);

  // Deploy AgeVerifier with the verifier address
  const AgeVerifier = await hre.ethers.getContractFactory("AgeVerifier");
  const ageVerifier = await AgeVerifier.deploy(verifierAddress);
  await ageVerifier.waitForDeployment();
  const ageVerifierAddress = await ageVerifier.getAddress();
  
  console.log("AgeVerifier deployed to:", ageVerifierAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

4. **Configure Hardhat** (`hardhat.config.js`):
```javascript
require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

module.exports = {
  solidity: "0.8.26",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
```

5. **Deploy**:
```bash
# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia

# Deploy to Polygon mainnet
npx hardhat run scripts/deploy.js --network polygon
```

### Using Remix IDE

1. Open [Remix IDE](https://remix.ethereum.org/)
2. Upload `contracts/verifier.sol` and `contracts/AgeVerifier.sol`
3. Compile both contracts (Solidity 0.8.26)
4. Deploy `Groth16Verifier` first
5. Copy the deployed verifier address
6. Deploy `AgeVerifier` with the verifier address as constructor parameter

### Environment Variables

Create a `.env` file in the root directory:

```env
# Blockchain RPC URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
POLYGON_RPC_URL=https://polygon-rpc.com

# Wallet Private Key (NEVER commit this!)
PRIVATE_KEY=your_private_key_here

# Contract Addresses (after deployment)
VITE_AGE_VERIFIER_ADDRESS=0x...
VITE_VERIFIER_ADDRESS=0x...

# Chain ID
VITE_CHAIN_ID=11155111  # Sepolia testnet
```

##  Configuration

Update the contract address in your frontend configuration:

**`src/config/chains.ts`** or **`src/constants/index.ts`**:

```typescript
export const AGE_VERIFIER_ADDRESS = '0xYourDeployedContractAddress';
```

##  How It Works

### User Flow

1. **Connect Wallet**: User connects their Web3 wallet using RainbowKit
2. **Input Birth Date**: User enters their birth date in the form
3. **Generate Proof**: 
   - Frontend generates a random salt
   - Creates inputs for the circuit
   - Computes the witness
   - Generates ZK proof locally (client-side)
4. **Submit Proof**: 
   - Proof is sent to the smart contract
   - Contract verifies the proof
   - If valid and user is 18, address is marked as verified
5. **Verification Status**: User's address is now verified on-chain

### Technical Flow

```
Birth Date + Salt  Circuit  Proof + Public Signals
                                
                         Smart Contract
                                
                    Verify Proof  Store Status
```

##  Testing

### Manual Testing

1. Enter a birth date that makes you 18+ years old
2. Generate and submit the proof
3. Check your verification status on the contract

### Test Cases

-  User born exactly 18 years ago
-  User born more than 18 years ago
-  User born less than 18 years ago
-  Invalid date inputs
-  Replay attack prevention

##  Project Structure

```
zk-age-verification/
 circuits/
    ageVerification.circom    # Main circuit
    build/                    # Compiled circuit artifacts
 contracts/
    AgeVerifier.sol          # Main contract
    verifier.sol             # Generated Groth16 verifier
 public/
    circuits/                # Circuit files for frontend
 scripts/
    compile-circuit.sh       # Circuit compilation script
    copy-circuit-files.sh    # File copying script
 src/
    components/              # React components
    hooks/                   # Custom React hooks
    lib/                     # ZK proof utilities
    types/                   # TypeScript types
    utils/                   # Helper functions
 package.json
```

##  Security Considerations

1. **Private Inputs**: Birth date and salt never leave the user's browser
2. **Commitment Scheme**: Prevents the same proof from being used twice
3. **Range Constraints**: Circuit validates date inputs are within valid ranges
4. **On-Chain Verification**: All proofs are verified on-chain before acceptance

##  Limitations

- Birth years are limited to 1900-2010 in the circuit
- Days are limited to 1-31 (doesn't validate month-specific day counts)
- Commitment scheme is simple and could be enhanced with Poseidon hash
- No revocation mechanism for verified status (except self-revoke)

##  Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

##  License

This project is licensed under the MIT License.

##  Resources

- [Circom Documentation](https://docs.circom.io/)
- [snarkjs Documentation](https://github.com/iden3/snarkjs)
- [ZK-SNARKs Introduction](https://z.cash/technology/zksnarks/)
- [Groth16 Paper](https://eprint.iacr.org/2016/260.pdf)

##  Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review the circuit code for proof generation details

##  Learn More

- [Zero-Knowledge Proofs Explained](https://blog.cryptographyengineering.com/2014/11/27/zero-knowledge-proofs-illustrated-primer/)
- [Circom Tutorial](https://docs.circom.io/getting-started/installation/)
- [Building dApps with ZK](https://ethereum.org/en/zero-knowledge-proofs/)

---

**Built with  using Circom, Solidity, and React**
