// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {Modifiers, Whitelist} from "../libraries/LibAppStorage.sol";

contract WhitelistFacet is Modifiers {
    event WhitelistCreated(uint32 indexed whitelistId);
    event WhitelistUpdated(uint32 indexed whitelistId);

    function createWhitelist(string calldata _name, address[] calldata _whitelistAddresses) external {
        uint256 whitelistLength = _whitelistAddresses.length;
        require(whitelistLength > 0, "WhitelistFacet: Whitelist length should be larger than zero");

        address sender = LibMeta.msgSender();
        uint32 whitelistId = uint32(s.whitelists.length + 1); //whitelistId 0 is reserved for "none" in GotchiLending struct
        address[] memory addresses;
        Whitelist memory whitelist = Whitelist({owner: sender, name: _name, addresses: addresses});
        s.whitelists.push(whitelist);
        _addAddressesToWhitelist(whitelistId, _whitelistAddresses);

        emit WhitelistCreated(whitelistId);
    }

    function updateWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) external {
        address sender = LibMeta.msgSender();

        require((s.whitelists.length >= _whitelistId) && (_whitelistId > 0), "WhitelistFacet: Whitelist not found");
        require(s.whitelists[_whitelistId - 1].owner == sender, "WhitelistFacet: Not whitelist owner");

        uint32 whitelistLength = uint32(_whitelistAddresses.length);
        require(whitelistLength > 0, "WhitelistFacet: Whitelist length should be larger than zero");

        _addAddressesToWhitelist(_whitelistId, _whitelistAddresses);

        emit WhitelistUpdated(_whitelistId);
    }

    function removeAddressesFromWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) external {
        address sender = LibMeta.msgSender();

        require((s.whitelists.length >= _whitelistId) && (_whitelistId > 0), "WhitelistFacet: Whitelist not found");
        require(s.whitelists[_whitelistId - 1].owner == sender, "WhitelistFacet: Not whitelist owner");

        uint32 whitelistLength = uint32(_whitelistAddresses.length);
        require(whitelistLength > 0, "WhitelistFacet: Whitelist length should be larger than zero");

        _removeAddressesFromWhitelist(_whitelistId, _whitelistAddresses);

        emit WhitelistUpdated(_whitelistId);
    }

    function isWhitelisted(uint32 _whitelistId, address _whitelistAddress) external view returns (uint256) {
        return s.isWhitelisted[_whitelistId][_whitelistAddress];
    }

    function getWhitelist(uint32 _whitelistId) external view returns (Whitelist memory) {
        require((uint32(s.whitelists.length) >= _whitelistId) && (_whitelistId > 0), "WhitelistFacet: Whitelist not found");
        return s.whitelists[_whitelistId - 1];
    }

    function getWhitelists() external view returns (Whitelist[] memory) {
        return s.whitelists;
    }

    function getWhitelistsLength() external view returns (uint256) {
        return s.whitelists.length;
    }

    function _addAddressesToWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) internal {
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            _addAddressToWhitelist(_whitelistId, _whitelistAddresses[i]);
        }
    }

    function _addAddressToWhitelist(uint32 _whitelistId, address _whitelistAddress) internal {
        if (s.isWhitelisted[_whitelistId][_whitelistAddress] == 0) {
            s.whitelists[_whitelistId - 1].addresses.push(_whitelistAddress);
            s.isWhitelisted[_whitelistId][_whitelistAddress] = s.whitelists[_whitelistId - 1].addresses.length; // Index of the whitelist entry + 1
        }
    }

    function _removeAddressesFromWhitelist(uint32 _whitelistId, address[] calldata _whitelistAddresses) internal {
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            _removeAddressFromWhitelist(_whitelistId, _whitelistAddresses[i]);
        }
    }

    function _removeAddressFromWhitelist(uint32 _whitelistId, address _whitelistAddress) internal {
        if (s.isWhitelisted[_whitelistId][_whitelistAddress] > 0) {
            uint256 index = s.isWhitelisted[_whitelistId][_whitelistAddress] - 1;
            uint256 lastIndex = s.whitelists[_whitelistId - 1].addresses.length - 1;
            // Replaces the element to be removed with the last element
            s.whitelists[_whitelistId - 1].addresses[index] = s.whitelists[_whitelistId - 1].addresses[lastIndex];
            // Store the last element in memory
            address lastElement = s.whitelists[_whitelistId - 1].addresses[lastIndex];
            // Remove the last element from storage
            s.whitelists[_whitelistId - 1].addresses.pop();
            // Update the index of the last element that was swapped. If this is the only element, updates to zero on the next line
            s.isWhitelisted[_whitelistId][lastElement] = index + 1;
            // Update the index of the removed element
            s.isWhitelisted[_whitelistId][_whitelistAddress] = 0;
        }
    }
}
