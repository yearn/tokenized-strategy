// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

interface IDiamond {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_);
}

interface IBaseLibrary {
    function apiVersion() external view returns (string memory);
}

contract DiamondHelper {
    address public baseLibrary;

    bytes4[] private selectors;
    IDiamond.FacetCut[] private cuts;

    constructor(bytes4[] memory _selectors) {
        selectors = _selectors;
    }

    /**
     * @notice Get the api version for this helper.
     */
    function apiVersion() external view returns (string memory) {
        return IBaseLibrary(baseLibrary).apiVersion();
    }

    /**
     * @notice Set the address of the BaseLibrary and store the
     *  FacetCut for events
     * @dev This contract needs to be deployed first since the
     * address must be hardcoded in the library.
     *
     * This can only be set up once and then the contract can
     * never be adjusted.
     *
     * @param _library, The address of the BaseLibrary for the
     * strategies to forward calls to.
     */
    function setLibrary(address _library) external {
        require(baseLibrary == address(0), "already set");
        baseLibrary = _library;

        //set up diamond cut struct
        cuts.push(
            IDiamond.FacetCut(_library, IDiamond.FacetCutAction.Add, selectors)
        );
    }

    /**
     * @notice Returns the Struct to emit in the needed DiamondCut
     * event on initilization of a new strategy.
     *
     * Contatins the address of the library, the enum singaling we
     * are adding and the array of all its external function selectors.
     */
    function diamondCut() external view returns (IDiamond.FacetCut[] memory) {
        return cuts;
    }

    /**
     * @notice Returns the fully array of function selectors the BaseLibrary contains.
     */
    function functionSelectors() external view returns (bytes4[] memory) {
        return selectors;
    }

    /**
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Facet
     */
    function facets()
        external
        view
        returns (IDiamondLoupe.Facet[] memory facets_)
    {
        facets_ = new IDiamondLoupe.Facet[](1);
        // we forward all calls to the base library
        facets_[0] = IDiamondLoupe.Facet(baseLibrary, selectors);
    }

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_
     */
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_) {
        if (_facet == baseLibrary) {
            facetFunctionSelectors_ = selectors;
        }
    }

    /**
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_
     */
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {
        facetAddresses_ = new address[](1);
        // we only use one facet
        facetAddresses_[0] = baseLibrary;
    }

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     */
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
