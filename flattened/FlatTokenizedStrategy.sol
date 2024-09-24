    // SPDX-License-Identifier: AGPL-3.0
    pragma solidity >=0.8.18 ^0.8.0 ^0.8.1;

    // lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

    // OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

    /**
    * @dev Interface of the ERC20 standard as defined in the EIP.
    */
    interface IERC20 {
        /**
        * @dev Emitted when `value` tokens are moved from one account (`from`) to
        * another (`to`).
        *
        * Note that `value` may be zero.
        */
        event Transfer(address indexed from, address indexed to, uint256 value);

        /**
        * @dev Emitted when the allowance of a `spender` for an `owner` is set by
        * a call to {approve}. `value` is the new allowance.
        */
        event Approval(address indexed owner, address indexed spender, uint256 value);

        /**
        * @dev Returns the amount of tokens in existence.
        */
        function totalSupply() external view returns (uint256);

        /**
        * @dev Returns the amount of tokens owned by `account`.
        */
        function balanceOf(address account) external view returns (uint256);

        /**
        * @dev Moves `amount` tokens from the caller's account to `to`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transfer(address to, uint256 amount) external returns (bool);

        /**
        * @dev Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        *
        * This value changes when {approve} or {transferFrom} are called.
        */
        function allowance(address owner, address spender) external view returns (uint256);

        /**
        * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * IMPORTANT: Beware that changing an allowance with this method brings the risk
        * that someone may use both the old and the new allowance by unfortunate
        * transaction ordering. One possible solution to mitigate this race
        * condition is to first reduce the spender's allowance to 0 and set the
        * desired value afterwards:
        * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        *
        * Emits an {Approval} event.
        */
        function approve(address spender, uint256 amount) external returns (bool);

        /**
        * @dev Moves `amount` tokens from `from` to `to` using the
        * allowance mechanism. `amount` is then deducted from the caller's
        * allowance.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
    }

    // lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

    // OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

    /**
    * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
    * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
    *
    * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
    * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
    * need to send a transaction, and thus is not required to hold Ether at all.
    *
    * ==== Security Considerations
    *
    * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
    * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
    * considered as an intention to spend the allowance in any specific way. The second is that because permits have
    * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
    * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
    * generally recommended is:
    *
    * ```solidity
    * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
    *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
    *     doThing(..., value);
    * }
    *
    * function doThing(..., uint256 value) public {
    *     token.safeTransferFrom(msg.sender, address(this), value);
    *     ...
    * }
    * ```
    *
    * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
    * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
    * {SafeERC20-safeTransferFrom}).
    *
    * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
    * contracts should have entry points that don't rely on permit.
    */
    interface IERC20Permit {
        /**
        * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
        * given ``owner``'s signed approval.
        *
        * IMPORTANT: The same issues {IERC20-approve} has related to transaction
        * ordering also apply here.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        * - `deadline` must be a timestamp in the future.
        * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
        * over the EIP712-formatted function arguments.
        * - the signature must use ``owner``'s current nonce (see {nonces}).
        *
        * For more information on the signature format, see the
        * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
        * section].
        *
        * CAUTION: See Security Considerations above.
        */
        function permit(
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external;

        /**
        * @dev Returns the current nonce for `owner`. This value must be
        * included whenever a signature is generated for {permit}.
        *
        * Every successful call to {permit} increases ``owner``'s nonce by one. This
        * prevents a signature from being used multiple times.
        */
        function nonces(address owner) external view returns (uint256);

        /**
        * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
        */
        // solhint-disable-next-line func-name-mixedcase
        function DOMAIN_SEPARATOR() external view returns (bytes32);
    }

    // lib/openzeppelin-contracts/contracts/utils/Address.sol

    // OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

    /**
    * @dev Collection of functions related to the address type
    */
    library Address {
        /**
        * @dev Returns true if `account` is a contract.
        *
        * [IMPORTANT]
        * ====
        * It is unsafe to assume that an address for which this function returns
        * false is an externally-owned account (EOA) and not a contract.
        *
        * Among others, `isContract` will return false for the following
        * types of addresses:
        *
        *  - an externally-owned account
        *  - a contract in construction
        *  - an address where a contract will be created
        *  - an address where a contract lived, but was destroyed
        *
        * Furthermore, `isContract` will also return true if the target contract within
        * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
        * which only has an effect at the end of a transaction.
        * ====
        *
        * [IMPORTANT]
        * ====
        * You shouldn't rely on `isContract` to protect against flash loan attacks!
        *
        * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
        * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
        * constructor.
        * ====
        */
        function isContract(address account) internal view returns (bool) {
            // This method relies on extcodesize/address.code.length, which returns 0
            // for contracts in construction, since the code is only stored at the end
            // of the constructor execution.

            return account.code.length > 0;
        }

        /**
        * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
        * `recipient`, forwarding all available gas and reverting on errors.
        *
        * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
        * of certain opcodes, possibly making contracts go over the 2300 gas limit
        * imposed by `transfer`, making them unable to receive funds via
        * `transfer`. {sendValue} removes this limitation.
        *
        * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
        *
        * IMPORTANT: because control is transferred to `recipient`, care must be
        * taken to not create reentrancy vulnerabilities. Consider using
        * {ReentrancyGuard} or the
        * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
        */
        function sendValue(address payable recipient, uint256 amount) internal {
            require(address(this).balance >= amount, "Address: insufficient balance");

            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }

        /**
        * @dev Performs a Solidity function call using a low level `call`. A
        * plain `call` is an unsafe replacement for a function call: use this
        * function instead.
        *
        * If `target` reverts with a revert reason, it is bubbled up by this
        * function (like regular Solidity function calls).
        *
        * Returns the raw returned data. To convert to the expected return value,
        * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
        *
        * Requirements:
        *
        * - `target` must be a contract.
        * - calling `target` with `data` must not revert.
        *
        * _Available since v3.1._
        */
        function functionCall(address target, bytes memory data) internal returns (bytes memory) {
            return functionCallWithValue(target, data, 0, "Address: low-level call failed");
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
        * `errorMessage` as a fallback revert reason when `target` reverts.
        *
        * _Available since v3.1._
        */
        function functionCall(
            address target,
            bytes memory data,
            string memory errorMessage
        ) internal returns (bytes memory) {
            return functionCallWithValue(target, data, 0, errorMessage);
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
        * but also transferring `value` wei to `target`.
        *
        * Requirements:
        *
        * - the calling contract must have an ETH balance of at least `value`.
        * - the called Solidity function must be `payable`.
        *
        * _Available since v3.1._
        */
        function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
            return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        }

        /**
        * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
        * with `errorMessage` as a fallback revert reason when `target` reverts.
        *
        * _Available since v3.1._
        */
        function functionCallWithValue(
            address target,
            bytes memory data,
            uint256 value,
            string memory errorMessage
        ) internal returns (bytes memory) {
            require(address(this).balance >= value, "Address: insufficient balance for call");
            (bool success, bytes memory returndata) = target.call{value: value}(data);
            return verifyCallResultFromTarget(target, success, returndata, errorMessage);
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
        * but performing a static call.
        *
        * _Available since v3.3._
        */
        function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
            return functionStaticCall(target, data, "Address: low-level static call failed");
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
        * but performing a static call.
        *
        * _Available since v3.3._
        */
        function functionStaticCall(
            address target,
            bytes memory data,
            string memory errorMessage
        ) internal view returns (bytes memory) {
            (bool success, bytes memory returndata) = target.staticcall(data);
            return verifyCallResultFromTarget(target, success, returndata, errorMessage);
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
        * but performing a delegate call.
        *
        * _Available since v3.4._
        */
        function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
            return functionDelegateCall(target, data, "Address: low-level delegate call failed");
        }

        /**
        * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
        * but performing a delegate call.
        *
        * _Available since v3.4._
        */
        function functionDelegateCall(
            address target,
            bytes memory data,
            string memory errorMessage
        ) internal returns (bytes memory) {
            (bool success, bytes memory returndata) = target.delegatecall(data);
            return verifyCallResultFromTarget(target, success, returndata, errorMessage);
        }

        /**
        * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
        * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
        *
        * _Available since v4.8._
        */
        function verifyCallResultFromTarget(
            address target,
            bool success,
            bytes memory returndata,
            string memory errorMessage
        ) internal view returns (bytes memory) {
            if (success) {
                if (returndata.length == 0) {
                    // only check isContract if the call was successful and the return data is empty
                    // otherwise we already know that it was a contract
                    require(isContract(target), "Address: call to non-contract");
                }
                return returndata;
            } else {
                _revert(returndata, errorMessage);
            }
        }

        /**
        * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
        * revert reason or using the provided one.
        *
        * _Available since v4.3._
        */
        function verifyCallResult(
            bool success,
            bytes memory returndata,
            string memory errorMessage
        ) internal pure returns (bytes memory) {
            if (success) {
                return returndata;
            } else {
                _revert(returndata, errorMessage);
            }
        }

        function _revert(bytes memory returndata, string memory errorMessage) private pure {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    // lib/openzeppelin-contracts/contracts/utils/Context.sol

    // OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

    /**
    * @dev Provides information about the current execution context, including the
    * sender of the transaction and its data. While these are generally available
    * via msg.sender and msg.data, they should not be accessed in such a direct
    * manner, since when dealing with meta-transactions the account sending and
    * paying for execution may not be the actual sender (as far as an application
    * is concerned).
    *
    * This contract is only required for intermediate, library-like contracts.
    */
    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }

        function _contextSuffixLength() internal view virtual returns (uint256) {
            return 0;
        }
    }

    // lib/openzeppelin-contracts/contracts/utils/math/Math.sol

    // OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

    /**
    * @dev Standard math utilities missing in the Solidity language.
    */
    library Math {
        enum Rounding {
            Down, // Toward negative infinity
            Up, // Toward infinity
            Zero // Toward zero
        }

        /**
        * @dev Returns the largest of two numbers.
        */
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }

        /**
        * @dev Returns the smallest of two numbers.
        */
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }

        /**
        * @dev Returns the average of two numbers. The result is rounded towards
        * zero.
        */
        function average(uint256 a, uint256 b) internal pure returns (uint256) {
            // (a + b) / 2 can overflow.
            return (a & b) + (a ^ b) / 2;
        }

        /**
        * @dev Returns the ceiling of the division of two numbers.
        *
        * This differs from standard division with `/` in that it rounds up instead
        * of rounding down.
        */
        function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
            // (a + b - 1) / b can overflow on addition, so we distribute.
            return a == 0 ? 0 : (a - 1) / b + 1;
        }

        /**
        * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
        * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
        * with further edits by Uniswap Labs also under MIT license.
        */
        function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
            unchecked {
                // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
                // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
                // variables such that product = prod1 * 2^256 + prod0.
                uint256 prod0; // Least significant 256 bits of the product
                uint256 prod1; // Most significant 256 bits of the product
                assembly {
                    let mm := mulmod(x, y, not(0))
                    prod0 := mul(x, y)
                    prod1 := sub(sub(mm, prod0), lt(mm, prod0))
                }

                // Handle non-overflow cases, 256 by 256 division.
                if (prod1 == 0) {
                    // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                    // The surrounding unchecked block does not change this fact.
                    // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                    return prod0 / denominator;
                }

                // Make sure the result is less than 2^256. Also prevents denominator == 0.
                require(denominator > prod1, "Math: mulDiv overflow");

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from [prod1 prod0].
                uint256 remainder;
                assembly {
                    // Compute remainder using mulmod.
                    remainder := mulmod(x, y, denominator)

                    // Subtract 256 bit number from 512 bit number.
                    prod1 := sub(prod1, gt(remainder, prod0))
                    prod0 := sub(prod0, remainder)
                }

                // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
                // See https://cs.stackexchange.com/q/138556/92363.

                // Does not overflow because the denominator cannot be zero at this stage in the function.
                uint256 twos = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by twos.
                    denominator := div(denominator, twos)

                    // Divide [prod1 prod0] by twos.
                    prod0 := div(prod0, twos)

                    // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                    twos := add(div(sub(0, twos), twos), 1)
                }

                // Shift in bits from prod1 into prod0.
                prod0 |= prod1 * twos;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4.
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step.
                inverse *= 2 - denominator * inverse; // inverse mod 2^8
                inverse *= 2 - denominator * inverse; // inverse mod 2^16
                inverse *= 2 - denominator * inverse; // inverse mod 2^32
                inverse *= 2 - denominator * inverse; // inverse mod 2^64
                inverse *= 2 - denominator * inverse; // inverse mod 2^128
                inverse *= 2 - denominator * inverse; // inverse mod 2^256

                // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
                // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
                // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
                // is no longer required.
                result = prod0 * inverse;
                return result;
            }
        }

        /**
        * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
        */
        function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
            uint256 result = mulDiv(x, y, denominator);
            if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
                result += 1;
            }
            return result;
        }

        /**
        * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
        *
        * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
        */
        function sqrt(uint256 a) internal pure returns (uint256) {
            if (a == 0) {
                return 0;
            }

            // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
            //
            // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
            // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
            //
            // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
            // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
            // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
            //
            // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
            uint256 result = 1 << (log2(a) >> 1);

            // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
            // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
            // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
            // into the expected uint128 result.
            unchecked {
                result = (result + a / result) >> 1;
                result = (result + a / result) >> 1;
                result = (result + a / result) >> 1;
                result = (result + a / result) >> 1;
                result = (result + a / result) >> 1;
                result = (result + a / result) >> 1;
                result = (result + a / result) >> 1;
                return min(result, a / result);
            }
        }

        /**
        * @notice Calculates sqrt(a), following the selected rounding direction.
        */
        function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
            unchecked {
                uint256 result = sqrt(a);
                return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
            }
        }

        /**
        * @dev Return the log in base 2, rounded down, of a positive value.
        * Returns 0 if given 0.
        */
        function log2(uint256 value) internal pure returns (uint256) {
            uint256 result = 0;
            unchecked {
                if (value >> 128 > 0) {
                    value >>= 128;
                    result += 128;
                }
                if (value >> 64 > 0) {
                    value >>= 64;
                    result += 64;
                }
                if (value >> 32 > 0) {
                    value >>= 32;
                    result += 32;
                }
                if (value >> 16 > 0) {
                    value >>= 16;
                    result += 16;
                }
                if (value >> 8 > 0) {
                    value >>= 8;
                    result += 8;
                }
                if (value >> 4 > 0) {
                    value >>= 4;
                    result += 4;
                }
                if (value >> 2 > 0) {
                    value >>= 2;
                    result += 2;
                }
                if (value >> 1 > 0) {
                    result += 1;
                }
            }
            return result;
        }

        /**
        * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
        * Returns 0 if given 0.
        */
        function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
            unchecked {
                uint256 result = log2(value);
                return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
            }
        }

        /**
        * @dev Return the log in base 10, rounded down, of a positive value.
        * Returns 0 if given 0.
        */
        function log10(uint256 value) internal pure returns (uint256) {
            uint256 result = 0;
            unchecked {
                if (value >= 10 ** 64) {
                    value /= 10 ** 64;
                    result += 64;
                }
                if (value >= 10 ** 32) {
                    value /= 10 ** 32;
                    result += 32;
                }
                if (value >= 10 ** 16) {
                    value /= 10 ** 16;
                    result += 16;
                }
                if (value >= 10 ** 8) {
                    value /= 10 ** 8;
                    result += 8;
                }
                if (value >= 10 ** 4) {
                    value /= 10 ** 4;
                    result += 4;
                }
                if (value >= 10 ** 2) {
                    value /= 10 ** 2;
                    result += 2;
                }
                if (value >= 10 ** 1) {
                    result += 1;
                }
            }
            return result;
        }

        /**
        * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
        * Returns 0 if given 0.
        */
        function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
            unchecked {
                uint256 result = log10(value);
                return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
            }
        }

        /**
        * @dev Return the log in base 256, rounded down, of a positive value.
        * Returns 0 if given 0.
        *
        * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
        */
        function log256(uint256 value) internal pure returns (uint256) {
            uint256 result = 0;
            unchecked {
                if (value >> 128 > 0) {
                    value >>= 128;
                    result += 16;
                }
                if (value >> 64 > 0) {
                    value >>= 64;
                    result += 8;
                }
                if (value >> 32 > 0) {
                    value >>= 32;
                    result += 4;
                }
                if (value >> 16 > 0) {
                    value >>= 16;
                    result += 2;
                }
                if (value >> 8 > 0) {
                    result += 1;
                }
            }
            return result;
        }

        /**
        * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
        * Returns 0 if given 0.
        */
        function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
            unchecked {
                uint256 result = log256(value);
                return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
            }
        }
    }

    // src/interfaces/IBaseStrategy.sol

    interface IBaseStrategy {
        function tokenizedStrategyAddress() external view returns (address);

        /*//////////////////////////////////////////////////////////////
                                IMMUTABLE FUNCTIONS
        //////////////////////////////////////////////////////////////*/

        function availableDepositLimit(
            address _owner
        ) external view returns (uint256);

        function availableWithdrawLimit(
            address _owner
        ) external view returns (uint256);

        function deployFunds(uint256 _assets) external;

        function freeFunds(uint256 _amount) external;

        function harvestAndReport() external returns (uint256);

        function tendThis(uint256 _totalIdle) external;

        function shutdownWithdraw(uint256 _amount) external;

        function tendTrigger() external view returns (bool, bytes memory);
    }

    // src/interfaces/IFactory.sol

    interface IFactory {
        function protocol_fee_config() external view returns (uint16, address);
    }

    // lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

    // OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

    /**
    * @dev Interface for the optional metadata functions from the ERC20 standard.
    *
    * _Available since v4.1._
    */
    interface IERC20Metadata is IERC20 {
        /**
        * @dev Returns the name of the token.
        */
        function name() external view returns (string memory);

        /**
        * @dev Returns the symbol of the token.
        */
        function symbol() external view returns (string memory);

        /**
        * @dev Returns the decimals places of the token.
        */
        function decimals() external view returns (uint8);
    }

    // lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

    // OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

    /**
    * @dev Implementation of the {IERC20} interface.
    *
    * This implementation is agnostic to the way tokens are created. This means
    * that a supply mechanism has to be added in a derived contract using {_mint}.
    * For a generic mechanism see {ERC20PresetMinterPauser}.
    *
    * TIP: For a detailed writeup see our guide
    * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
    * to implement supply mechanisms].
    *
    * The default value of {decimals} is 18. To change this, you should override
    * this function so it returns a different value.
    *
    * We have followed general OpenZeppelin Contracts guidelines: functions revert
    * instead returning `false` on failure. This behavior is nonetheless
    * conventional and does not conflict with the expectations of ERC20
    * applications.
    *
    * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
    * This allows applications to reconstruct the allowance for all accounts just
    * by listening to said events. Other implementations of the EIP may not emit
    * these events, as it isn't required by the specification.
    *
    * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
    * functions have been added to mitigate the well-known issues around setting
    * allowances. See {IERC20-approve}.
    */
    contract ERC20 is Context, IERC20, IERC20Metadata {
        mapping(address => uint256) private _balances;

        mapping(address => mapping(address => uint256)) private _allowances;

        uint256 private _totalSupply;

        string private _name;
        string private _symbol;

        /**
        * @dev Sets the values for {name} and {symbol}.
        *
        * All two of these values are immutable: they can only be set once during
        * construction.
        */
        constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
        }

        /**
        * @dev Returns the name of the token.
        */
        function name() public view virtual override returns (string memory) {
            return _name;
        }

        /**
        * @dev Returns the symbol of the token, usually a shorter version of the
        * name.
        */
        function symbol() public view virtual override returns (string memory) {
            return _symbol;
        }

        /**
        * @dev Returns the number of decimals used to get its user representation.
        * For example, if `decimals` equals `2`, a balance of `505` tokens should
        * be displayed to a user as `5.05` (`505 / 10 ** 2`).
        *
        * Tokens usually opt for a value of 18, imitating the relationship between
        * Ether and Wei. This is the default value returned by this function, unless
        * it's overridden.
        *
        * NOTE: This information is only used for _display_ purposes: it in
        * no way affects any of the arithmetic of the contract, including
        * {IERC20-balanceOf} and {IERC20-transfer}.
        */
        function decimals() public view virtual override returns (uint8) {
            return 18;
        }

        /**
        * @dev See {IERC20-totalSupply}.
        */
        function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
        }

        /**
        * @dev See {IERC20-balanceOf}.
        */
        function balanceOf(address account) public view virtual override returns (uint256) {
            return _balances[account];
        }

        /**
        * @dev See {IERC20-transfer}.
        *
        * Requirements:
        *
        * - `to` cannot be the zero address.
        * - the caller must have a balance of at least `amount`.
        */
        function transfer(address to, uint256 amount) public virtual override returns (bool) {
            address owner = _msgSender();
            _transfer(owner, to, amount);
            return true;
        }

        /**
        * @dev See {IERC20-allowance}.
        */
        function allowance(address owner, address spender) public view virtual override returns (uint256) {
            return _allowances[owner][spender];
        }

        /**
        * @dev See {IERC20-approve}.
        *
        * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
        * `transferFrom`. This is semantically equivalent to an infinite approval.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function approve(address spender, uint256 amount) public virtual override returns (bool) {
            address owner = _msgSender();
            _approve(owner, spender, amount);
            return true;
        }

        /**
        * @dev See {IERC20-transferFrom}.
        *
        * Emits an {Approval} event indicating the updated allowance. This is not
        * required by the EIP. See the note at the beginning of {ERC20}.
        *
        * NOTE: Does not update the allowance if the current allowance
        * is the maximum `uint256`.
        *
        * Requirements:
        *
        * - `from` and `to` cannot be the zero address.
        * - `from` must have a balance of at least `amount`.
        * - the caller must have allowance for ``from``'s tokens of at least
        * `amount`.
        */
        function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
            address spender = _msgSender();
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
            return true;
        }

        /**
        * @dev Atomically increases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {IERC20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            address owner = _msgSender();
            _approve(owner, spender, allowance(owner, spender) + addedValue);
            return true;
        }

        /**
        * @dev Atomically decreases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {IERC20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        * - `spender` must have allowance for the caller of at least
        * `subtractedValue`.
        */
        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            address owner = _msgSender();
            uint256 currentAllowance = allowance(owner, spender);
            require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            unchecked {
                _approve(owner, spender, currentAllowance - subtractedValue);
            }

            return true;
        }

        /**
        * @dev Moves `amount` of tokens from `from` to `to`.
        *
        * This internal function is equivalent to {transfer}, and can be used to
        * e.g. implement automatic token fees, slashing mechanisms, etc.
        *
        * Emits a {Transfer} event.
        *
        * Requirements:
        *
        * - `from` cannot be the zero address.
        * - `to` cannot be the zero address.
        * - `from` must have a balance of at least `amount`.
        */
        function _transfer(address from, address to, uint256 amount) internal virtual {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");

            _beforeTokenTransfer(from, to, amount);

            uint256 fromBalance = _balances[from];
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[from] = fromBalance - amount;
                // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
                // decrementing then incrementing.
                _balances[to] += amount;
            }

            emit Transfer(from, to, amount);

            _afterTokenTransfer(from, to, amount);
        }

        /** @dev Creates `amount` tokens and assigns them to `account`, increasing
        * the total supply.
        *
        * Emits a {Transfer} event with `from` set to the zero address.
        *
        * Requirements:
        *
        * - `account` cannot be the zero address.
        */
        function _mint(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");

            _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            unchecked {
                // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
                _balances[account] += amount;
            }
            emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
        }

        /**
        * @dev Destroys `amount` tokens from `account`, reducing the
        * total supply.
        *
        * Emits a {Transfer} event with `to` set to the zero address.
        *
        * Requirements:
        *
        * - `account` cannot be the zero address.
        * - `account` must have at least `amount` tokens.
        */
        function _burn(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: burn from the zero address");

            _beforeTokenTransfer(account, address(0), amount);

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
                // Overflow not possible: amount <= accountBalance <= totalSupply.
                _totalSupply -= amount;
            }

            emit Transfer(account, address(0), amount);

            _afterTokenTransfer(account, address(0), amount);
        }

        /**
        * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
        *
        * This internal function is equivalent to `approve`, and can be used to
        * e.g. set automatic allowances for certain subsystems, etc.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        *
        * - `owner` cannot be the zero address.
        * - `spender` cannot be the zero address.
        */
        function _approve(address owner, address spender, uint256 amount) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

        /**
        * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
        *
        * Does not update the allowance amount in case of infinite allowance.
        * Revert if not enough allowance is available.
        *
        * Might emit an {Approval} event.
        */
        function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
            uint256 currentAllowance = allowance(owner, spender);
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: insufficient allowance");
                unchecked {
                    _approve(owner, spender, currentAllowance - amount);
                }
            }
        }

        /**
        * @dev Hook that is called before any transfer of tokens. This includes
        * minting and burning.
        *
        * Calling conditions:
        *
        * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
        * will be transferred to `to`.
        * - when `from` is zero, `amount` tokens will be minted for `to`.
        * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
        * - `from` and `to` are never both zero.
        *
        * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
        */
        function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

        /**
        * @dev Hook that is called after any transfer of tokens. This includes
        * minting and burning.
        *
        * Calling conditions:
        *
        * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
        * has been transferred to `to`.
        * - when `from` is zero, `amount` tokens have been minted for `to`.
        * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
        * - `from` and `to` are never both zero.
        *
        * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
        */
        function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    }

    // lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

    // OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

    /**
    * @title SafeERC20
    * @dev Wrappers around ERC20 operations that throw on failure (when the token
    * contract returns false). Tokens that return no value (and instead revert or
    * throw on failure) are also supported, non-reverting calls are assumed to be
    * successful.
    * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
    * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
    */
    library SafeERC20 {
        using Address for address;

        /**
        * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
        * non-reverting calls are assumed to be successful.
        */
        function safeTransfer(IERC20 token, address to, uint256 value) internal {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }

        /**
        * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
        * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
        */
        function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        }

        /**
        * @dev Deprecated. This function has issues similar to the ones found in
        * {IERC20-approve}, and its usage is discouraged.
        *
        * Whenever possible, use {safeIncreaseAllowance} and
        * {safeDecreaseAllowance} instead.
        */
        function safeApprove(IERC20 token, address spender, uint256 value) internal {
            // safeApprove should only be called when setting an initial allowance,
            // or when resetting it to zero. To increase and decrease it, use
            // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
            require(
                (value == 0) || (token.allowance(address(this), spender) == 0),
                "SafeERC20: approve from non-zero to non-zero allowance"
            );
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
        }

        /**
        * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
        * non-reverting calls are assumed to be successful.
        */
        function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
            uint256 oldAllowance = token.allowance(address(this), spender);
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
        }

        /**
        * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
        * non-reverting calls are assumed to be successful.
        */
        function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
            unchecked {
                uint256 oldAllowance = token.allowance(address(this), spender);
                require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
                _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
            }
        }

        /**
        * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
        * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
        * to be set to zero before setting it to a non-zero value, such as USDT.
        */
        function forceApprove(IERC20 token, address spender, uint256 value) internal {
            bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

            if (!_callOptionalReturnBool(token, approvalCall)) {
                _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
                _callOptionalReturn(token, approvalCall);
            }
        }

        /**
        * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
        * Revert on invalid signature.
        */
        function safePermit(
            IERC20Permit token,
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) internal {
            uint256 nonceBefore = token.nonces(owner);
            token.permit(owner, spender, value, deadline, v, r, s);
            uint256 nonceAfter = token.nonces(owner);
            require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
        }

        /**
        * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
        * on the return value: the return value is optional (but if data is returned, it must not be false).
        * @param token The token targeted by the call.
        * @param data The call data (encoded using abi.encode or one of its variants).
        */
        function _callOptionalReturn(IERC20 token, bytes memory data) private {
            // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
            // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
            // the target address contains contract code and also asserts for success in the low-level call.

            bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
            require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }

        /**
        * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
        * on the return value: the return value is optional (but if data is returned, it must not be false).
        * @param token The token targeted by the call.
        * @param data The call data (encoded using abi.encode or one of its variants).
        *
        * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
        */
        function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
            // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
            // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
            // and not revert is the subcall reverts.

            (bool success, bytes memory returndata) = address(token).call(data);
            return
                success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
        }
    }

    // src/TokenizedStrategy.sol

    /**$$$$$$$$$$$$$$$$$$$$$$$$$$$&Mr/|1+~>>iiiiiiiiiii>~+{|tuMW$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$$$$$B#j]->iiiiiiiiiiiiiiiiiiiiiiiiiiii>-?f*B$$$$$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$@zj}~iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii~}fv@$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$@z(+iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii+)zB$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$Mf~iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii~t#@$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$@u[iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii?n@$$$$$$$$$$$$$
    $$$$$$$$$$$@z]iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii?u@$$$$$$$$$$$
    $$$$$$$$$$v]iiiiiiiiiiiiiiii,.';iiiiiiiiiiiiiiiiiiiiiiiiii;'."iiiiiiiiiiiiiiii?u$$$$$$$$$$
    $$$$$$$$%)>iiiiiiiiiiiiiii,.    ';iiiiiiiiiiiiiiiiiiiiii;'    ."iiiiiiiiiiiiiiii1%$$$$$$$$
    $$$$$$$c~iiiiiiiiiiiiiii,.        ';iiiiiiiiiiiiiiiiii;'        ."iiiiiiiiiiiiiii~u$$$$$$$
    $$$$$B/>iiiiiiiiiiiiii!'            `IiiiiiiiiiiiiiiI`            .Iiiiiiiiiiiiiii>|%$$$$$
    $$$$@)iiiiiiiiiiiiiiiii;'             `Iiiiiiiiiiil`             ';iiiiiiiiiiiiiiiii}@$$$$
    $$$B|iiiiiiiiiiiiiiiiiiii;'             `Iiiiiiil`             ';iiiiiiiiiiiiiiiiiiii1B$$$
    $$@)iiiiiiiiiiiiiiiiiiiiiii:'             `;iiI`             ':iiiiiiiiiiiiiiiiiiiiiii{B$$
    $$|iiiiiiiiiiiiiiiiiiiiiiiiii;'             ``             ':iiiiiiiiiiiiiiiiiiiiiiiiii1$$
    $v>iiiiiiiiiiiiiiiiiiiiiiiiiiii:'                        ':iiiiiiiiiiiiiiiiiiiiiiiiiiii>x$
    &?iiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:'                    .,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiii-W
    ziiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:'                .,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiv
    -iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:'            .,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii-
    <iiiiiiiiiiiiiiiiiiii!.':iiiiiiiiiiiiii,          "iiiiiiiiiiiiii;'.Iiiiiiiiiiiiiiiiiiiii<
    iiiiiiiiiiiiiiiiiiiii'   ';iiiiiiiiiiiii          Iiiiiiiiiiiii;'   .iiiiiiiiiiiiiiiiiiiii
    iiiiiiiiiiiiiiiiiiii,      ';iiiiiiiiiii          IiiiiiiiiiiI`      `iiiiiiiiiiiiiiiiiiii
    iiiiiiiiiiiiiiiiiiii.        `Iiiiiiiiii          Iiiiiiiii!`         !iiiiiiiiiiiiiiiiiii
    iiiiiiiiiiiiiiiiiii;          :iiiiiiiii          Iiiiiiiii!          ,iiiiiiiiiiiiiiiiiii
    iiiiiiiiiiiiiiiiiii,          iiiiiiiiii          Iiiiiiiiii.         ^iiiiiiiiiiiiiiiiiii
    <iiiiiiiiiiiiiiiiii,          iiiiiiiiii          Iiiiiiiiii'         ^iiiiiiiiiiiiiiiiii<
    -iiiiiiiiiiiiiiiiii;          Iiiiiiiiii          Iiiiiiiiii.         "iiiiiiiiiiiiiiiiii-
    ziiiiiiiiiiiiiiiiiii.         'iiiiiiiii''''''''''liiiiiiii^          liiiiiiiiiiiiiiiiiiv
    &?iiiiiiiiiiiiiiiiii^          ^iiiiiiiiiiiiiiiiiiiiiiiiii,          `iiiiiiiiiiiiiiiiii_W
    $u>iiiiiiiiiiiiiiiiii.          `!iiiiiiiiiiiiiiiiiiiiiii^          .liiiiiiiiiiiiiiiiiir$
    $$(iiiiiiiiiiiiiiiiii;.          ."iiiiiiiiiiiiiiiiiiii,.           :iiiiiiiiiiiiiiiiii}$$
    $$@{iiiiiiiiiiiiiiiiii;.           .`:iiiiiiiiiiiiii;^.            :iiiiiiiiiiiiiiiiii}B$$
    $$$B)iiiiiiiiiiiiiiiiii!'              '`",::::,"`'.             .Iiiiiiiiiiiiiiiiiii{%$$$
    $$$$@1iiiiiiiiiiiiiiiiiii,.                                     ^iiiiiiiiiiiiiiiiiii[@$$$$
    $$$$$B|>iiiiiiiiiiiiiiiiii!^.                                 `liiiiiiiiiiiiiiiiii>)%$$$$$
    $$$$$$$c~iiiiiiiiiiiiiiiiiiii"'                            ."!iiiiiiiiiiiiiiiiiii~n$$$$$$$
    $$$$$$$$B)iiiiiiiiiiiiiiiiiiiii!,`.                    .'"liiiiiiiiiiiiiiiiiiiii1%$$$$$$$$
    $$$$$$$$$@u]iiiiiiiiiiiiiiiiiiiiiiil,^`'..      ..''^,liiiiiiiiiiiiiiiiiiiiiii-x@$$$$$$$$$
    $$$$$$$$$$$@v?iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii-x$$$$$$$$$$$$
    $$$$$$$$$$$$$@n?iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii-rB$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$/~iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii<\*@$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$Bc1~iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii~{v%$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$Bvf]<iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii<]tuB$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$$$$$%zt-+>iiiiiiiiiiiiiiiiiiiiiiiiiiiii+_tc%$$$$$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$W#u/|{+~>iiiiiiiiiiii><+{|/n#W$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    /**
    * @title Yearn Tokenized Strategy
    * @author yearn.finance
    * @notice
    *  This TokenizedStrategy can be used by anyone wishing to easily build
    *  and deploy their own custom ERC4626 compliant single strategy Vault.
    *
    *  The TokenizedStrategy contract is meant to be used as the proxy
    *  implementation contract that will handle all logic, storage and
    *  management for a custom strategy that inherits the `BaseStrategy`.
    *  Any function calls to the strategy that are not defined within that
    *  strategy will be forwarded through a delegateCall to this contract.

    *  A strategist only needs to override a few simple functions that are
    *  focused entirely on the strategy specific needs to easily and cheaply
    *  deploy their own permissionless 4626 compliant vault.
    */
    contract TokenizedStrategy {
        using Math for uint256;
        using SafeERC20 for ERC20;

        /*//////////////////////////////////////////////////////////////
                                    EVENTS
        //////////////////////////////////////////////////////////////*/
        /**
        * @notice Emitted when a strategy is shutdown.
        */
        event StrategyShutdown();

        /**
        * @notice Emitted on the initialization of any new `strategy` that uses `asset`
        * with this specific `apiVersion`.
        */
        event NewTokenizedStrategy(
            address indexed strategy,
            address indexed asset,
            string apiVersion
        );

        /**
        * @notice Emitted when the strategy reports `profit` or `loss` and
        * `performanceFees` and `protocolFees` are paid out.
        */
        event Reported(
            uint256 profit,
            uint256 loss,
            uint256 protocolFees,
            uint256 performanceFees
        );

        /**
        * @notice Emitted when the 'performanceFeeRecipient' address is
        * updated to 'newPerformanceFeeRecipient'.
        */
        event UpdatePerformanceFeeRecipient(
            address indexed newPerformanceFeeRecipient
        );

        /**
        * @notice Emitted when the 'keeper' address is updated to 'newKeeper'.
        */
        event UpdateKeeper(address indexed newKeeper);

        /**
        * @notice Emitted when the 'performanceFee' is updated to 'newPerformanceFee'.
        */
        event UpdatePerformanceFee(uint16 newPerformanceFee);

        /**
        * @notice Emitted when the 'management' address is updated to 'newManagement'.
        */
        event UpdateManagement(address indexed newManagement);

        /**
        * @notice Emitted when the 'emergencyAdmin' address is updated to 'newEmergencyAdmin'.
        */
        event UpdateEmergencyAdmin(address indexed newEmergencyAdmin);

        /**
        * @notice Emitted when the 'profitMaxUnlockTime' is updated to 'newProfitMaxUnlockTime'.
        */
        event UpdateProfitMaxUnlockTime(uint256 newProfitMaxUnlockTime);

        /**
        * @notice Emitted when the 'pendingManagement' address is updated to 'newPendingManagement'.
        */
        event UpdatePendingManagement(address indexed newPendingManagement);

        /**
        * @notice Emitted when the allowance of a `spender` for an `owner` is set by
        * a call to {approve}. `value` is the new allowance.
        */
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );

        /**
        * @notice Emitted when `value` tokens are moved from one account (`from`) to
        * another (`to`).
        *
        * Note that `value` may be zero.
        */
        event Transfer(address indexed from, address indexed to, uint256 value);

        /**
        * @notice Emitted when the `caller` has exchanged `assets` for `shares`,
        * and transferred those `shares` to `owner`.
        */
        event Deposit(
            address indexed caller,
            address indexed owner,
            uint256 assets,
            uint256 shares
        );

        /**
        * @notice Emitted when the `caller` has exchanged `owner`s `shares` for `assets`,
        * and transferred those `assets` to `receiver`.
        */
        event Withdraw(
            address indexed caller,
            address indexed receiver,
            address indexed owner,
            uint256 assets,
            uint256 shares
        );

        /*//////////////////////////////////////////////////////////////
                            STORAGE STRUCT
        //////////////////////////////////////////////////////////////*/

        /**
        * @dev The struct that will hold all the storage data for each strategy
        * that uses this implementation.
        *
        * This replaces all state variables for a traditional contract. This
        * full struct will be initialized on the creation of the strategy
        * and continually updated and read from for the life of the contract.
        *
        * We combine all the variables into one struct to limit the amount of
        * times the custom storage slots need to be loaded during complex functions.
        *
        * Loading the corresponding storage slot for the struct does not
        * load any of the contents of the struct into memory. So the size
        * will not increase memory related gas usage.
        */
        // prettier-ignore
        struct StrategyData {
            // The ERC20 compliant underlying asset that will be
            // used by the Strategy
            ERC20 asset;

            // These are the corresponding ERC20 variables needed for the
            // strategies token that is issued and burned on each deposit or withdraw.
            uint8 decimals; // The amount of decimals that `asset` and strategy use.
            string name; // The name of the token for the strategy.
            uint256 totalSupply; // The total amount of shares currently issued.
            mapping(address => uint256) nonces; // Mapping of nonces used for permit functions.
            mapping(address => uint256) balances; // Mapping to track current balances for each account that holds shares.
            mapping(address => mapping(address => uint256)) allowances; // Mapping to track the allowances for the strategies shares.

            // We manually track `totalAssets` to prevent PPS manipulation through airdrops.
            uint256 totalAssets;

            // Variables for profit reporting and locking.
            // We use uint96 for timestamps to fit in the same slot as an address. That overflows in 2.5e+21 years.
            // I know Yearn moves slowly but surely V4 will be out by then.
            // If the timestamps ever overflow tell the cyborgs still using this code I'm sorry for being cheap.
            uint256 profitUnlockingRate; // The rate at which locked profit is unlocking.
            uint96 fullProfitUnlockDate; // The timestamp at which all locked shares will unlock.
            address keeper; // Address given permission to call {report} and {tend}.
            uint32 profitMaxUnlockTime; // The amount of seconds that the reported profit unlocks over.
            uint16 performanceFee; // The percent in basis points of profit that is charged as a fee.
            address performanceFeeRecipient; // The address to pay the `performanceFee` to.
            uint96 lastReport; // The last time a {report} was called.

            // Access management variables.
            address management; // Main address that can set all configurable variables.
            address pendingManagement; // Address that is pending to take over `management`.
            address emergencyAdmin; // Address to act in emergencies as well as `management`.

            // Strategy Status
            uint8 entered; // To prevent reentrancy. Use uint8 for gas savings.
            bool shutdown; // Bool that can be used to stop deposits into the strategy.
        }

        /*//////////////////////////////////////////////////////////////
                                MODIFIERS
        //////////////////////////////////////////////////////////////*/

        /**
        * @dev Require that the call is coming from the strategies management.
        */
        modifier onlyManagement() {
            requireManagement(msg.sender);
            _;
        }

        /**
        * @dev Require that the call is coming from either the strategies
        * management or the keeper.
        */
        modifier onlyKeepers() {
            requireKeeperOrManagement(msg.sender);
            _;
        }

        /**
        * @dev Require that the call is coming from either the strategies
        * management or the emergencyAdmin.
        */
        modifier onlyEmergencyAuthorized() {
            requireEmergencyAuthorized(msg.sender);
            _;
        }

        /**
        * @dev Prevents a contract from calling itself, directly or indirectly.
        * Placed over all state changing functions for increased safety.
        */
        modifier nonReentrant() {
            StrategyData storage S = _strategyStorage();
            // On the first call to nonReentrant, `entered` will be false (2)
            require(S.entered != ENTERED, "ReentrancyGuard: reentrant call");

            // Any calls to nonReentrant after this point will fail
            S.entered = ENTERED;

            _;

            // Reset to false (1) once call has finished.
            S.entered = NOT_ENTERED;
        }

        /**
        * @notice Require a caller is `management`.
        * @dev Is left public so that it can be used by the Strategy.
        *
        * When the Strategy calls this the msg.sender would be the
        * address of the strategy so we need to specify the sender.
        *
        * @param _sender The original msg.sender.
        */
        function requireManagement(address _sender) public view {
            require(_sender == _strategyStorage().management, "!management");
        }

        /**
        * @notice Require a caller is the `keeper` or `management`.
        * @dev Is left public so that it can be used by the Strategy.
        *
        * When the Strategy calls this the msg.sender would be the
        * address of the strategy so we need to specify the sender.
        *
        * @param _sender The original msg.sender.
        */
        function requireKeeperOrManagement(address _sender) public view {
            StrategyData storage S = _strategyStorage();
            require(_sender == S.keeper || _sender == S.management, "!keeper");
        }

        /**
        * @notice Require a caller is the `management` or `emergencyAdmin`.
        * @dev Is left public so that it can be used by the Strategy.
        *
        * When the Strategy calls this the msg.sender would be the
        * address of the strategy so we need to specify the sender.
        *
        * @param _sender The original msg.sender.
        */
        function requireEmergencyAuthorized(address _sender) public view {
            StrategyData storage S = _strategyStorage();
            require(
                _sender == S.emergencyAdmin || _sender == S.management,
                "!emergency authorized"
            );
        }

        /*//////////////////////////////////////////////////////////////
                                CONSTANTS
        //////////////////////////////////////////////////////////////*/

        /// @notice API version this TokenizedStrategy implements.
        string internal constant API_VERSION = "3.0.3";

        /// @notice Value to set the `entered` flag to during a call.
        uint8 internal constant ENTERED = 2;
        /// @notice Value to set the `entered` flag to at the end of the call.
        uint8 internal constant NOT_ENTERED = 1;

        /// @notice Maximum in Basis Points the Performance Fee can be set to.
        uint16 public constant MAX_FEE = 5_000; // 50%

        /// @notice Used for fee calculations.
        uint256 internal constant MAX_BPS = 10_000;
        /// @notice Used for profit unlocking rate calculations.
        uint256 internal constant MAX_BPS_EXTENDED = 1_000_000_000_000;

        /// @notice Seconds per year for max profit unlocking time.
        uint256 internal constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days

        /**
        * @dev Custom storage slot that will be used to store the
        * `StrategyData` struct that holds each strategies
        * specific storage variables.
        *
        * Any storage updates done by the TokenizedStrategy actually update
        * the storage of the calling contract. This variable points
        * to the specific location that will be used to store the
        * struct that holds all that data.
        *
        * We use a custom string in order to get a random
        * storage slot that will allow for strategists to use any
        * amount of storage in their strategy without worrying
        * about collisions.
        */
        bytes32 internal constant BASE_STRATEGY_STORAGE =
            bytes32(uint256(keccak256("yearn.base.strategy.storage")) - 1);

        /*//////////////////////////////////////////////////////////////
                                IMMUTABLE
        //////////////////////////////////////////////////////////////*/

        /// @notice Address of the previously deployed Vault factory that the
        // protocol fee config is retrieved from.
        address public immutable FACTORY;

        /*//////////////////////////////////////////////////////////////
                                STORAGE GETTER
        //////////////////////////////////////////////////////////////*/

        /**
        * @dev will return the actual storage slot where the strategy
        * specific `StrategyData` struct is stored for both read
        * and write operations.
        *
        * This loads just the slot location, not the full struct
        * so it can be used in a gas efficient manner.
        */
        function _strategyStorage() internal pure returns (StrategyData storage S) {
            // Since STORAGE_SLOT is a constant, we have to put a variable
            // on the stack to access it from an inline assembly block.
            bytes32 slot = BASE_STRATEGY_STORAGE;
            assembly {
                S.slot := slot
            }
        }

        /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Used to initialize storage for a newly deployed strategy.
        * @dev This should be called atomically whenever a new strategy is
        * deployed and can only be called once for each strategy.
        *
        * This will set all the default storage that must be set for a
        * strategy to function. Any changes can be made post deployment
        * through external calls from `management`.
        *
        * The function will also emit an event that off chain indexers can
        * look for to track any new deployments using this TokenizedStrategy.
        *
        * @param _asset Address of the underlying asset.
        * @param _name Name the strategy will use.
        * @param _management Address to set as the strategies `management`.
        * @param _performanceFeeRecipient Address to receive performance fees.
        * @param _keeper Address to set as strategies `keeper`.
        */
        function initialize(
            address _asset,
            string memory _name,
            address _management,
            address _performanceFeeRecipient,
            address _keeper
        ) external {
            // Cache storage pointer.
            StrategyData storage S = _strategyStorage();

            // Make sure we aren't initialized.
            require(address(S.asset) == address(0), "initialized");

            // Set the strategy's underlying asset.
            S.asset = ERC20(_asset);
            // Set the Strategy Tokens name.
            S.name = _name;
            // Set decimals based off the `asset`.
            S.decimals = ERC20(_asset).decimals();

            // Default to a 10 day profit unlock period.
            S.profitMaxUnlockTime = 10 days;
            // Set address to receive performance fees.
            // Can't be address(0) or we will be burning fees.
            require(_performanceFeeRecipient != address(0), "ZERO ADDRESS");
            // Can't mint shares to its self because of profit locking.
            require(_performanceFeeRecipient != address(this), "self");
            S.performanceFeeRecipient = _performanceFeeRecipient;
            // Default to a 10% performance fee.
            S.performanceFee = 1_000;
            // Set last report to this block.
            S.lastReport = uint96(block.timestamp);

            // Set the default management address. Can't be 0.
            require(_management != address(0), "ZERO ADDRESS");
            S.management = _management;
            // Set the keeper address
            S.keeper = _keeper;

            // Emit event to signal a new strategy has been initialized.
            emit NewTokenizedStrategy(address(this), _asset, API_VERSION);
        }

        /*//////////////////////////////////////////////////////////////
                        ERC4626 WRITE METHODS
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Mints `shares` of strategy shares to `receiver` by
        * depositing exactly `assets` of underlying tokens.
        * @param assets The amount of underlying to deposit in.
        * @param receiver The address to receive the `shares`.
        * @return shares The actual amount of shares issued.
        */
        function deposit(
            uint256 assets,
            address receiver
        ) external nonReentrant returns (uint256 shares) {
            // Get the storage slot for all following calls.
            StrategyData storage S = _strategyStorage();

            // Deposit full balance if using max uint.
            if (assets == type(uint256).max) {
                assets = S.asset.balanceOf(msg.sender);
            }

            // Checking max deposit will also check if shutdown.
            require(
                assets <= _maxDeposit(S, receiver),
                "ERC4626: deposit more than max"
            );
            // Check for rounding error.
            require(
                (shares = _convertToShares(S, assets, Math.Rounding.Down)) != 0,
                "ZERO_SHARES"
            );

            _deposit(S, receiver, assets, shares);
        }

        /**
        * @notice Mints exactly `shares` of strategy shares to
        * `receiver` by depositing `assets` of underlying tokens.
        * @param shares The amount of strategy shares mint.
        * @param receiver The address to receive the `shares`.
        * @return assets The actual amount of asset deposited.
        */
        function mint(
            uint256 shares,
            address receiver
        ) external nonReentrant returns (uint256 assets) {
            // Get the storage slot for all following calls.
            StrategyData storage S = _strategyStorage();

            // Checking max mint will also check if shutdown.
            require(shares <= _maxMint(S, receiver), "ERC4626: mint more than max");
            // Check for rounding error.
            require(
                (assets = _convertToAssets(S, shares, Math.Rounding.Up)) != 0,
                "ZERO_ASSETS"
            );

            _deposit(S, receiver, assets, shares);
        }

        /**
        * @notice Withdraws exactly `assets` from `owners` shares and sends
        * the underlying tokens to `receiver`.
        * @dev This will default to not allowing any loss to be taken.
        * @param assets The amount of underlying to withdraw.
        * @param receiver The address to receive `assets`.
        * @param owner The address whose shares are burnt.
        * @return shares The actual amount of shares burnt.
        */
        function withdraw(
            uint256 assets,
            address receiver,
            address owner
        ) external returns (uint256 shares) {
            return withdraw(assets, receiver, owner, 0);
        }

        /**
        * @notice Withdraws `assets` from `owners` shares and sends
        * the underlying tokens to `receiver`.
        * @dev This includes an added parameter to allow for losses.
        * @param assets The amount of underlying to withdraw.
        * @param receiver The address to receive `assets`.
        * @param owner The address whose shares are burnt.
        * @param maxLoss The amount of acceptable loss in Basis points.
        * @return shares The actual amount of shares burnt.
        */
        function withdraw(
            uint256 assets,
            address receiver,
            address owner,
            uint256 maxLoss
        ) public nonReentrant returns (uint256 shares) {
            // Get the storage slot for all following calls.
            StrategyData storage S = _strategyStorage();
            require(
                assets <= _maxWithdraw(S, owner),
                "ERC4626: withdraw more than max"
            );
            // Check for rounding error or 0 value.
            require(
                (shares = _convertToShares(S, assets, Math.Rounding.Up)) != 0,
                "ZERO_SHARES"
            );

            // Withdraw and track the actual amount withdrawn for loss check.
            _withdraw(S, receiver, owner, assets, shares, maxLoss);
        }

        /**
        * @notice Redeems exactly `shares` from `owner` and
        * sends `assets` of underlying tokens to `receiver`.
        * @dev This will default to allowing any loss passed to be realized.
        * @param shares The amount of shares burnt.
        * @param receiver The address to receive `assets`.
        * @param owner The address whose shares are burnt.
        * @return assets The actual amount of underlying withdrawn.
        */
        function redeem(
            uint256 shares,
            address receiver,
            address owner
        ) external returns (uint256) {
            // We default to not limiting a potential loss.
            return redeem(shares, receiver, owner, MAX_BPS);
        }

        /**
        * @notice Redeems exactly `shares` from `owner` and
        * sends `assets` of underlying tokens to `receiver`.
        * @dev This includes an added parameter to allow for losses.
        * @param shares The amount of shares burnt.
        * @param receiver The address to receive `assets`.
        * @param owner The address whose shares are burnt.
        * @param maxLoss The amount of acceptable loss in Basis points.
        * @return . The actual amount of underlying withdrawn.
        */
        function redeem(
            uint256 shares,
            address receiver,
            address owner,
            uint256 maxLoss
        ) public nonReentrant returns (uint256) {
            // Get the storage slot for all following calls.
            StrategyData storage S = _strategyStorage();
            require(
                shares <= _maxRedeem(S, owner),
                "ERC4626: redeem more than max"
            );
            uint256 assets;
            // Check for rounding error or 0 value.
            require(
                (assets = _convertToAssets(S, shares, Math.Rounding.Down)) != 0,
                "ZERO_ASSETS"
            );

            // We need to return the actual amount withdrawn in case of a loss.
            return _withdraw(S, receiver, owner, assets, shares, maxLoss);
        }

        /*//////////////////////////////////////////////////////////////
                        EXTERNAL 4626 VIEW METHODS
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Get the total amount of assets this strategy holds
        * as of the last report.
        *
        * We manually track `totalAssets` to avoid any PPS manipulation.
        *
        * @return . Total assets the strategy holds.
        */
        function totalAssets() external view returns (uint256) {
            return _totalAssets(_strategyStorage());
        }

        /**
        * @notice Get the current supply of the strategies shares.
        *
        * Locked shares issued to the strategy from profits are not
        * counted towards the full supply until they are unlocked.
        *
        * As more shares slowly unlock the totalSupply will decrease
        * causing the PPS of the strategy to increase.
        *
        * @return . Total amount of shares outstanding.
        */
        function totalSupply() external view returns (uint256) {
            return _totalSupply(_strategyStorage());
        }

        /**
        * @notice The amount of shares that the strategy would
        *  exchange for the amount of assets provided, in an
        * ideal scenario where all the conditions are met.
        *
        * @param assets The amount of underlying.
        * @return . Expected shares that `assets` represents.
        */
        function convertToShares(uint256 assets) external view returns (uint256) {
            return _convertToShares(_strategyStorage(), assets, Math.Rounding.Down);
        }

        /**
        * @notice The amount of assets that the strategy would
        * exchange for the amount of shares provided, in an
        * ideal scenario where all the conditions are met.
        *
        * @param shares The amount of the strategies shares.
        * @return . Expected amount of `asset` the shares represents.
        */
        function convertToAssets(uint256 shares) external view returns (uint256) {
            return _convertToAssets(_strategyStorage(), shares, Math.Rounding.Down);
        }

        /**
        * @notice Allows an on-chain or off-chain user to simulate
        * the effects of their deposit at the current block, given
        * current on-chain conditions.
        * @dev This will round down.
        *
        * @param assets The amount of `asset` to deposits.
        * @return . Expected shares that would be issued.
        */
        function previewDeposit(uint256 assets) external view returns (uint256) {
            return _convertToShares(_strategyStorage(), assets, Math.Rounding.Down);
        }

        /**
        * @notice Allows an on-chain or off-chain user to simulate
        * the effects of their mint at the current block, given
        * current on-chain conditions.
        * @dev This is used instead of convertToAssets so that it can
        * round up for safer mints.
        *
        * @param shares The amount of shares to mint.
        * @return . The needed amount of `asset` for the mint.
        */
        function previewMint(uint256 shares) external view returns (uint256) {
            return _convertToAssets(_strategyStorage(), shares, Math.Rounding.Up);
        }

        /**
        * @notice Allows an on-chain or off-chain user to simulate
        * the effects of their withdrawal at the current block,
        * given current on-chain conditions.
        * @dev This is used instead of convertToShares so that it can
        * round up for safer withdraws.
        *
        * @param assets The amount of `asset` that would be withdrawn.
        * @return . The amount of shares that would be burnt.
        */
        function previewWithdraw(uint256 assets) external view returns (uint256) {
            return _convertToShares(_strategyStorage(), assets, Math.Rounding.Up);
        }

        /**
        * @notice Allows an on-chain or off-chain user to simulate
        * the effects of their redemption at the current block,
        * given current on-chain conditions.
        * @dev This will round down.
        *
        * @param shares The amount of shares that would be redeemed.
        * @return . The amount of `asset` that would be returned.
        */
        function previewRedeem(uint256 shares) external view returns (uint256) {
            return _convertToAssets(_strategyStorage(), shares, Math.Rounding.Down);
        }

        /**
        * @notice Total number of underlying assets that can
        * be deposited into the strategy, where `receiver`
        * corresponds to the receiver of the shares of a {deposit} call.
        *
        * @param receiver The address receiving the shares.
        * @return . The max that `receiver` can deposit in `asset`.
        */
        function maxDeposit(address receiver) external view returns (uint256) {
            return _maxDeposit(_strategyStorage(), receiver);
        }

        /**
        * @notice Total number of shares that can be minted to `receiver`
        * of a {mint} call.
        *
        * @param receiver The address receiving the shares.
        * @return _maxMint The max that `receiver` can mint in shares.
        */
        function maxMint(address receiver) external view returns (uint256) {
            return _maxMint(_strategyStorage(), receiver);
        }

        /**
        * @notice Total number of underlying assets that can be
        * withdrawn from the strategy by `owner`, where `owner`
        * corresponds to the msg.sender of a {redeem} call.
        *
        * @param owner The owner of the shares.
        * @return _maxWithdraw Max amount of `asset` that can be withdrawn.
        */
        function maxWithdraw(address owner) external view returns (uint256) {
            return _maxWithdraw(_strategyStorage(), owner);
        }

        /**
        * @notice Variable `maxLoss` is ignored.
        * @dev Accepts a `maxLoss` variable in order to match the multi
        * strategy vaults ABI.
        */
        function maxWithdraw(
            address owner,
            uint256 /*maxLoss*/
        ) external view returns (uint256) {
            return _maxWithdraw(_strategyStorage(), owner);
        }

        /**
        * @notice Total number of strategy shares that can be
        * redeemed from the strategy by `owner`, where `owner`
        * corresponds to the msg.sender of a {redeem} call.
        *
        * @param owner The owner of the shares.
        * @return _maxRedeem Max amount of shares that can be redeemed.
        */
        function maxRedeem(address owner) external view returns (uint256) {
            return _maxRedeem(_strategyStorage(), owner);
        }

        /**
        * @notice Variable `maxLoss` is ignored.
        * @dev Accepts a `maxLoss` variable in order to match the multi
        * strategy vaults ABI.
        */
        function maxRedeem(
            address owner,
            uint256 /*maxLoss*/
        ) external view returns (uint256) {
            return _maxRedeem(_strategyStorage(), owner);
        }

        /*//////////////////////////////////////////////////////////////
                        INTERNAL 4626 VIEW METHODS
        //////////////////////////////////////////////////////////////*/

        /// @dev Internal implementation of {totalAssets}.
        function _totalAssets(
            StrategyData storage S
        ) internal view returns (uint256) {
            return S.totalAssets;
        }

        /// @dev Internal implementation of {totalSupply}.
        function _totalSupply(
            StrategyData storage S
        ) internal view returns (uint256) {
            return S.totalSupply - _unlockedShares(S);
        }

        /// @dev Internal implementation of {convertToShares}.
        function _convertToShares(
            StrategyData storage S,
            uint256 assets,
            Math.Rounding _rounding
        ) internal view returns (uint256) {
            // Saves an extra SLOAD if values are non-zero.
            uint256 totalSupply_ = _totalSupply(S);
            // If supply is 0, PPS = 1.
            if (totalSupply_ == 0) return assets;

            uint256 totalAssets_ = _totalAssets(S);
            // If assets are 0 but supply is not PPS = 0.
            if (totalAssets_ == 0) return 0;

            return assets.mulDiv(totalSupply_, totalAssets_, _rounding);
        }

        /// @dev Internal implementation of {convertToAssets}.
        function _convertToAssets(
            StrategyData storage S,
            uint256 shares,
            Math.Rounding _rounding
        ) internal view returns (uint256) {
            // Saves an extra SLOAD if totalSupply() is non-zero.
            uint256 supply = _totalSupply(S);

            return
                supply == 0
                    ? shares
                    : shares.mulDiv(_totalAssets(S), supply, _rounding);
        }

        /// @dev Internal implementation of {maxDeposit}.
        function _maxDeposit(
            StrategyData storage S,
            address receiver
        ) internal view returns (uint256) {
            // Cannot deposit when shutdown or to the strategy.
            if (S.shutdown || receiver == address(this)) return 0;

            return IBaseStrategy(address(this)).availableDepositLimit(receiver);
        }

        /// @dev Internal implementation of {maxMint}.
        function _maxMint(
            StrategyData storage S,
            address receiver
        ) internal view returns (uint256 maxMint_) {
            // Cannot mint when shutdown or to the strategy.
            if (S.shutdown || receiver == address(this)) return 0;

            maxMint_ = IBaseStrategy(address(this)).availableDepositLimit(receiver);
            if (maxMint_ != type(uint256).max) {
                maxMint_ = _convertToShares(S, maxMint_, Math.Rounding.Down);
            }
        }

        /// @dev Internal implementation of {maxWithdraw}.
        function _maxWithdraw(
            StrategyData storage S,
            address owner
        ) internal view returns (uint256 maxWithdraw_) {
            // Get the max the owner could withdraw currently.
            maxWithdraw_ = IBaseStrategy(address(this)).availableWithdrawLimit(
                owner
            );

            // If there is no limit enforced.
            if (maxWithdraw_ == type(uint256).max) {
                // Saves a min check if there is no withdrawal limit.
                maxWithdraw_ = _convertToAssets(
                    S,
                    _balanceOf(S, owner),
                    Math.Rounding.Down
                );
            } else {
                maxWithdraw_ = Math.min(
                    _convertToAssets(S, _balanceOf(S, owner), Math.Rounding.Down),
                    maxWithdraw_
                );
            }
        }

        /// @dev Internal implementation of {maxRedeem}.
        function _maxRedeem(
            StrategyData storage S,
            address owner
        ) internal view returns (uint256 maxRedeem_) {
            // Get the max the owner could withdraw currently.
            maxRedeem_ = IBaseStrategy(address(this)).availableWithdrawLimit(owner);

            // Conversion would overflow and saves a min check if there is no withdrawal limit.
            if (maxRedeem_ == type(uint256).max) {
                maxRedeem_ = _balanceOf(S, owner);
            } else {
                maxRedeem_ = Math.min(
                    // Can't redeem more than the balance.
                    _convertToShares(S, maxRedeem_, Math.Rounding.Down),
                    _balanceOf(S, owner)
                );
            }
        }

        /*//////////////////////////////////////////////////////////////
                        INTERNAL 4626 WRITE METHODS
        //////////////////////////////////////////////////////////////*/

        /**
        * @dev Function to be called during {deposit} and {mint}.
        *
        * This function handles all logic including transfers,
        * minting and accounting.
        *
        * We do all external calls before updating any internal
        * values to prevent view reentrancy issues from the token
        * transfers or the _deployFunds() calls.
        */
        function _deposit(
            StrategyData storage S,
            address receiver,
            uint256 assets,
            uint256 shares
        ) internal {
            // Cache storage variables used more than once.
            ERC20 _asset = S.asset;

            // Need to transfer before minting or ERC777s could reenter.
            _asset.safeTransferFrom(msg.sender, address(this), assets);

            // We can deploy the full loose balance currently held.
            IBaseStrategy(address(this)).deployFunds(
                _asset.balanceOf(address(this))
            );

            // Adjust total Assets.
            S.totalAssets += assets;

            // mint shares
            _mint(S, receiver, shares);

            emit Deposit(msg.sender, receiver, assets, shares);
        }

        /**
        * @dev To be called during {redeem} and {withdraw}.
        *
        * This will handle all logic, transfers and accounting
        * in order to service the withdraw request.
        *
        * If we are not able to withdraw the full amount needed, it will
        * be counted as a loss and passed on to the user.
        */
        function _withdraw(
            StrategyData storage S,
            address receiver,
            address owner,
            uint256 assets,
            uint256 shares,
            uint256 maxLoss
        ) internal returns (uint256) {
            require(receiver != address(0), "ZERO ADDRESS");
            require(maxLoss <= MAX_BPS, "exceeds MAX_BPS");

            // Spend allowance if applicable.
            if (msg.sender != owner) {
                _spendAllowance(S, owner, msg.sender, shares);
            }

            // Cache `asset` since it is used multiple times..
            ERC20 _asset = S.asset;

            uint256 idle = _asset.balanceOf(address(this));
            uint256 loss;
            // Check if we need to withdraw funds.
            if (idle < assets) {
                // Tell Strategy to free what we need.
                unchecked {
                    IBaseStrategy(address(this)).freeFunds(assets - idle);
                }

                // Return the actual amount withdrawn. Adjust for potential under withdraws.
                idle = _asset.balanceOf(address(this));

                // If we didn't get enough out then we have a loss.
                if (idle < assets) {
                    unchecked {
                        loss = assets - idle;
                    }
                    // If a non-default max loss parameter was set.
                    if (maxLoss < MAX_BPS) {
                        // Make sure we are within the acceptable range.
                        require(
                            loss <= (assets * maxLoss) / MAX_BPS,
                            "too much loss"
                        );
                    }
                    // Lower the amount to be withdrawn.
                    assets = idle;
                }
            }

            // Update assets based on how much we took.
            S.totalAssets -= (assets + loss);

            _burn(S, owner, shares);

            // Transfer the amount of underlying to the receiver.
            _asset.safeTransfer(receiver, assets);

            emit Withdraw(msg.sender, receiver, owner, assets, shares);

            // Return the actual amount of assets withdrawn.
            return assets;
        }

        /*//////////////////////////////////////////////////////////////
                            PROFIT REPORTING
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Function for keepers to call to harvest and record all
        * profits accrued.
        *
        * @dev This will account for any gains/losses since the last report
        * and charge fees accordingly.
        *
        * Any profit over the fees charged will be immediately locked
        * so there is no change in PricePerShare. Then slowly unlocked
        * over the `maxProfitUnlockTime` each second based on the
        * calculated `profitUnlockingRate`.
        *
        * In case of a loss it will first attempt to offset the loss
        * with any remaining locked shares from the last report in
        * order to reduce any negative impact to PPS.
        *
        * Will then recalculate the new time to unlock profits over and the
        * rate based on a weighted average of any remaining time from the
        * last report and the new amount of shares to be locked.
        *
        * @return profit The notional amount of gain if any since the last
        * report in terms of `asset`.
        * @return loss The notional amount of loss if any since the last
        * report in terms of `asset`.
        */
        function report()
            external
            nonReentrant
            onlyKeepers
            returns (uint256 profit, uint256 loss)
        {
            // Cache storage pointer since its used repeatedly.
            StrategyData storage S = _strategyStorage();

            // Tell the strategy to report the real total assets it has.
            // It should do all reward selling and redepositing now and
            // account for deployed and loose `asset` so we can accurately
            // account for all funds including those potentially airdropped
            // and then have any profits immediately locked.
            uint256 newTotalAssets = IBaseStrategy(address(this))
                .harvestAndReport();

            uint256 oldTotalAssets = _totalAssets(S);

            // Get the amount of shares we need to burn from previous reports.
            uint256 sharesToBurn = _unlockedShares(S);

            // Initialize variables needed throughout.
            uint256 totalFees;
            uint256 protocolFees;
            uint256 sharesToLock;
            uint256 _profitMaxUnlockTime = S.profitMaxUnlockTime;
            // Calculate profit/loss.
            if (newTotalAssets > oldTotalAssets) {
                // We have a profit.
                unchecked {
                    profit = newTotalAssets - oldTotalAssets;
                }

                // We need to get the equivalent amount of shares
                // at the current PPS before any minting or burning.
                sharesToLock = _convertToShares(S, profit, Math.Rounding.Down);

                // Cache the performance fee.
                uint16 fee = S.performanceFee;
                uint256 totalFeeShares;
                // If we are charging a performance fee
                if (fee != 0) {
                    // Asses performance fees.
                    unchecked {
                        // Get in `asset` for the event.
                        totalFees = (profit * fee) / MAX_BPS;
                        // And in shares for the payment.
                        totalFeeShares = (sharesToLock * fee) / MAX_BPS;
                    }

                    // Get the protocol fee config from the factory.
                    (
                        uint16 protocolFeeBps,
                        address protocolFeesRecipient
                    ) = IFactory(FACTORY).protocol_fee_config();

                    uint256 protocolFeeShares;
                    // Check if there is a protocol fee to charge.
                    if (protocolFeeBps != 0) {
                        unchecked {
                            // Calculate protocol fees based on the performance Fees.
                            protocolFeeShares =
                                (totalFeeShares * protocolFeeBps) /
                                MAX_BPS;
                            // Need amount in underlying for event.
                            protocolFees = (totalFees * protocolFeeBps) / MAX_BPS;
                        }

                        // Mint the protocol fees to the recipient.
                        _mint(S, protocolFeesRecipient, protocolFeeShares);
                    }

                    // Mint the difference to the strategy fee recipient.
                    unchecked {
                        _mint(
                            S,
                            S.performanceFeeRecipient,
                            totalFeeShares - protocolFeeShares
                        );
                    }
                }

                // Check if we are locking profit.
                if (_profitMaxUnlockTime != 0) {
                    // lock (profit - fees)
                    unchecked {
                        sharesToLock -= totalFeeShares;
                    }

                    // If we are burning more than re-locking.
                    if (sharesToBurn > sharesToLock) {
                        // Burn the difference
                        unchecked {
                            _burn(S, address(this), sharesToBurn - sharesToLock);
                        }
                    } else if (sharesToLock > sharesToBurn) {
                        // Mint the shares to lock the strategy.
                        unchecked {
                            _mint(S, address(this), sharesToLock - sharesToBurn);
                        }
                    }
                }
            } else {
                // Expect we have a loss.
                unchecked {
                    loss = oldTotalAssets - newTotalAssets;
                }

                // Check in case `else` was due to being equal.
                if (loss != 0) {
                    // We will try and burn the unlocked shares and as much from any
                    // pending profit still unlocking to offset the loss to prevent any PPS decline post report.
                    sharesToBurn = Math.min(
                        // Cannot burn more than we have.
                        S.balances[address(this)],
                        // Try and burn both the shares already unlocked and the amount for the loss.
                        _convertToShares(S, loss, Math.Rounding.Down) + sharesToBurn
                    );
                }

                // Check if there is anything to burn.
                if (sharesToBurn != 0) {
                    _burn(S, address(this), sharesToBurn);
                }
            }

            // Update unlocking rate and time to fully unlocked.
            uint256 totalLockedShares = S.balances[address(this)];
            if (totalLockedShares != 0) {
                uint256 previouslyLockedTime;
                uint96 _fullProfitUnlockDate = S.fullProfitUnlockDate;
                // Check if we need to account for shares still unlocking.
                if (_fullProfitUnlockDate > block.timestamp) {
                    unchecked {
                        // There will only be previously locked shares if time remains.
                        // We calculate this here since it should be rare.
                        previouslyLockedTime =
                            (_fullProfitUnlockDate - block.timestamp) *
                            (totalLockedShares - sharesToLock);
                    }
                }

                // newProfitLockingPeriod is a weighted average between the remaining
                // time of the previously locked shares and the profitMaxUnlockTime.
                uint256 newProfitLockingPeriod = (previouslyLockedTime +
                    sharesToLock *
                    _profitMaxUnlockTime) / totalLockedShares;

                // Calculate how many shares unlock per second.
                S.profitUnlockingRate =
                    (totalLockedShares * MAX_BPS_EXTENDED) /
                    newProfitLockingPeriod;

                // Calculate how long until the full amount of shares is unlocked.
                S.fullProfitUnlockDate = uint96(
                    block.timestamp + newProfitLockingPeriod
                );
            } else {
                // Only setting this to 0 will turn in the desired effect,
                // no need to update profitUnlockingRate.
                S.fullProfitUnlockDate = 0;
            }

            // Update the new total assets value.
            S.totalAssets = newTotalAssets;
            S.lastReport = uint96(block.timestamp);

            // Emit event with info
            emit Reported(
                profit,
                loss,
                protocolFees, // Protocol fees
                totalFees - protocolFees // Performance Fees
            );
        }

        /**
        * @notice Get how many shares have been unlocked since last report.
        * @return . The amount of shares that have unlocked.
        */
        function unlockedShares() external view returns (uint256) {
            return _unlockedShares(_strategyStorage());
        }

        /**
        * @dev To determine how many of the shares that were locked during the last
        * report have since unlocked.
        *
        * If the `fullProfitUnlockDate` has passed the full strategy's balance will
        * count as unlocked.
        *
        * @return unlocked The amount of shares that have unlocked.
        */
        function _unlockedShares(
            StrategyData storage S
        ) internal view returns (uint256 unlocked) {
            uint96 _fullProfitUnlockDate = S.fullProfitUnlockDate;
            if (_fullProfitUnlockDate > block.timestamp) {
                unchecked {
                    unlocked =
                        (S.profitUnlockingRate * (block.timestamp - S.lastReport)) /
                        MAX_BPS_EXTENDED;
                }
            } else if (_fullProfitUnlockDate != 0) {
                // All shares have been unlocked.
                unlocked = S.balances[address(this)];
            }
        }

        /*//////////////////////////////////////////////////////////////
                                TENDING
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice For a 'keeper' to 'tend' the strategy if a custom
        * tendTrigger() is implemented.
        *
        * @dev Both 'tendTrigger' and '_tend' will need to be overridden
        * for this to be used.
        *
        * This will callback the internal '_tend' call in the BaseStrategy
        * with the total current amount available to the strategy to deploy.
        *
        * This is a permissioned function so if desired it could
        * be used for illiquid or manipulatable strategies to compound
        * rewards, perform maintenance or deposit/withdraw funds.
        *
        * This will not cause any change in PPS. Total assets will
        * be the same before and after.
        *
        * A report() call will be needed to record any profits or losses.
        */
        function tend() external nonReentrant onlyKeepers {
            // Tend the strategy with the current loose balance.
            IBaseStrategy(address(this)).tendThis(
                _strategyStorage().asset.balanceOf(address(this))
            );
        }

        /*//////////////////////////////////////////////////////////////
                            STRATEGY SHUTDOWN
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Used to shutdown the strategy preventing any further deposits.
        * @dev Can only be called by the current `management` or `emergencyAdmin`.
        *
        * This will stop any new {deposit} or {mint} calls but will
        * not prevent {withdraw} or {redeem}. It will also still allow for
        * {tend} and {report} so that management can report any last losses
        * in an emergency as well as provide any maintenance to allow for full
        * withdraw.
        *
        * This is a one way switch and can never be set back once shutdown.
        */
        function shutdownStrategy() external onlyEmergencyAuthorized {
            _strategyStorage().shutdown = true;

            emit StrategyShutdown();
        }

        /**
        * @notice To manually withdraw funds from the yield source after a
        * strategy has been shutdown.
        * @dev This can only be called post {shutdownStrategy}.
        *
        * This will never cause a change in PPS. Total assets will
        * be the same before and after.
        *
        * A strategist will need to override the {_emergencyWithdraw} function
        * in their strategy for this to work.
        *
        * @param amount The amount of asset to attempt to free.
        */
        function emergencyWithdraw(
            uint256 amount
        ) external nonReentrant onlyEmergencyAuthorized {
            // Make sure the strategy has been shutdown.
            require(_strategyStorage().shutdown, "not shutdown");

            // Withdraw from the yield source.
            IBaseStrategy(address(this)).shutdownWithdraw(amount);
        }

        /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Get the underlying asset for the strategy.
        * @return . The underlying asset.
        */
        function asset() external view returns (address) {
            return address(_strategyStorage().asset);
        }

        /**
        * @notice Get the API version for this TokenizedStrategy.
        * @return . The API version for this TokenizedStrategy
        */
        function apiVersion() external pure returns (string memory) {
            return API_VERSION;
        }

        /**
        * @notice Get the current address that controls the strategy.
        * @return . Address of management
        */
        function management() external view returns (address) {
            return _strategyStorage().management;
        }

        /**
        * @notice Get the current pending management address if any.
        * @return . Address of pendingManagement
        */
        function pendingManagement() external view returns (address) {
            return _strategyStorage().pendingManagement;
        }

        /**
        * @notice Get the current address that can call tend and report.
        * @return . Address of the keeper
        */
        function keeper() external view returns (address) {
            return _strategyStorage().keeper;
        }

        /**
        * @notice Get the current address that can shutdown and emergency withdraw.
        * @return . Address of the emergencyAdmin
        */
        function emergencyAdmin() external view returns (address) {
            return _strategyStorage().emergencyAdmin;
        }

        /**
        * @notice Get the current performance fee charged on profits.
        * denominated in Basis Points where 10_000 == 100%
        * @return . Current performance fee.
        */
        function performanceFee() external view returns (uint16) {
            return _strategyStorage().performanceFee;
        }

        /**
        * @notice Get the current address that receives the performance fees.
        * @return . Address of performanceFeeRecipient
        */
        function performanceFeeRecipient() external view returns (address) {
            return _strategyStorage().performanceFeeRecipient;
        }

        /**
        * @notice Gets the timestamp at which all profits will be unlocked.
        * @return . The full profit unlocking timestamp
        */
        function fullProfitUnlockDate() external view returns (uint256) {
            return uint256(_strategyStorage().fullProfitUnlockDate);
        }

        /**
        * @notice The per second rate at which profits are unlocking.
        * @dev This is denominated in EXTENDED_BPS decimals.
        * @return . The current profit unlocking rate.
        */
        function profitUnlockingRate() external view returns (uint256) {
            return _strategyStorage().profitUnlockingRate;
        }

        /**
        * @notice Gets the current time profits are set to unlock over.
        * @return . The current profit max unlock time.
        */
        function profitMaxUnlockTime() external view returns (uint256) {
            return _strategyStorage().profitMaxUnlockTime;
        }

        /**
        * @notice The timestamp of the last time protocol fees were charged.
        * @return . The last report.
        */
        function lastReport() external view returns (uint256) {
            return uint256(_strategyStorage().lastReport);
        }

        /**
        * @notice Get the price per share.
        * @dev This value offers limited precision. Integrations that require
        * exact precision should use convertToAssets or convertToShares instead.
        *
        * @return . The price per share.
        */
        function pricePerShare() external view returns (uint256) {
            StrategyData storage S = _strategyStorage();
            return _convertToAssets(S, 10 ** S.decimals, Math.Rounding.Down);
        }

        /**
        * @notice To check if the strategy has been shutdown.
        * @return . Whether or not the strategy is shutdown.
        */
        function isShutdown() external view returns (bool) {
            return _strategyStorage().shutdown;
        }

        /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Step one of two to set a new address to be in charge of the strategy.
        * @dev Can only be called by the current `management`. The address is
        * set to pending management and will then have to call {acceptManagement}
        * in order for the 'management' to officially change.
        *
        * Cannot set `management` to address(0).
        *
        * @param _management New address to set `pendingManagement` to.
        */
        function setPendingManagement(address _management) external onlyManagement {
            require(_management != address(0), "ZERO ADDRESS");
            _strategyStorage().pendingManagement = _management;

            emit UpdatePendingManagement(_management);
        }

        /**
        * @notice Step two of two to set a new 'management' of the strategy.
        * @dev Can only be called by the current `pendingManagement`.
        */
        function acceptManagement() external {
            StrategyData storage S = _strategyStorage();
            require(msg.sender == S.pendingManagement, "!pending");
            S.management = msg.sender;
            S.pendingManagement = address(0);

            emit UpdateManagement(msg.sender);
        }

        /**
        * @notice Sets a new address to be in charge of tend and reports.
        * @dev Can only be called by the current `management`.
        *
        * @param _keeper New address to set `keeper` to.
        */
        function setKeeper(address _keeper) external onlyManagement {
            _strategyStorage().keeper = _keeper;

            emit UpdateKeeper(_keeper);
        }

        /**
        * @notice Sets a new address to be able to shutdown the strategy.
        * @dev Can only be called by the current `management`.
        *
        * @param _emergencyAdmin New address to set `emergencyAdmin` to.
        */
        function setEmergencyAdmin(
            address _emergencyAdmin
        ) external onlyManagement {
            _strategyStorage().emergencyAdmin = _emergencyAdmin;

            emit UpdateEmergencyAdmin(_emergencyAdmin);
        }

        /**
        * @notice Sets the performance fee to be charged on reported gains.
        * @dev Can only be called by the current `management`.
        *
        * Denominated in Basis Points. So 100% == 10_000.
        * Cannot set greater than to MAX_FEE.
        *
        * @param _performanceFee New performance fee.
        */
        function setPerformanceFee(uint16 _performanceFee) external onlyManagement {
            require(_performanceFee <= MAX_FEE, "MAX FEE");
            _strategyStorage().performanceFee = _performanceFee;

            emit UpdatePerformanceFee(_performanceFee);
        }

        /**
        * @notice Sets a new address to receive performance fees.
        * @dev Can only be called by the current `management`.
        *
        * Cannot set to address(0).
        *
        * @param _performanceFeeRecipient New address to set `management` to.
        */
        function setPerformanceFeeRecipient(
            address _performanceFeeRecipient
        ) external onlyManagement {
            require(_performanceFeeRecipient != address(0), "ZERO ADDRESS");
            require(_performanceFeeRecipient != address(this), "Cannot be self");
            _strategyStorage().performanceFeeRecipient = _performanceFeeRecipient;

            emit UpdatePerformanceFeeRecipient(_performanceFeeRecipient);
        }

        /**
        * @notice Sets the time for profits to be unlocked over.
        * @dev Can only be called by the current `management`.
        *
        * Denominated in seconds and cannot be greater than 1 year.
        *
        * NOTE: Setting to 0 will cause all currently locked profit
        * to be unlocked instantly and should be done with care.
        *
        * `profitMaxUnlockTime` is stored as a uint32 for packing but can
        * be passed in as uint256 for simplicity.
        *
        * @param _profitMaxUnlockTime New `profitMaxUnlockTime`.
        */
        function setProfitMaxUnlockTime(
            uint256 _profitMaxUnlockTime
        ) external onlyManagement {
            // Must be less than a year.
            require(_profitMaxUnlockTime <= SECONDS_PER_YEAR, "too long");
            StrategyData storage S = _strategyStorage();

            // If we are setting to 0 we need to adjust amounts.
            if (_profitMaxUnlockTime == 0) {
                uint256 shares = S.balances[address(this)];
                if (shares != 0) {
                    // Burn all shares if applicable.
                    _burn(S, address(this), shares);
                }
                // Reset unlocking variables
                S.profitUnlockingRate = 0;
                S.fullProfitUnlockDate = 0;
            }

            S.profitMaxUnlockTime = uint32(_profitMaxUnlockTime);

            emit UpdateProfitMaxUnlockTime(_profitMaxUnlockTime);
        }

        /**
        * @notice Updates the name for the strategy.
        * @param _name The new name for the strategy.
        */
        function setName(string calldata _name) external onlyManagement {
            _strategyStorage().name = _name;
        }

        /*//////////////////////////////////////////////////////////////
                            ERC20 METHODS
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Returns the name of the token.
        * @return . The name the strategy is using for its token.
        */
        function name() external view returns (string memory) {
            return _strategyStorage().name;
        }

        /**
        * @notice Returns the symbol of the strategies token.
        * @dev Will be 'ys + asset symbol'.
        * @return . The symbol the strategy is using for its tokens.
        */
        function symbol() external view returns (string memory) {
            return
                string(abi.encodePacked("ys", _strategyStorage().asset.symbol()));
        }

        /**
        * @notice Returns the number of decimals used to get its user representation.
        * @return . The decimals used for the strategy and `asset`.
        */
        function decimals() external view returns (uint8) {
            return _strategyStorage().decimals;
        }

        /**
        * @notice Returns the current balance for a given '_account'.
        * @dev If the '_account` is the strategy then this will subtract
        * the amount of shares that have been unlocked since the last profit first.
        * @param account the address to return the balance for.
        * @return . The current balance in y shares of the '_account'.
        */
        function balanceOf(address account) external view returns (uint256) {
            return _balanceOf(_strategyStorage(), account);
        }

        /// @dev Internal implementation of {balanceOf}.
        function _balanceOf(
            StrategyData storage S,
            address account
        ) internal view returns (uint256) {
            if (account == address(this)) {
                return S.balances[account] - _unlockedShares(S);
            }
            return S.balances[account];
        }

        /**
        * @notice Transfer '_amount` of shares from `msg.sender` to `to`.
        * @dev
        * Requirements:
        *
        * - `to` cannot be the zero address.
        * - `to` cannot be the address of the strategy.
        * - the caller must have a balance of at least `_amount`.
        *
        * @param to The address shares will be transferred to.
        * @param amount The amount of shares to be transferred from sender.
        * @return . a boolean value indicating whether the operation succeeded.
        */
        function transfer(address to, uint256 amount) external returns (bool) {
            _transfer(_strategyStorage(), msg.sender, to, amount);
            return true;
        }

        /**
        * @notice Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        *
        * This value changes when {approve} or {transferFrom} are called.
        * @param owner The address who owns the shares.
        * @param spender The address who would be moving the owners shares.
        * @return . The remaining amount of shares of `owner` that could be moved by `spender`.
        */
        function allowance(
            address owner,
            address spender
        ) external view returns (uint256) {
            return _allowance(_strategyStorage(), owner, spender);
        }

        /// @dev Internal implementation of {allowance}.
        function _allowance(
            StrategyData storage S,
            address owner,
            address spender
        ) internal view returns (uint256) {
            return S.allowances[owner][spender];
        }

        /**
        * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
        * @dev
        *
        * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
        * `transferFrom`. This is semantically equivalent to an infinite approval.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        *
        * IMPORTANT: Beware that changing an allowance with this method brings the risk
        * that someone may use both the old and the new allowance by unfortunate
        * transaction ordering. One possible solution to mitigate this race
        * condition is to first reduce the spender's allowance to 0 and set the
        * desired value afterwards:
        * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        *
        * Emits an {Approval} event.
        *
        * @param spender the address to allow the shares to be moved by.
        * @param amount the amount of shares to allow `spender` to move.
        * @return . a boolean value indicating whether the operation succeeded.
        */
        function approve(address spender, uint256 amount) external returns (bool) {
            _approve(_strategyStorage(), msg.sender, spender, amount);
            return true;
        }

        /**
        * @notice `amount` tokens from `from` to `to` using the
        * allowance mechanism. `amount` is then deducted from the caller's
        * allowance.
        *
        * @dev
        * Emits an {Approval} event indicating the updated allowance. This is not
        * required by the EIP.
        *
        * NOTE: Does not update the allowance if the current allowance
        * is the maximum `uint256`.
        *
        * Requirements:
        *
        * - `from` and `to` cannot be the zero address.
        * - `to` cannot be the address of the strategy.
        * - `from` must have a balance of at least `amount`.
        * - the caller must have allowance for ``from``'s tokens of at least
        * `amount`.
        *
        * Emits a {Transfer} event.
        *
        * @param from the address to be moving shares from.
        * @param to the address to be moving shares to.
        * @param amount the quantity of shares to move.
        * @return . a boolean value indicating whether the operation succeeded.
        */
        function transferFrom(
            address from,
            address to,
            uint256 amount
        ) external returns (bool) {
            StrategyData storage S = _strategyStorage();
            _spendAllowance(S, from, msg.sender, amount);
            _transfer(S, from, to, amount);
            return true;
        }

        /**
        * @dev Moves `amount` of tokens from `from` to `to`.
        *
        * This internal function is equivalent to {transfer}, and can be used to
        * e.g. implement automatic token fees, slashing mechanisms, etc.
        *
        * Emits a {Transfer} event.
        *
        * Requirements:
        *
        * - `from` cannot be the zero address.
        * - `to` cannot be the zero address.
        * - `to` cannot be the strategies address
        * - `from` must have a balance of at least `amount`.
        *
        */
        function _transfer(
            StrategyData storage S,
            address from,
            address to,
            uint256 amount
        ) internal {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(to != address(this), "ERC20 transfer to strategy");

            S.balances[from] -= amount;
            unchecked {
                S.balances[to] += amount;
            }

            emit Transfer(from, to, amount);
        }

        /** @dev Creates `amount` tokens and assigns them to `account`, increasing
        * the total supply.
        *
        * Emits a {Transfer} event with `from` set to the zero address.
        *
        * Requirements:
        *
        * - `account` cannot be the zero address.
        *
        */
        function _mint(
            StrategyData storage S,
            address account,
            uint256 amount
        ) internal {
            require(account != address(0), "ERC20: mint to the zero address");

            S.totalSupply += amount;
            unchecked {
                S.balances[account] += amount;
            }
            emit Transfer(address(0), account, amount);
        }

        /**
        * @dev Destroys `amount` tokens from `account`, reducing the
        * total supply.
        *
        * Emits a {Transfer} event with `to` set to the zero address.
        *
        * Requirements:
        *
        * - `account` cannot be the zero address.
        * - `account` must have at least `amount` tokens.
        */
        function _burn(
            StrategyData storage S,
            address account,
            uint256 amount
        ) internal {
            require(account != address(0), "ERC20: burn from the zero address");

            S.balances[account] -= amount;
            unchecked {
                S.totalSupply -= amount;
            }
            emit Transfer(account, address(0), amount);
        }

        /**
        * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
        *
        * This internal function is equivalent to `approve`, and can be used to
        * e.g. set automatic allowances for certain subsystems, etc.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        *
        * - `owner` cannot be the zero address.
        * - `spender` cannot be the zero address.
        */
        function _approve(
            StrategyData storage S,
            address owner,
            address spender,
            uint256 amount
        ) internal {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");

            S.allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

        /**
        * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
        *
        * Does not update the allowance amount in case of infinite allowance.
        * Revert if not enough allowance is available.
        *
        * Might emit an {Approval} event.
        */
        function _spendAllowance(
            StrategyData storage S,
            address owner,
            address spender,
            uint256 amount
        ) internal {
            uint256 currentAllowance = _allowance(S, owner, spender);
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "ERC20: insufficient allowance"
                );
                unchecked {
                    _approve(S, owner, spender, currentAllowance - amount);
                }
            }
        }

        /*//////////////////////////////////////////////////////////////
                                EIP-2612 LOGIC
        //////////////////////////////////////////////////////////////*/

        /**
        * @notice Returns the current nonce for `owner`. This value must be
        * included whenever a signature is generated for {permit}.
        *
        * @dev Every successful call to {permit} increases ``owner``'s nonce by one. This
        * prevents a signature from being used multiple times.
        *
        * @param _owner the address of the account to return the nonce for.
        * @return . the current nonce for the account.
        */
        function nonces(address _owner) external view returns (uint256) {
            return _strategyStorage().nonces[_owner];
        }

        /**
        * @notice Sets `value` as the allowance of `spender` over ``owner``'s tokens,
        * given ``owner``'s signed approval.
        *
        * @dev IMPORTANT: The same issues {IERC20-approve} has related to transaction
        * ordering also apply here.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        * - `deadline` must be a timestamp in the future.
        * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
        * over the EIP712-formatted function arguments.
        * - the signature must use ``owner``'s current nonce (see {nonces}).
        *
        * For more information on the signature format, see the
        * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
        * section].
        */
        function permit(
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external {
            require(deadline >= block.timestamp, "ERC20: PERMIT_DEADLINE_EXPIRED");

            // Unchecked because the only math done is incrementing
            // the owner's nonce which cannot realistically overflow.
            unchecked {
                address recoveredAddress = ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19\x01",
                            DOMAIN_SEPARATOR(),
                            keccak256(
                                abi.encode(
                                    keccak256(
                                        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                    ),
                                    owner,
                                    spender,
                                    value,
                                    _strategyStorage().nonces[owner]++,
                                    deadline
                                )
                            )
                        )
                    ),
                    v,
                    r,
                    s
                );

                require(
                    recoveredAddress != address(0) && recoveredAddress == owner,
                    "ERC20: INVALID_SIGNER"
                );

                _approve(_strategyStorage(), recoveredAddress, spender, value);
            }
        }

        /**
        * @notice Returns the domain separator used in the encoding of the signature
        * for {permit}, as defined by {EIP712}.
        *
        * @return . The domain separator that will be used for any {permit} calls.
        */
        function DOMAIN_SEPARATOR() public view returns (bytes32) {
            return
                keccak256(
                    abi.encode(
                        keccak256(
                            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                        ),
                        keccak256("Yearn Vault"),
                        keccak256(bytes(API_VERSION)),
                        block.chainid,
                        address(this)
                    )
                );
        }

        /*//////////////////////////////////////////////////////////////
                                DEPLOYMENT
        //////////////////////////////////////////////////////////////*/

        /**
        * @dev On contract creation we set `asset` for this contract to address(1).
        * This prevents it from ever being initialized in the future.
        * @param _factory Address of the factory of the same version for protocol fees.
        */
        constructor(address _factory) {
            FACTORY = _factory;
            _strategyStorage().asset = ERC20(address(1));
        }
    }
