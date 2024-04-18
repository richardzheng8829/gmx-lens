// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

interface DataStore {
    function getUint(bytes32 key) external view returns (uint256);
    function getBytes32(bytes32 key) external view returns (bytes32);
    function getAddress(bytes32 key) external view returns (address);
    function getAddressCount(bytes32 setKey) external view returns (uint256);
    function getAddressValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (address[] memory);
}