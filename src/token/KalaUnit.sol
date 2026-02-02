// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ERC20Pausable
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract KalaUnit is ERC20, ERC20Pausable {
    address internal constant INITIAL_TOKEN_HOLDER =
        0x000000000000000000000000000000000000dEaD;

    uint256 internal constant UINT128_MAX = ~uint128(0);

    error SharesAmountMustBeGreaterThanZero();
    error SharesTooLarge();

    event TransferShares(
        address indexed from,
        address indexed to,
        uint256 sharesValue
    );

    constructor() ERC20("Kala Unit", "KALA") {}

    function mintShares(address recipient, uint256 sharesAmount) internal {
        if (sharesAmount == 0) {
            revert SharesAmountMustBeGreaterThanZero();
        }
        // Use internal _mint from ERC20 which tracks shares
        super._mint(recipient, sharesAmount);
    }

    function totalSupply() public view override returns (uint256) {
        return _getTotalPooledEther();
    }

    function getTotalShares() public view returns (uint256) {
        return super.totalSupply();
    }

    function getPooledEthByShares(
        uint256 _sharesAmount
    ) public view returns (uint256) {
        if (_sharesAmount == 0) {
            revert SharesAmountMustBeGreaterThanZero();
        }
        if (_sharesAmount >= UINT128_MAX) {
            revert SharesTooLarge();
        }
        uint256 _totalShares = getTotalShares();
        if (_totalShares == 0) return 0;

        return (_getTotalPooledEther() * _sharesAmount) / _totalShares;
    }

    function getSharesByPooledEth(
        uint256 _ethAmount
    ) public view returns (uint256) {
        uint256 totalPooledEth = _getTotalPooledEther();
        if (totalPooledEth == 0) return 0;

        uint256 _totalShares = getTotalShares();
        return (_ethAmount * _totalShares) / totalPooledEth;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 accountShares = super.balanceOf(account);
        if (accountShares == 0) return 0;
        return getPooledEthByShares(accountShares);
    }

    function sharesOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function _getTotalPooledEther() internal view virtual returns (uint256) {
        // Return the total shares as the default implementation
        // This provides a 1:1 ratio between shares and tokens
        return getTotalShares();
    }

    function _mintInitialShares(uint256 _sharesAmount) internal {
        super._mint(INITIAL_TOKEN_HOLDER, _sharesAmount);
        _emitTransferAfterMintingShares(INITIAL_TOKEN_HOLDER, _sharesAmount);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    function _emitTransferEvents(
        address _from,
        address _to,
        uint256 _pooledEtherAmount,
        uint256 _sharesAmount
    ) internal {
        emit Transfer(_from, _to, _pooledEtherAmount);
        emit TransferShares(_from, _to, _sharesAmount);
    }

    function _emitTransferAfterMintingShares(
        address _to,
        uint256 _sharesAmount
    ) internal {
        _emitTransferEvents(
            address(0),
            _to,
            getPooledEthByShares(_sharesAmount),
            _sharesAmount
        );
    }
}
