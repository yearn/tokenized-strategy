// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {DiamondHelper, IDiamond} from "./DiamondHelper.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";

contract Diamond {
    event DiamondCut(
        IDiamond.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    // NOTE: These will be set to internal constants once the library has actually been deployed
    address public baseLibrary;
    // NOTE: holder address based on expected location during tests
    address public constant diamondHelper =
        0xFEfC6BAF87cF3684058D62Da40Ff3A795946Ab06;

    function _diamondSetup() internal {
        // emit the standard DiamondCut event with the values from out helper contract
        emit DiamondCut(
            // struct containing the address of the library, the add enum and array of all function selectors
            DiamondHelper(diamondHelper).diamondCut(),
            // init address to call if applicable
            address(0),
            // call data to send the init address if applicable
            new bytes(0)
        );
    }

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL EIP-2535 VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // TODO: Implement the Diamon Loupe function using the selector helper
    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets()
        external
        view
        returns (IDiamondLoupe.Facet[] memory facets_)
    {
        // we forward all calls to the base library
        facets_[0] = IDiamondLoupe.Facet(
            baseLibrary,
            DiamondHelper(diamondHelper).functionSelectors()
        );
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        if (_facet == baseLibrary) {
            facetFunctionSelectors_ = DiamondHelper(diamondHelper)
                .functionSelectors();
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {
        // we only use one facet
        facetAddresses_[0] = baseLibrary;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_)
    {
        bytes4[] memory facetFunctionSelectors_ = DiamondHelper(diamondHelper)
            .functionSelectors();

        for (uint256 i; i < facetFunctionSelectors_.length; ++i) {
            if (facetFunctionSelectors_[i] == _functionSelector)
                return baseLibrary;
        }
    }

    // NOTE: Should we have a seperate management access library to control ownership?

    // exeute a function on the baseLibrary and return any value.
    fallback() external payable {
        // load our target address
        // IF needed this could call the helper contract based on the sig to make external library functions unavailable
        address _baseLibrary = baseLibrary;
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(
                gas(),
                _baseLibrary,
                0,
                calldatasize(),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
