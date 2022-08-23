// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

/// Import Packages
import {ERC20} from "solmate/tokens/ERC20.sol";

/// Import Interfaces
import {IUniswapV2Router} from "src/interfaces/IUniswapV2Router.sol";

contract Hermes {
    /* ========== ERRORS =========== */

    error Hermes_InvalidParams();
    error Hermes_OnlyOwner();

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
    IUniswapV2Router internal router;

    /// User State
    mapping(address => address) public preferredToken;

    /// Management State
    uint256 feesCollected;

    /// Config Variables
    uint16 internal feeRate;
    uint16 internal constant PRECISION_LEVEL = 10000;

    constructor(address owner_, address router_) {
        if (owner_ == address(0) || router_ == address(0))
            revert Hermes_InvalidParams();

        owner = owner_;
        router = IUniswapV2Router(router_);
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
        address recipientPreferredToken = preferredToken[recipient_];

        uint256 feeAmount = (feeRate * amount_) / PRECISION_LEVEL;
        uint256 amount = amount_ - fee;
        feesCollected += feeAmount;

        if (token_ == recipientPreferredToken) {
            ERC20(token_).transferFrom(msg.sender, recipient_, amount);
            return true;
        }

        /// TODO: Build path
        uint256[] memory resultingAmounts = router.swapExactTokensForTokens(
            amount,
            amountOutMin,
            path,
            recipient_,
            block.timestamp + 10 * 60
        );

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
}
