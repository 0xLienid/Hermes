// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

/// Import Packages
import {ERC20} from "solmate/tokens/ERC20.sol";

/// Import Interfaces
import {SingleSwap, FundManagement, IVault} from "src/interfaces/IVault.sol";

contract Hermes {
    /* ========== ERRORS =========== */

    error Hermes_InvalidParams();
    error Hermes_OnlyOwner();
    error Hermes_IllegalToken();

    /* ========== EVENTS =========== */

    event Paid(
        address indexed sender,
        address indexed recipient,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );

    /* ========== STATE VARIABLES =========== */

    /// Management Addresses
    address internal owner;

    /// External Contracts
    IVault internal vault;
    address internal poolId;

    /// User State
    mapping(address => address) public preferredToken;

    /// Management State
    uint256 feesCollected;

    /// Config Variables
    mapping(address => bool) public whitelistedTokens;
    uint16 internal feeRate;
    uint16 internal slippage;
    uint16 internal constant PRECISION_LEVEL = 10000;

    constructor(address owner_, address vault_, bytes32 poolId_) {
        if (owner_ == address(0) || vault_ == address(0))
            revert Hermes_InvalidParams();

        owner = owner_;
        vault = IVault(vault_);
        poolId = poolId_;

        (address[] memory tokens, , ) = vault.getPoolTokens(poolId_);
        uint8 tokensLength = tokens.length;
        for (uint8 i = 0; i < tokensLength; ) {
            whitelistedTokens[tokens[i]] = true;

            unchecked {
                i++;
            }
        }
    }

    /* ========== MODIFIERS =========== */

    modifier onlyOwner() {
        if (msg.sender != owner) revert Hermes_OnlyOwner();
        _;
    }

    /* ========== USER FUNCTIONS =========== */

    function pay(
        address recipient_,
        address token_,
        uint256 amount_
    ) external returns (bool) {
        if (!whitelistedTokens[token_]) revert Hermes_IllegalToken();

        address recipientPreferredToken = preferredToken[recipient_];

        uint256 feeAmount = (feeRate * amount_) / PRECISION_LEVEL;
        uint256 amount = amount_ - fee;
        feesCollected += feeAmount;

        if (token_ == recipientPreferredToken) {
            ERC20(token_).transferFrom(msg.sender, recipient_, amount);
            return true;
        }

        SingleSwap swapData = SingleSwap({
            poolId,
            SwapKind.GIVEN_IN,
            token_,
            recipientPreferredToken,
            amount,
            bytes(0)
        });

        FundManagement fundData = FundManagement({
            msg.sender,
            false,
            recipient_,
            false
        });

        vault.swap(swapData, fundData, minAmountOut, block.timestamp + 10 * 60);

        emit Paid(
            msg.sender,
            recipient_,
            token_,
            amount,
            recipientPreferredToken,
            resultingAmounts[1]
        );
        return true;
    }

    function setPreferredToken(address token_) external {
        if (!whitelistedTokens[token_]) revert Hermes_IllegalToken();
        preferredToken[msg.sender] = token_;
    }
}
