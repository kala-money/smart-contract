# Post-Mortem: Kala Workflow Transaction Reverts

## Executive Summary
Two distinct configuration failures caused the `report` workflow to revert on Sepolia. Both issues stemmed from mismatched address initialization in the `KalaConsumer` and `KalaOracle` contracts.

## Issue 1: Oracle Authorization Failure
**Symptom:**  
Transaction passed the Forwarder but reverted when `KalaConsumer` called `oracleContract.updatePriceData()`.  
**Error:** `Unauthorized()` (from `KalaOracle`).

**Root Cause:**  
The `KalaOracle` contract restricts state updates to a specific `oracle` address. This address was not set to the newly deployed `KalaConsumer`, causing the modifier `onlyOracle` to reject the call.

**Fix:**  
Explicitly authorized the Consumer on the Oracle contract.
```bash
cast send ... <Oracle_Address> "setOracle(address)" <Consumer_Address>
```

---

## Issue 2: Consumer Misconfiguration (Double Fault)
**Symptom:**  
Subsequent transactions reverted immediately upon entering `KalaConsumer`.  
**Error:** `InvalidSender` (inferred) and potential downstream call failure.

**Root Cause:**  
The `KalaConsumer` was deployed with incorrect constructor arguments or env variables, leading to two invalid state variables:
1.  **Forwarder Mismatch:** `s_forwarderAddress` was set to the **Oracle** address instead of the **Chainlink Forwarder**. The Consumer incorrectly rejected valid reports from the real Forwarder.
2.  **Oracle Target Mismatch:** `oracleContract` was set to an unknown/incorrect address (`0xF8344...`). Even if the checks passed, the Consumer would have failed to write data.

**Fix:**  
Corrected both addresses on the Consumer contract using `setForwarderAddress` and `setOracle`.

---

## Applied Solution (Commands)

### 1. Authorize Consumer on Oracle
```bash
cast send --rpc-url $SEPOLIA_RPC_URL $0x4FC13201489580c3F9Ac38c4916197BFf4c5c34c "setOracle(address)" $0xEb33A8FF1C2561EC48a62367a2C6379Ce75dEf2d
```

### 2. Fix Forwarder Address on Consumer
```bash

### 3. Fix Oracle Target on Consumer
```bash
cast send --rpc-url $SEPOLIA_RPC_URL --private-key $KALA_DEPLOYER_PK 0xEb33A8FF1C2561EC48a62367a2C6379Ce75dEf2d "setOracle(address)" 0x4FC13201489580c3F9Ac38c4916197BFf4c5c34c
```

2.  **Post-Deployment Verification:** Add a script step to verify `KalaConsumer.getForwarderAddress()` matches the documented Forwarder before running workflows.

# AFTER DEPLOYMENT DO THIS:
### Set the Correct Forwarder: (Authorizes 0x15fC6... to call onReport)

``` bash
cast send --rpc-url $SEPOLIA_RPC_URL \
  --private-key $KALA_DEPLOYER_PK \
  0xEb33A8FF1C2561EC48a62367a2C6379Ce75dEf2d \
  "setForwarderAddress(address)" \
  0x15fC6ae953E024d975e77382eEeC56A9101f9F88
```
Set the Correct Oracle: (Points Consumer to update data on 0x35C9...)

```bash
cast send --rpc-url $SEPOLIA_RPC_URL \
  --private-key $KALA_DEPLOYER_PK \
  0xEb33A8FF1C2561EC48a62367a2C6379Ce75dEf2d \
  "setOracle(address)" \
  0x4FC13201489580c3F9Ac38c4916197BFf4c5c34c
```