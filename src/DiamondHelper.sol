// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IDiamond} from "./interfaces/IDiamond.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";

contract DiamondHelper {
    bytes4[] private selectors;
    IDiamond.FacetCut[] private cuts;

    // NOTE: These will be set to internal constants once the library has actually been deployed
    address public baseLibrary;

    constructor(bytes4[] memory _selectors) {
        selectors = _selectors;
    }

    // can only be set up once
    function setLibrary(address _library) external {
        require(baseLibrary == address(0), "already set");
        baseLibrary = _library;

        //set up diamond cut struct
        cuts.push(
            IDiamond.FacetCut(_library, IDiamond.FacetCutAction.Add, selectors)
        );
    }

    function diamondCut() external view returns (IDiamond.FacetCut[] memory) {
        return cuts;
    }

    function functionSelectors() external view returns (bytes4[] memory) {
        return selectors;
    }

    // TODO: Implement the Diamon Loupe function using the selector helper
    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets()
        external
        view
        returns (IDiamondLoupe.Facet[] memory facets_)
    {
        // we forward all calls to the base library
        facets_[0] = IDiamondLoupe.Facet(baseLibrary, selectors);
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_) {
        if (_facet == baseLibrary) {
            facetFunctionSelectors_ = selectors;
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
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_) {
        bytes4[] memory facetFunctionSelectors_ = selectors;

        for (uint256 i; i < facetFunctionSelectors_.length; ++i) {
            if (facetFunctionSelectors_[i] == _functionSelector)
                return baseLibrary;
        }
    }
}
