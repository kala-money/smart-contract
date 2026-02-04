# KALA Money: A Programmable Stable Asset
### Indexed to Real Purchasing Power

## Abstract
Conventional stablecoin protocols pegged to fiat currencies inherit systemic inflation risks and dependence on national monetary policies. This paper introduces **KALA Money**, a decentralized monetary protocol that redefines stability through:
1.  **Real Purchasing Power Index**
2.  **Hard Assets** (Gold and Silver)
3.  **Ethereum Blockspace Value**

KALA does not aim to maintain a nominal dollar value but rather preserves the user's absolute purchasing power.

---

## Introduction
KALA Money is a stablecoin protocol not pegged to the dollar or any national currency. Instead, it is pegged to a global index of real purchasing power, hard assets, and ETH blockspace value. 

> [!IMPORTANT]
> The price of KALA is **1:1 with the KALA Index**. 

This protocol addresses Vitalik Buterin’s critique regarding the fragility of traditional stablecoins by combining independent price indexing, anti-plutocratic governance, and the utilization of staking yields as collective security insurance.

---

## KALA Units (KALA)

### Mechanism
The value of 1 KALA reflects real purchasing power calculated based on a basket of on-chain assets and decentralized macroeconomic indicators.

### Objective
To avoid the systemic risk of fiat currencies. If the USD experiences inflation, the value of 1 KALA against the USD will adjust dynamically (e.g., becoming $1.05 USD) to preserve the value of user assets in the long term.

### Index Composition (The KALA Vision)
The target value is a weighted average of three core primitives:

| Component | Weight | Description |
| :--- | :--- | :--- |
| **Purchasing Power Index** | 40% | Real-world cost of living and purchasing power indicators. |
| **Hard Assets** | 40% | Long-term value stability (split 50/50 between Gold and Silver). |
| **ETH Blockspace Value** | 20% | Internal ecosystem relevance and network demand. |

---

## Staking Layer & Slashing Mechanism

### How to acquire KALA?
Users obtain KALA by staking ETH. Similar to liquid staking protocols, when users stake ETH, they receive KALA minted in proportion to the KALA index price. It resolves the conflict between ETH’s utility as collateral and the potential for staking yield.

- **Yield-Driven Stability**: ETH deposited as collateral enters a buffer fund and is staked by the protocol.
- **Cost Efficiency**: Users can mint KALA at **0% interest** because protocol operational costs are covered by the staking yield.
- **Slashing Bailout Mechanism**: All staking yield is allocated to the **Kala Save Buffer**. If a validator gets slashed, this reserve fund is automatically used to patch the user's collateral shortfall.

---

## Nodes
The protocol comprises two distinct node components:

1.  **Validator Node (Consensus Layer)**: Runs Ethereum staking infrastructure to generate staking yield as the protocol's economic fuel.
2.  **CRE (Chainlink Runtime Environment)**: Fetches and computes macroeconomic data off-chain. The resulting index price serves as the protocol’s authoritative price.

---

## Oracle Mechanism

### Genesis T0 (Time = 0)
At protocol launch, assets are priced at **1 KALA = 1 USD**.

**Simulation Base (T0):**
- **Base PPI**: 100
- **Base Gold**: $2,000
- **Base Silver**: $500
- **Base Gas**: 20 gwei

### Oracle Formula
The smart contract calculates the ratio of change for each asset against $T_0$:

$$P_{KALA} = (0.4 \times \frac{PPI_t}{PPI_0}) + (0.2 \times \frac{G_t}{G_0}) + (0.2 \times \frac{S_t}{S_0}) + (0.2 \times \frac{B_t}{B_0})$$

### Case Example (T1)
Lates Oracle Data:
- **PPI**: 105 (+5%)
- **Gold**: $2,100 (+5%)
- **Silver**: $525 (+5%)
- **Gas**: 40 gwei (+100%)

**New KALA Price:**
- PPI contribution: $0.4 \times 1.05 = 0.42$
- Gold contribution: $0.2 \times 1.05 = 0.21$
- Silver contribution: $0.2 \times 1.05 = 0.21$
- Gas contribution: $0.2 \times 2.0 = 0.40$
- **Final Price**: **$1.24 USD**

> [!NOTE]
> The user is protected from USD inflation and profits from exposure to network congestion, increasing their absolute purchasing power.

---

## Validation Collateral Ratio (VCR)

When a user deposits ETH, the system enforces a safe proportional minting limit:

$$Debt_{KALA} \times P_{KALA} \le \frac{ETH_{dep} \times P_{ETH}}{CR_{target}}$$

---

## Exit Strategy
A small portion (**10%**) of the ETH yield is directed to a **Liquidity Buffer** to:
1. Serve users who wish to redeem quickly.
2. Provide immediate exit liquidity while the main validator stake undergoes the unstaking period.

---

## KALA Stable Coin Collateral Ratio
KALA utilizes a **Dynamic Insurance Premium** model rather than a static over-collateralization model.

### Variable Components
The system monitors three real-time metrics:
- **Save Buffer Solvency Ratio (BSR)**: Ratio of Buffer ETH vs. Total KALA circulation.
- **Historical Volatility (V)**: 30-day ETH/KALA price deviation.
- **Liquidity Depth (L)**: Available DEX liquidity for potential liquidations.

### Automatic Target CR Formula
$$CR_{target} = Base_{CR} + f(V) + f(L) - f(BSR)$$

### Decision Matrix

| Buffer Condition | Volatility | Smart Contract Action | Technical Reason |
| :--- | :--- | :--- | :--- |
| **Deep** (BSR > 10%) | Low | **CR Decreases** (e.g. 120%) | High security allows for higher capital efficiency. |
| **Thin** (BSR < 2%) | Low | **Standard CR** (150%) | Protocol must build reserves; conservative stance. |
| **Deep** (BSR > 10%) | High | **Standard CR** (150%) | Buffer acts as a cushion against high volatility. |
| **Thin** (BSR < 2%) | High | **Very High CR** (180%) | Danger zone; requires maximum collateral spacing. |

---

## Scenarios: BSR Logic Simulation

### Base Assumptions
- **Base CR**: 150%
- **Total Debt**: 1,000,000 KALA
- **Staking Yield**: 4% APY

#### Scenario 1: Early Phase
- **Buffer Value**: 10,000 KALA (BSR 1%)
- **Logic**: No discount applied.
- **Target CR**: **150%**

#### Scenario 2: Mature Phase (1 KALA = $1.24)
- **Buffer Value**: $124,000 (BSR 10%)
- **Logic**: Healthy buffer grants a 20% discount.
- **Target CR**: **130%**

#### Scenario 3: Market Crash (ETH drops 30%)
- **BSR**: Drops to 7%.
- **Volatility**: Spikes (+30% Risk Premium).
- **Liquidity**: Thins (+10% Liquidity Premium).
- **Calculation**: $150\% + 30\% + 10\% - 10\% = 180\%$
- **Target CR**: **180%**

---

## Deployment & Infrastructure (Sepolia)

The protocol is currently deployed on the Ethereum Sepolia Testnet.

### Core Protocol
| Contract | Address |
| :--- | :--- |
| **KalaMoney** | `0xAF53484b277e9b7e9Fb224D2e534ee9beB68B7BA` |
| **CREngine** | `0x2B8C53A0cD2F537F6B30458E0702D5726595B845` |
| **BufferFund** | `0x8845B809be98396b5cf05dF93135B8dAe58F8CB8` |
| **SaveBuffer** | `0xc2BE3df42e3c53fe64648a03C04FB254fe17E340` |
| **Oracle** | `0x4FC13201489580c3F9Ac38c4916197BFf4c5c34c` |
| **Consumer** | `0xEb33A8FF1C2561EC48a62367a2C6379Ce75dEf2d` |

### External Feeds
- **ETH/USD Feed**: `0x694AA1769357215DE4FAC081bf1f309aDC325306`

---

## Uniswap v4 & Market Efficiency

KALA leverages Uniswap v4’s modular architecture to implement **Privacy-Enhancing Execution** and **Information Handling** via the `KalaHook`.

### Performance & Security Principles
1.  **Resilience to Adverse Selection**: The `KalaHook` implements a dynamic fee mechanism that increases costs during periods of high price deviation from the KALA Index. This protects LPs from toxic arbitrage and extractive MEV.
2.  **Privacy-Preserving Stability**: By enforcing alignment with the off-chain CRE-based index, the protocol reduces the "information exposure" of its internal state to external arbitrageurs, preserving the protocol's integrity without requiring complex ZK-proofs.
3.  **Execution Quality**: legitimate traders benefit from deeper liquidity as LPs (protocol stakers) are shielded from losses typical in static-fee pools.

### Technical Infrastructure (Sepolia)
| Component | TxID / Address |
| :--- | :--- |
| **KalaMoney (Deploy)** | [`0xe69e73ace33...`](https://sepolia.etherscan.io/tx/0xe69e73ace3398cc8b826301fc63f6f25d7ad947b9de3c6a7f558ddc9d18ebf11) |
| **KALA Hook (Deploy)** | [`0x2b7155f1b8b...`](https://sepolia.etherscan.io/tx/0x2b7155f1b8b8bbfee038cbdb7d69cf3589caec238a18806d5629a7d24f160f50) |
| **Pool Init** | [`0xd7e452e1115...`](https://sepolia.etherscan.io/tx/0xd7e452e1115f4f5379aa17d3d9f4d4c370597a88709f05259cc6e9df584442da) |
| **PoolManager** | `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543` |
| **KALA Token/Pool** | `0xAF53484b277e9b7e9Fb224D2e534ee9beB68B7BA` |

---

## Setup & Verification

To verify the protocol integrity and deploy locally:

1.  **Install Dependencies**:
    ```bash
    forge install
    ```
2.  **Build Contracts**:
    ```bash
    forge build
    ```
3.  **Run Tests**:
    ```bash
    forge test --fork-url $SEPOLIA_RPC
    ```

---

## Conclusion
KALA Money offers a new stablecoin paradigm that protects economic value from systemic inflation. By combining a **CRE-based price index**, a **yield-driven Save Buffer**, and an **adaptive collateral ratio**, the protocol creates a resilient on-chain monetary standard. 

The system does not merely mimic fiat stability; it builds stability based on real-world asset value and collective coordination.
