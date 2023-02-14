// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IDiamond} from "./interfaces/IDiamond.sol";

contract DiamondHelper {
    bytes4[] private selectors;
    IDiamond.FacetCut[] private cuts;

    constructor(address _library, bytes4[] memory _selectors) {
        selectors = _selectors;

        //set up diamond cut struct
        cuts.push(
            IDiamond.FacetCut(_library, IDiamond.FacetCutAction.Add, _selectors)
        );
    }

    function diamondCut() external view returns (IDiamond.FacetCut[] memory) {
        return cuts;
    }

    function functionSelectors() external view returns (bytes4[] memory) {
        return selectors;
    }
}
