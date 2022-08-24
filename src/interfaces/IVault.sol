// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface IVault {
    function getPoolTokens(bytes32 poolId)
        external
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function swap(
        SingleSwap singleSwap,
        FundManagement funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);
}
