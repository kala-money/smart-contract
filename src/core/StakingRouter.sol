// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BeaconChainDepositor} from "../integration/BeaconChainDepositor.sol";

interface IBufferFund {
    function getStakingBalance() external view returns (uint256);
    function requestETH(uint256 amount) external;
}

contract KalaStakingRouter is BeaconChainDepositor {
    struct ValidatorNode {
        bytes pubkey;
        bytes32 depositDataRoot;
        bytes signature;
        bool isUsed;
    }

    address public immutable KALA_MONEY;
    address public immutable BUFFER_FUND;
    address public immutable SAVE_BUFFER;

    ValidatorNode[] public validatorRegistry;
    uint256 public nextValidatorIndex;

    event ValidatorAdded(bytes pubkey);
    event DepositExecuted(bytes pubkey, uint256 index);

    modifier onlyKala() {
        require(msg.sender == KALA_MONEY, "Only KALA Money can trigger");
        _;
    }

    constructor(
        address _depositContract,
        address _kalaMoney,
        address _bufferFund,
        address _saveBuffer
    ) BeaconChainDepositor(_depositContract) {
        KALA_MONEY = _kalaMoney;
        BUFFER_FUND = _bufferFund;
        SAVE_BUFFER = _saveBuffer;
    }

    function addValidatorKeys(
        bytes calldata _pubkey,
        bytes32 _depositDataRoot,
        bytes calldata _signature
    ) external {
        validatorRegistry.push(
            ValidatorNode({
                pubkey: _pubkey,
                depositDataRoot: _depositDataRoot,
                signature: _signature,
                isUsed: false
            })
        );
        emit ValidatorAdded(_pubkey);
    }

    function getNextActiveValidator()
        public
        view
        returns (uint256 index, bytes memory pubkey)
    {
        for (
            uint256 i = nextValidatorIndex;
            i < validatorRegistry.length;
            i++
        ) {
            if (!validatorRegistry[i].isUsed) {
                return (i, validatorRegistry[i].pubkey);
            }
        }
        revert("No available validators");
    }

    function triggerDeposit() external onlyKala {
        uint256 bufferBalance = IBufferFund(BUFFER_FUND).getStakingBalance();
        require(bufferBalance >= 32 ether, "Insufficent ETH in Buffer");

        (uint256 idx, ) = getNextActiveValidator();
        ValidatorNode storage v = validatorRegistry[idx];

        IBufferFund(BUFFER_FUND).requestETH(32 ether);

        bytes memory withdrawalCredentials = _generateWithdrawalCredentials();

        _makeBeaconChainDeposits32ETH(
            1,
            withdrawalCredentials,
            v.pubkey,
            v.signature
        );

        v.isUsed = true;
        nextValidatorIndex = idx + 1;

        emit DepositExecuted(v.pubkey, idx);
    }

    function _generateWithdrawalCredentials()
        internal
        view
        returns (bytes memory)
    {
        return abi.encodePacked(bytes1(0x01), bytes11(0), SAVE_BUFFER);
    }
}
